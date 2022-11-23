function Get-OraTableInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][Oracle.ManagedDataAccess.Client.OracleConnection]$Connection,
        [string[]]$Table,
        [switch]$EnableException
    )

    try {
        $queryParams = @{
            Connection      = $Connection
            As              = 'SingleValue'
            EnableException = $true
        }

        if ($Table.Count -eq 0) {
            Write-PSFMessage -Level Verbose -Message "Getting list of tables in current schema"
            $Table = Invoke-OraQuery -Query 'SELECT table_name FROM user_tables' @queryParams | Sort-Object
        }
    
        foreach ($tbl in $Table) {
            Write-PSFMessage -Level Verbose -Message "Getting information about $tbl"
            $blocks = Invoke-OraQuery -Query 'SELECT NVL(SUM(blocks), 0) FROM user_segments WHERE segment_name = :segment_name' -ParameterValues @{ segment_name = $tbl } @queryParams
            $rows = Invoke-OraQuery -Query "SELECT COUNT(*) FROM $tbl" @queryParams
            [PSCustomObject]@{
                Table  = $tbl
                Blocks = [int]$blocks
                Rows   = [int]$rows
            }
        }
    } catch {
        Stop-PSFFunction -Message "Getting information failed: $($_.Exception.Message)" -EnableException $EnableException
    }
}
