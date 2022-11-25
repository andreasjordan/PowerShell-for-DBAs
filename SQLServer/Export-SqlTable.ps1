function Export-SqlTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,
        [Parameter(Mandatory)][string]$Table,
        [Parameter(Mandatory)][string]$Path,
        [int]$BatchSize = 1000,
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8,
        [switch]$EnableException
    )

    Write-PSFMessage -Level Verbose -Message "Opening file"
    try {
        $streamWriter = [System.IO.StreamWriter]::new($Path, $false, $Encoding)
    } catch {
        Stop-PSFFunction -Message "Opening file failed: $($_.Exception.Message)" -Target $Path -EnableException $EnableException
        return
    }

    Write-PSFMessage -Level Verbose -Message "Getting number of rows"
    Write-Progress -Id 1 -Activity "Exporting rows from $Table" -Status "Getting number of rows"
    try {
        $command = $Connection.CreateCommand()
        $command.CommandText = "SELECT COUNT(*) FROM $Table"
        $command.CommandTimeout = 0
        $numRows = $command.ExecuteScalar()
    } catch {
        Stop-PSFFunction -Message "Getting number of rows failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
        return
    }

    Write-PSFMessage -Level Verbose -Message "Exporting rows"
    $progressParam = @{ 
        Id               = 1
        Activity         = 'Exporting rows from {0}' -f $Table
        Status           = '0 of {0:n0} rows exported' -f $numRows
    }
    Write-Progress @progressParam
    try {
        $command = $Connection.CreateCommand()
        $command.CommandText = "SELECT * FROM $Table"
        $command.CommandTimeout = 0
        $reader = $command.ExecuteReader()
        $columns = $reader.GetSchemaTable().Rows
        $rowCount = 0
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        while($reader.Read()) {
            $row = [ordered]@{ }
            foreach ($column in $columns) {
                if ($reader.IsDBNull($column.ColumnOrdinal)) {
                    $row[$column.ColumnName] = $null
                } else {
                    $row[$column.ColumnName] = $reader.GetValue($column.ColumnOrdinal)
                }
            }
            $streamWriter.WriteLine(($row | ConvertTo-Json -Compress))
            $rowCount += 1

            if ($rowCount % $BatchSize -eq 0) {
                $progressParam.Status = '{0:n0} of {1:n0} rows exported' -f $rowCount, $numRows
                $progressParam.SecondsRemaining = $stopwatch.Elapsed.TotalSeconds * ($numRows - $rowCount) / $rowCount
                $progressParam.PercentComplete = $rowCount * 100 / $numRows
                $progressParam.CurrentOperation = '{0:n0} rows per second' -f ($rowCount / $stopwatch.Elapsed.TotalSeconds)
                Write-Progress @progressParam
            }
        }
    } catch {
        Stop-PSFFunction -Message "Exporting rows failed: $($_.Exception.InnerException.Message)" -Target $command -EnableException $EnableException
        return
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        if ($null -ne $streamWriter) { $streamWriter.Close() }
        Write-Progress -Id 1 -Activity Completed -Completed
    }
}
