function Invoke-IfxQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][Informix.Net.Core.IfxConnection]$Connection,
        [Parameter(Mandatory)][string]$Query,
        [Int32]$QueryTimeout = 600,
        [ValidateSet("DataSet", "DataTable", "DataRow", "PSObject", "SingleValue")]
        [string]$As = "PSObject",
        [System.Collections.IDictionary]$ParameterValues,
        [System.Collections.IDictionary]$ParameterTypes,
        [switch]$EnableException
    )

    begin {
        if ($As -eq 'PSObject') {
            #This code scrubs DBNulls.  Props to Dave Wyatt
            $cSharp = @'
                using System;
                using System.Data;
                using System.Management.Automation;
                public class DBNullScrubber
                {
                    public static PSObject DataRowToPSObject(DataRow row)
                    {
                        PSObject psObject = new PSObject();
                        if (row != null && (row.RowState & DataRowState.Detached) != DataRowState.Detached)
                        {
                            foreach (DataColumn column in row.Table.Columns)
                            {
                                Object value = null;
                                if (!row.IsNull(column))
                                {
                                    value = row[column];
                                }
                                psObject.Properties.Add(new PSNoteProperty(column.ColumnName, value));
                            }
                        }
                        return psObject;
                    }
                }
'@

            try {
                if ($PSEdition -eq 'Core') {
                    $assemblies = @('System.Management.Automation', 'System.Data.Common', 'System.ComponentModel.TypeConverter')
                } else {
                    $assemblies = @('System.Data', 'System.Xml')
                }
                Add-Type -TypeDefinition $cSharp -ReferencedAssemblies $assemblies -ErrorAction Stop
            } catch {
                if (-not $_.ToString() -like "*The type name 'DBNullScrubber' already exists*") {
                    Write-Warning -Message "Could not load DBNullScrubber. Defaulting to DataRow output: $_."
                    $As = "Datarow"
                }
            }
        }
    }

    process {
        Write-Verbose -Message "Creating command from connection and setting query: $Query"
        $command = $Connection.CreateCommand()
        $command.CommandText = $Query
        $command.CommandTimeout = $QueryTimeout

        if ($null -ne $ParameterValues) {
            Write-Verbose -Message "Adding parameters to command"
            # Named parameters are not supported, so replace them by positional parameters
            $parameterObjects = foreach ($parameterName in $ParameterValues.Keys) {
                [PSCustomObject]@{
                    Name     = $parameterName
                    Value    = $ParameterValues[$parameterName]
                    Position = $Query.IndexOf("@$parameterName")
                }
            }
            # Add parameters in order of appearance
            $parameterObjects = $parameterObjects | Sort-Object -Property Position
            foreach ($parameterObject in $parameterObjects) {
                $Query = $Query.Replace("@$($parameterObject.Name)", '?')
                $parameter = $command.CreateParameter()
                $parameter.ParameterName = $parameterObject.Name
                if (($null -ne $ParameterTypes) -and ($null -ne $ParameterTypes[$parameterObject.Name])) {
                    $parameter.IfxType = $ParameterTypes[$parameterObject.Name]
                }
                $parameter.Value = $parameterObject.Value
                if ($null -eq $parameter.Value) {
                    $parameter.Value = [DBNull]::Value
                }
                $null = $command.Parameters.Add($parameter)
                Write-Verbose -Message "Added parameter $($parameterObject.Name)) with value: $($parameterObject.Value)"
            }
            $command.CommandText = $Query
        }

        Write-Verbose -Message "Creating data adapter and setting command"
        $dataAdapter = [Informix.Net.Core.IfxDataAdapter]::new()
        $dataAdapter.SelectCommand = $command

        Write-Verbose -Message "Creating data set"
        $dataSet = [System.Data.DataSet]::new()

        try {
            Write-Verbose -Message "Filling data set by data adapter"
            $rowCount = $dataAdapter.Fill($dataSet)
            Write-Verbose -Message "Received $rowCount rows"

            switch ($As) {
                'DataSet' {
                    $dataSet
                }
                'DataTable' {
                    $dataSet.Tables
                }
                'DataRow' {
                    if ($dataSet.Tables.Count -ne 0) {
                        $dataSet.Tables[0].Rows
                    }
                }
                'PSObject' {
                    if ($dataSet.Tables.Count -ne 0) {
                        foreach ($row in $dataSet.Tables[0].Rows) {
                            [DBNullScrubber]::DataRowToPSObject($row)
                        }
                    }
                }
                'SingleValue' {
                    if ($dataSet.Tables.Count -ne 0) {
                        $dataSet.Tables[0].Rows | Select-Object -ExpandProperty $dataSet.Tables[0].Columns[0].ColumnName
                    }
                }
            }
        } catch {
            $message = "Query failed: $($_.Exception.InnerException.Message)"
            if ($EnableException) {
                Write-Error -Message $message -TargetObject $command -ErrorAction Stop
            } else {
                Write-Warning -Message $message
            }
        }
    }
}
