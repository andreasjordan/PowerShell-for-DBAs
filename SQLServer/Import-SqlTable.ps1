function Import-SqlTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,
        [Parameter(Mandatory)][string]$Table,
        [int]$BatchSize = 1000,
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8,
        [hashtable]$ColumnMap,
        [switch]$TruncateTable,
        [switch]$EnableException
    )

    Write-PSFMessage -Level Verbose -Message "Importing data from $Path into $Table"

    Write-PSFMessage -Level Verbose -Message "Opening file"
    try {
        $fileStream = [IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $streamReader = [System.IO.StreamReader]::new($fileStream, $Encoding)
    } catch {
        if ($null -ne $streamReader) { $streamReader.Dispose() }
        if ($null -ne $fileStream) { $fileStream.Dispose() }
        Stop-PSFFunction -Message "Opening file failed: $($_.Exception.Message)" -Target $Path -EnableException $EnableException
        return
    }

    Write-PSFMessage -Level Verbose -Message "Getting target schema table"
    Write-Progress -Id 1 -Activity "Getting target schema table for $Table"
    try {
        $command = $Connection.CreateCommand()
        $command.CommandText = "SELECT * FROM $Table"
        $reader = $command.ExecuteReader()
        $targetSchemaTable = $reader.GetSchemaTable()
    } catch {
        Stop-PSFFunction -Message "Getting target schema table failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
        return
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        if ($null -ne $command) { $command.Dispose() }
    }

    if ($TruncateTable) {
        Write-PSFMessage -Level Verbose -Message "Truncating table"
        Write-Progress -Id 1 -Activity "Truncating table"
        try {
            $command = $Connection.CreateCommand()
            $command.CommandText = "TRUNCATE TABLE $Table"
            $null = $command.ExecuteNonQuery()
            $command.Dispose()
        } catch {
            Stop-PSFFunction -Message "Truncating table failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
            return
        } finally {
            if ($null -ne $command) { $command.Dispose() }
        }
    }

    Write-PSFMessage -Level Verbose -Message "Initializing bulk copy"
    Write-Progress -Id 1 -Activity "Initializing bulk copy for $Table"
    try {
        $bulkCopyOptions = 0
        $bulkCopyOptions += [System.Data.SqlClient.SqlBulkCopyOptions]::TableLock
        $bulkCopyOptions += [System.Data.SqlClient.SqlBulkCopyOptions]::UseInternalTransaction
        $bulkCopy = [System.Data.SqlClient.SqlBulkCopy]::new($Connection, $bulkCopyOptions, $null)
        $bulkCopy.DestinationTableName = $Table
        $bulkCopy.BatchSize = $BatchSize
        $bulkCopy.BulkCopyTimeout = 0
    } catch {
        if ($null -ne $bulkCopy) { $bulkCopy.Dispose() }
        Stop-PSFFunction -Message "Initializing bulk copy failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
        return
    }

    Write-PSFMessage -Level Verbose -Message "Creating data table"
    $dataTable = [System.Data.DataTable]::new()
    foreach ($column in $targetSchemaTable) { $null = $dataTable.Columns.Add($column.ColumnName, $column.DataType) }

    Write-PSFMessage -Level Verbose -Message "Inserting rows"
    Write-Progress -Id 1 -Activity "Inserting rows into $Table" -Status ("0 of {0:n0} bytes transfered, 0 rows created" -f $fileStream.Length)
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $dataType = $null
        $rowCount = 0
        while (-not $streamReader.EndOfStream) {
            $line = $streamReader.ReadLine()
            if ($null -eq $dataType) {
                if ($line.Substring(0, 5) -eq '<?xml') {
                    $dataType = 'xml'
                } elseif ($line.Substring(0, 1) -eq '{') {
                    $dataType = 'json'
                }
            }
            $rowObject = $null
            if ($dataType -eq 'xml' -and $line.Substring(0, 6) -eq '  <row') {
                $rowObject = ([xml]$line).row
            } elseif ($dataType -eq 'json') {
                $rowObject = $line | ConvertFrom-Json
            }
            if ($null -ne $rowObject) {
                $newRow = $dataTable.NewRow()
                foreach ($column in $targetSchemaTable) {
                    if ($column.ColumnName -in $ColumnMap.Keys) {
                        $sourceColumnName = $ColumnMap[$column.ColumnName]
                    } else {
                        $sourceColumnName = $column.ColumnName
                    }
                    $value = $rowObject.$sourceColumnName
                    if ($null -ne $value) {
                        $newRow[$column.ColumnName] = $value
                    }
                }
                $dataTable.Rows.Add($newRow)
                $rowCount += 1

                if ($rowCount % $BatchSize -eq 0) {
                    $bulkCopy.WriteToServer($dataTable)
                    $dataTable.Clear()
        
                    $progressParam = @{ 
                        Id               = 1
                        Activity         = 'Inserting rows into {0}' -f $Table
                        Status           = '{0:n0} of {1:n0} bytes transfered' -f $fileStream.Position, $fileStream.Length
                        SecondsRemaining = $stopwatch.Elapsed.TotalSeconds * ($fileStream.Length - $fileStream.Position) / $fileStream.Position
                        PercentComplete  = $fileStream.Position * 100 / $fileStream.Length
                        CurrentOperation = '{0:n0} rows created, {1:n0} rows per second' -f $rowCount, ($rowCount / $stopwatch.Elapsed.TotalSeconds)
                    }
                    Write-Progress @progressParam
                }
            }
        }
        $bulkCopy.WriteToServer($dataTable)
    } catch {
        Stop-PSFFunction -Message "Inserting rows failed: $($_.Exception.InnerException.Message)" -Target $Table -EnableException $EnableException
        return
    } finally {
        if ($null -ne $bulkCopy) { $bulkCopy.Dispose() }
        if ($null -ne $streamReader) { $streamReader.Dispose() }
        if ($null -ne $fileStream) { $fileStream.Dispose() }
        Write-Progress -Id 1 -Activity Completed -Completed
    }
}
