function Read-SqlQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,
        [Parameter(Mandatory)][string]$Query,
        [Int32]$QueryTimeout = 600,
        [System.Collections.IDictionary]$ParameterValues,
        [System.Collections.IDictionary]$ParameterTypes,
        [switch]$EnableException
    )

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

    Write-Verbose -Message "Creating data reader"
    try {
        $reader = $command.ExecuteReader()
        $columns = $reader.GetSchemaTable().Rows
        while($reader.Read()) {
            $row = [ordered]@{ }
            foreach ($column in $columns) {
                if ($reader.IsDBNull($column.ColumnOrdinal)) {
                    $row[$column.ColumnName] = $null
                } else {
                    $row[$column.ColumnName] = $reader.GetValue($column.ColumnOrdinal)
                }
            }
            [PSCustomObject]$row
        }
    } catch {
        $message = "Query failed: $($_.Exception.InnerException.Message)"
        if ($EnableException) {
            Write-Error -Message $message -TargetObject $command -ErrorAction Stop
        } else {
            Write-Warning -Message $message
        }
    } finally {
        $reader.Dispose()
    }
}
