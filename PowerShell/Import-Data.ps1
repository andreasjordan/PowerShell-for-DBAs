function Import-Data {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][ValidateSet("SQLServer", "Oracle", "PostgreSQL", "MySQL")][string]$DBMS,
        [Parameter(Mandatory)][object]$Connection,
        [switch]$EnableException
    )

    try {
        Write-Verbose -Message "Importing JSON from $Path"
        $data = Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json
        $tableNames = $data.PSObject.Properties.Name | Sort-Object

        $progressTableParameter = @{ Id = 1 ; Activity = 'Importing tables' }
        $progressTableTotal = $tableNames.Count
        $progressTableCompleted = 0 

        foreach ($tableName in $tableNames) {
            Write-Verbose -Message "Processing table $tableName"

            $progressTableParameter.Status = "$progressTableCompleted of $progressTableTotal tables completed"
            $progressTableParameter.CurrentOperation = "processing table $tableName"
            Write-Progress @progressTableParameter
            $progressTableCompleted++

            switch ($DBMS) {
                SQLServer {
                    Write-SqlTable -Connection $Connection -Table $tableName -Data $data.$tableName -EnableException
                }
                Oracle {
                    Write-OraTable -Connection $Connection -Table $tableName -Data $data.$tableName -EnableException
                }
                PostgreSQL {
                    Write-PgTable -Connection $Connection -Table $tableName -Data $data.$tableName -EnableException
                }
                MySQL {
                    Write-MyTable -Connection $Connection -Table $tableName -Data $data.$tableName -EnableException
                }
            }
        }
        Write-Progress @progressTableParameter -Completed
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Data could not be imported: $_"
        }
    }
}
