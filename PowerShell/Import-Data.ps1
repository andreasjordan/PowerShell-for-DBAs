function Import-Data {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][ValidateSet("SQLServer", "Oracle", "PostgreSQL", "MySQL", "Db2", "Informix")][string]$DBMS,
        [Parameter(Mandatory)][object]$Connection,
        [int]$MaxRowsPerTable,
        [switch]$EnableException
    )

    try {
        Write-Verbose -Message "Importing JSON from $Path"
        $data = Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json

        $tableNames = $data.PSObject.Properties.Name | Sort-Object

        $bindParameterSymbol = ':'
        if ($DBMS -in 'SQLServer', 'Db2', 'Informix') {
            $bindParameterSymbol = '@'
        }
        if ($DBMS -eq 'MySQL' -and $Connection.GetType().FullName -notmatch 'Devart') {
            $bindParameterSymbol = '?'
        }

        $progressTableParameter = @{ Id = 1 ; Activity = 'Importing tables' }
        $progressTableTotal = $tableNames.Count
        $progressTableCompleted = 0 

        foreach ($tableName in $tableNames) {
            Write-Verbose -Message "Processing table $tableName"

            $progressTableParameter.Status = "$progressTableCompleted of $progressTableTotal tables completed"
            $progressTableParameter.CurrentOperation = "processing table $tableName"
            Write-Progress @progressTableParameter
            $progressTableCompleted++

            $insertIntoSql1 = "INSERT INTO $tableName ("
            $insertIntoSql2 = " VALUES ("
            $columNames = ($data.$tableName | Select-Object -First 1).PSObject.Properties.Name
            foreach ($columnName in $columNames) {
                $insertIntoSql1 += "$columnName, "
                $insertIntoSql2 += "$bindParameterSymbol$columnName, "
            }
            $insertIntoSql1 = $insertIntoSql1.TrimEnd(', ') + ')'
            $insertIntoSql2 = $insertIntoSql2.TrimEnd(', ') + ')'
            $insertIntoSql = $insertIntoSql1 + $insertIntoSql2

            if ($tableName -eq 'Posts') {
                $parameterTypes = @{ Body = 'TEXT' }
            }
            if ($tableName -eq 'Users') {
                $parameterTypes = @{ AboutMe = 'TEXT' }
            }

            $progressRowParameter = @{ Id = 2 ; Activity = 'Importing rows' }
            $progressRowTotal = $data.$tableName.Count
            $progressRowCompleted = 0 
            $progressRowStart = Get-Date

            foreach ($row in $data.$tableName) {
                if ($progressRowCompleted % 100 -eq 0) {
                    $progressRowParameter.Status = "$progressRowCompleted of $progressRowTotal rows completed"
                    $progressRowParameter.PercentComplete = $progressRowCompleted * 100 / $progressRowTotal
                    if ($progressRowParameter.PercentComplete -gt 0) {
                        $progressRowParameter.SecondsRemaining = ((Get-Date) - $progressRowStart).TotalSeconds / $progressRowParameter.PercentComplete * (100 - $progressRowParameter.PercentComplete)
                        $progressRowParameter.Status += " ($([int]($progressRowCompleted / ((Get-Date) - $progressRowStart).TotalSeconds)) rows per second)"
                    }
                    Write-Progress @progressRowParameter
                }
                $progressRowCompleted++

                $parameterValues = @{}
                foreach ($column in $row.PSObject.Properties) {
                    $parameterValues[$column.Name] = $column.Value
                }

                switch ($DBMS) {
                    SQLServer {
                        if (Get-Module -Name dbatools) {
                            $null = Invoke-DbaQuery -SqlInstance $Connection -Query $insertIntoSql -SqlParameter $parameterValues -EnableException
                        } else {
                            $null = Invoke-SqlQuery -Connection $Connection -Query $insertIntoSql -ParameterValues $parameterValues -EnableException
                        }
                    }
                    Oracle {
                        $null = Invoke-OraQuery -Connection $Connection -Query $insertIntoSql -ParameterValues $parameterValues -EnableException
                    }
                    PostgreSQL {
                        $null = Invoke-PgQuery -Connection $Connection -Query $insertIntoSql -ParameterValues $parameterValues -EnableException
                    }
                    MySQL {
                        $null = Invoke-MyQuery -Connection $Connection -Query $insertIntoSql -ParameterValues $parameterValues -EnableException
                    }
                    Db2 {
                        $null = Invoke-Db2Query -Connection $Connection -Query $insertIntoSql -ParameterValues $parameterValues -EnableException
                    }
                    Informix {
                        $null = Invoke-IfxQuery -Connection $Connection -Query $insertIntoSql -ParameterValues $parameterValues -ParameterTypes $parameterTypes -EnableException
                    }
                }

                if ($MaxRowsPerTable -gt 0 -and $progressRowCompleted -ge $MaxRowsPerTable) { 
                    Write-Verbose -Message "Maximum of $MaxRowsPerTable rows reached"
                    break
                }
            }
            Write-Progress @progressRowParameter -Completed
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
