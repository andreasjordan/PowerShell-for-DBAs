function Get-SqlTableReader {
    [CmdletBinding()]
    [OutputType([System.Data.SqlClient.SqlDataReader])]
    param (
        [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,
        [Parameter(Mandatory)][string]$Table,
        [switch]$EnableException
    )

    try {
        Write-PSFMessage -Level Verbose -Message "Getting data reader for $Table"
        $command = $Connection.CreateCommand()
        $command.CommandText = "SELECT * FROM $Table"
        , $command.ExecuteReader()
    } catch {
        Stop-PSFFunction -Message "Getting data reader failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
    } finally {
        try { $command.Dispose() } catch { }
    }
}
