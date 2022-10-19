function Invoke-SqlQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,
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
        Write-Verbose -Message "Creating command from connection and setting query"
        $command = $Connection.CreateCommand()
        $command.CommandText = $Query
        $command.CommandTimeout = $QueryTimeout

        if ($null -ne $ParameterValues) {
            Write-Verbose -Message "Adding parameters to command"
            foreach ($parameterName in $ParameterValues.Keys) {
                $parameter = $command.CreateParameter()
                $parameter.ParameterName = $parameterName
                if (($null -ne $ParameterTypes) -and ($null -ne $ParameterTypes[$parameterName])) {
                    $parameter.SqlDbType = $ParameterTypes[$parameterName]
                }
                $parameter.Value = $ParameterValues[$parameterName]
                if ($null -eq $parameter.Value) {
                    $parameter.Value = [DBNull]::Value
                }
                $null = $command.Parameters.Add($parameter)
            }
        }

        Write-Verbose -Message "Creating data adapter and setting command"
        $dataAdapter = [System.Data.SqlClient.SqlDataAdapter]::new()
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
