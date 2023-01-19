function Get-PgTableInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][Npgsql.NpgsqlConnection]$Connection,
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
            $Table = Invoke-PgQuery -Query "SELECT table_name FROM information_schema.tables WHERE table_catalog LIKE '$($Connection.Database)' AND table_schema = 'public' AND table_type LIKE 'BASE_TABLE'" @queryParams | Sort-Object
        }

        foreach ($tbl in $Table) {
            $tbl = $tbl.ToLower()
            Write-PSFMessage -Level Verbose -Message "Getting information about $tbl"
            $bytes = Invoke-PgQuery -Query "SELECT pg_relation_size(quote_ident('$tbl'))" @queryParams
            $rows = Invoke-PgQuery -Query "SELECT COUNT(*) FROM $tbl" @queryParams
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
