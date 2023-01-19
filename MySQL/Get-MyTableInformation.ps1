function Get-MyTableInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][MySqlConnector.MySqlConnection]$Connection,
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
            $Table = Invoke-MyQuery -Query "SELECT table_name FROM information_schema.tables WHERE table_schema LIKE '$($Connection.Database)' AND table_type LIKE 'BASE_TABLE'" @queryParams | Sort-Object
        }
    
        foreach ($tbl in $Table) {
            Write-PSFMessage -Level Verbose -Message "Getting information about $tbl"
            $bytes = Invoke-MyQuery -Query "SELECT IFNULL(data_length, 0) FROM information_schema.tables WHERE table_schema LIKE '$($Connection.Database)' AND table_name = ?table_name" -ParameterValues @{ table_name = $tbl } @queryParams
            $rows = Invoke-MyQuery -Query "SELECT COUNT(*) FROM $tbl" @queryParams
            [PSCustomObject]@{
                Table = $tbl
                Bytes = [int]$bytes
                Rows  = [int]$rows
            }
        }
    } catch {
        Stop-PSFFunction -Message "Getting information failed: $($_.Exception.Message)" -EnableException $EnableException
    }
}
