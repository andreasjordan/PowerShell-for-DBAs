function Import-Schema {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][ValidateSet("SQLServer", "Oracle", "PostgreSQL", "MySQL", "Db2", "Informix")][string]$DBMS,
        [Parameter(Mandatory)][object]$Connection,
        [switch]$EnableException
    )

    try {
        Write-Verbose -Message "Importing PowerShellDataFile from $Path"
        $schema = Import-PowerShellDataFile -Path $Path

        $queries = @( )

        foreach ($table in $schema.Tables) {
            # $table = $schema.Tables[0]
            Write-Verbose -Message "Processing table [$($table.TableName)]"

            $query = "CREATE TABLE $($table.TableName) ("
            foreach ($column in $table.Columns) {
                # $column = $table.Columns[1]

                Write-Verbose -Message "Processing column [$($column.ColumnName)]"
                if ($column.Datatype -match '^VARCHAR_(\d+)$') {
                    $datatype = 'VARCHAR'
                    if ($DBMS -eq 'Oracle') {
                        $length = "($($Matches[1]) CHAR)"
                    } elseif ($DBMS -eq 'Db2') {
                        $length = "($($Matches[1]) CODEUNITS32)"
                    } else {
                        $length = "($($Matches[1]))"
                    }
                } else {
                    $datatype = $column.Datatype
                    $length = ''
                }
                $datatype = $schema.DataTypes.$datatype.$DBMS
                $query += "$($column.ColumnName) $datatype$length $($column.Constraint), "
            }
            if ($DBMS -eq 'Informix') {
                $query += "PRIMARY KEY ($($table.PrimaryKey)) CONSTRAINT $($table.TableName)_PK)"
            } else {
                $query += "CONSTRAINT $($table.TableName)_PK PRIMARY KEY ($($table.PrimaryKey)))"
            }

            $queries += $query
        }

        foreach ($index in $schema.Indexes) {
            # $index = $schema.Indexes[0]
            Write-Verbose -Message "Processing index [$($index.IndexName)] on [$($index.TableName)]"

            $queries += "CREATE INDEX $($index.IndexName) ON $($index.TableName) ($($index.Columns -join ','))"
        }

        Write-Verbose -Message "Sending all queries to database"
        foreach ($query in $queries) {
            Write-Debug -Message "Running query: $query"
            switch ($DBMS) {
                SQLServer {
                    if (Get-Module -Name dbatools) {
                        $null = Invoke-DbaQuery -SqlInstance $Connection -Query $query -EnableException
                    } else {
                        $null = Invoke-SqlQuery -Connection $Connection -Query $query -EnableException
                    }
                }
                Oracle {
                    $null = Invoke-OraQuery -Connection $Connection -Query $query -EnableException
                }
                PostgreSQL {
                    $null = Invoke-PgQuery -Connection $Connection -Query $query -EnableException
                }
                MySQL {
                    $null = Invoke-MyQuery -Connection $Connection -Query $query -EnableException
                }
                Db2 {
                    $null = Invoke-Db2Query -Connection $Connection -Query $query -EnableException
                }
                Informix {
                    $null = Invoke-IfxQuery -Connection $Connection -Query $query -EnableException
                }
            }
        }
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Schema could not be imported: $_"
        }
    }
}
