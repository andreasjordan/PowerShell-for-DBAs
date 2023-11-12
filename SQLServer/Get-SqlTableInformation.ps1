function Get-SqlTableInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,
        [string[]]$Table,
        [switch]$EnableException
    )

    try {
        $queryParams = @{
            Connection      = $Connection
            EnableException = $true
        }

        if ($Table.Count -eq 0) {
            Write-PSFMessage -Level Verbose -Message "Getting list of tables in current schema"
            $Table = Invoke-SqlQuery -Query 'SELECT name FROM sys.tables' -As SingleValue @queryParams | Sort-Object
        }
    
        foreach ($tbl in $Table) {
            Write-PSFMessage -Level Verbose -Message "Getting information about $tbl"
            # Query might be wrong, please test and give feedback
            $pagesQuery = @'
SELECT SUM(u.used_pages)
  FROM sys.tables AS t 
     , sys.partitions AS p
     , sys.allocation_units AS u
 WHERE t.object_id = p.object_id
   AND p.hobt_id = u.container_id
   AND t.name = @name
   AND p.index_id <= 1
'@
            $pages = Invoke-SqlQuery -Query $pagesQuery -ParameterValues @{ name = $tbl } @queryParams
            $rows = Invoke-SqlQuery -Query "SELECT COUNT(*) FROM $tbl" @queryParams
            [PSCustomObject]@{
                Table = $tbl
                Pages = [int]$pages
                Rows  = [int]$rows
            }
        }
    } catch {
        Stop-PSFFunction -Message "Getting information failed: $($_.Exception.Message)" -EnableException $EnableException
    }
}
