function Get-SqlTableReader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][Microsoft.Data.SqlClient.SqlConnection]$Connection,
        [Parameter(Mandatory)][string]$Table,
        [switch]$IncludeRowCount,
        [switch]$EnableException
    )

    if ($IncludeRowCount) {
        try {
            Write-PSFMessage -Level Verbose -Message "Getting number of rows in $Table"
            $command = $Connection.CreateCommand()
            $command.CommandText = "SELECT COUNT(*) FROM $Table"
            $rowCount = [int]$command.ExecuteScalar()
            $command.Dispose()
        } catch {
            Stop-PSFFunction -Message "Getting number of rows: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
            return
        } finally {
            try { $command.Dispose() } catch { }
        }
    }

    try {
        Write-PSFMessage -Level Verbose -Message "Getting data reader for $Table"
        $command = $Connection.CreateCommand()
        $command.CommandText = "SELECT * FROM $Table"
        $reader = $command.ExecuteReader()
    } catch {
        Stop-PSFFunction -Message "Getting data reader failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
        return
    } finally {
        try { $command.Dispose() } catch { }
    }

    if ($IncludeRowCount) {
        $reader, $rowCount
    } else {
        , $reader
    }
}
