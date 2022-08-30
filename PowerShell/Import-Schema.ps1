function Import-Schema {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][ValidateSet("SQLServer", "Oracle", "PostgreSQL", "MySQL", "Db2", "Informix")][string]$DBMS,
        [switch]$EnableException
    )

    try {
        Write-Verbose -Message "Importing PowerShellDataFile from $Path"
        $schema = Import-PowerShellDataFile -Path $Path

        foreach ($table in $schema.Tables) {
            # $table = $schema.Tables[0]
            Write-Verbose -Message "Processing table [$($table.TableName)]"

            $query = "CREATE TABLE $($table.TableName) ("
            foreach ($column in $table.Columns) {
                # $column = $table.Columns[1]

                Write-Verbose -Message "Processing column [$($column.ColumnName)]"
                if ($column.Datatype -match '^VARCHAR_(\d+)$') {
                    $datatype = 'VARCHAR'
                    $length = "($($Matches[1]))"
                } else {
                    $datatype = $column.Datatype
                    $length = ''
                }
                $datatype = $schema.DataTypes.$datatype.$DBMS
                $query += "$($column.ColumnName) $datatype$length $($column.Constraint), "
            }
            $query += "CONSTRAINT $($table.TableName)_PK PRIMARY KEY ($($table.PrimaryKey)))"

            Write-Debug -Message "Adding to output: $query"
            $query
        }
        foreach ($index in $schema.Indexes) {
            # $index = $schema.Indexes[0]
            Write-Verbose -Message "Processing index [$($index.IndexName)] on [$($index.TableName)]"

            $query = "CREATE INDEX $($index.IndexName) ON $($index.TableName) ($($index.Columns -join ','))"

            Write-Debug -Message "Adding to output: $query"
            $query
        }
    } catch {
            if ($EnableException) {
                throw
            } else {
                Write-Warning -Message "Schema could not be initialized: $_"
            }
    }
}
