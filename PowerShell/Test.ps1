# Set-Location -Path .\PowerShell
$ErrorActionPreference = 'Stop'

$hostname = 'DockerDatabases'
$credential = [PSCredential]::new('stackoverflow', (ConvertTo-SecureString -String 'Passw0rd!' -AsPlainText -Force))
$database = 'stackoverflow'

$dataPath = 'C:\tmp\stackexchange'
if (Test-Path -Path $dataPath) {
    Remove-Item -Path $dataPath -Recurse -Force
}
$null = New-Item -Path $dataPath -ItemType Directory
Push-Location -Path $dataPath
#Invoke-WebRequest -Uri https://archive.org/download/stackexchange/dba.stackexchange.com.7z -OutFile tmp.7z -UseBasicParsing
Invoke-WebRequest -Uri https://archive.org/download/stackexchange/dba.meta.stackexchange.com.7z -OutFile tmp.7z -UseBasicParsing
$null = C:\Progra~1\7-Zip\7z.exe e tmp.7z
Remove-Item -Path tmp.7z
Pop-Location

$config = @(
    @{
        Folder   = 'SQLServer'
        Prefix   = 'Sql'
        Instance = @{
            Instance   = $hostname
            Credential = $credential
            Database   = $database
        }
    }
    @{
        Library  = $true
        Folder   = 'Oracle'
        Prefix   = 'Ora'
        Instance = @{
            Instance   = "$hostname/XEPDB1"
            Credential = $credential
        }
    }
    @{
        Library  = $true
        Folder   = 'MySQL'
        Prefix   = 'My'
        Instance = @{
            Instance   = $hostname
#            Instance   = "$($hostname):13306"  # MariaDB
            Credential = $credential
            Database   = $database
        }
    }
    @{
        Library  = $true
        Folder   = 'PostgreSQL'
        Prefix   = 'Pg'
        Instance = @{
            Instance   = $hostname
            Credential = $credential
            Database   = $database
        }
    }
)

$tables = 'Badges', 'Comments', 'PostLinks', 'Posts', 'Users', 'Votes'

. .\Import-Schema.ps1

foreach ($cfg in $config) {
    # $cfg = $config[-1]

    Write-PSFMessage -Level Host -Message "Starting with $($cfg.Folder)"

    if ($cfg.Library) {
        . ..\$($cfg.Folder)\Import-$($cfg.Prefix)Library.ps1
        Invoke-Expression "Import-$($cfg.Prefix)Library"
    }
    . ..\$($cfg.Folder)\Connect-$($cfg.Prefix)Instance.ps1
    . ..\$($cfg.Folder)\Invoke-$($cfg.Prefix)Query.ps1
    . ..\$($cfg.Folder)\Read-$($cfg.Prefix)Query.ps1
    . ..\$($cfg.Folder)\Import-$($cfg.Prefix)Table.ps1
    . ..\$($cfg.Folder)\Export-$($cfg.Prefix)Table.ps1
    . ..\$($cfg.Folder)\Get-$($cfg.Prefix)TableInformation.ps1
    . ..\$($cfg.Folder)\Get-$($cfg.Prefix)TableReader.ps1
    . ..\$($cfg.Folder)\Write-$($cfg.Prefix)Table.ps1

    $instanceParams = $cfg.Instance
    $connection = Invoke-Expression "Connect-$($cfg.Prefix)Instance @instanceParams"
    $sourceConnection = Invoke-Expression "Connect-$($cfg.Prefix)Instance @instanceParams"
    $targetConnection = Invoke-Expression "Connect-$($cfg.Prefix)Instance @instanceParams"

    Write-PSFMessage -Level Host -Message "Refresh schema"
    $tableInfo = Invoke-Expression ('Get-{0}TableInformation -Connection $connection -EnableException' -f $cfg.Prefix)
    foreach ($table in $tableInfo.Table) {
        Invoke-Expression ('Invoke-{0}Query -Connection $connection -Query "DROP TABLE $table" -EnableException' -f $cfg.Prefix)
    }
    Import-Schema -Path .\SampleSchema.psd1 -DBMS $cfg.Folder -Connection $connection -EnableException

    Write-PSFMessage -Level Host -Message "Testing Import-$($cfg.Prefix)Table with xml"
    foreach ($table in $tables) {
        if ($table -eq 'Badges') {
            $columnMap = '-ColumnMap @{ CreationDate = "Date" }'
        } else {
            $columnMap = ''
        }
        Invoke-Expression ('Import-{0}Table -Path $dataPath\$table.xml -Connection $connection -Table $table -TruncateTable {1} -EnableException' -f $cfg.Prefix, $columnMap)
    }

    Write-PSFMessage -Level Host -Message "Testing Export-$($cfg.Prefix)Table"
    foreach ($table in $tables) {
        Invoke-Expression ('Export-{0}Table -Connection $connection -Table $table -Path $dataPath\$($table)_$($cfg.Folder).json -EnableException' -f $cfg.Prefix)
    }
    
    Write-PSFMessage -Level Host -Message "Testing Import-$($cfg.Prefix)Table with json"
    foreach ($table in $tables) {
        Invoke-Expression ('Import-{0}Table -Path $dataPath\$($table)_$($cfg.Folder).json -Connection $connection -Table $table -TruncateTable -EnableException' -f $cfg.Prefix)
    }
    
    Write-PSFMessage -Level Host -Message "Testing Get-$($cfg.Prefix)TableInformation, Get-$($cfg.Prefix)TableReade and Write-$($cfg.Prefix)Table"
    foreach ($table in $tables) {
        if ($cfg.Prefix -eq 'Sql') {
            Invoke-SqlQuery -Connection $connection -Query "SELECT * INTO $($table)Copy FROM $table WHERE 1=0" -EnableException
        } else {
            Invoke-Expression ('Invoke-{0}Query -Connection $connection -Query "CREATE TABLE $($table)Copy AS SELECT * FROM $table WHERE 1=0" -EnableException' -f $cfg.Prefix)
        }
    }
    $tableInfo = Invoke-Expression ('Get-{0}TableInformation -Connection $sourceConnection -Table $tables -EnableException' -f $cfg.Prefix)
    foreach ($info in $tableInfo) {
        $reader = Invoke-Expression ('Get-{0}TableReader -Connection $sourceConnection -Table $info.Table -EnableException' -f $cfg.Prefix)
        Invoke-Expression ('Write-{0}Table -Connection $targetConnection -Table "$($info.Table)Copy" -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException' -f $cfg.Prefix)
    }
    foreach ($table in $tables) {
        Invoke-Expression ('Invoke-{0}Query -Connection $connection -Query "DROP TABLE $($table)Copy" -EnableException' -f $cfg.Prefix)
    }

    Write-PSFMessage -Level Host -Message "Testing Read-$($cfg.Prefix)Query and Write-$($cfg.Prefix)Table"
    if ($cfg.Prefix -eq 'Sql') {
        Invoke-SqlQuery -Connection $connection -Query "SELECT * INTO Questions FROM Posts WHERE 1=0" -EnableException
    } else {
        Invoke-Expression ('Invoke-{0}Query -Connection $connection -Query "CREATE TABLE Questions AS SELECT * FROM Posts WHERE 1=0" -EnableException' -f $cfg.Prefix)
    }

    if ($cfg.Prefix -eq 'Sql') {
        Read-SqlQuery -Connection $sourceConnection -Query "SELECT * FROM Posts WHERE PostTypeId = 1" | 
            ForEach-Object `
                -Begin {
                    Write-PSFMessage -Level Verbose -Message "Begin"
                    [System.Collections.ArrayList]$data = @() 
                    $rows = 0
                } `
                -Process {
                    $null = $data.Add($_)
                    $rows++
                    if ($rows%10000 -eq 0) {
                        Write-SqlTable -Connection $targetConnection -Table Questions -Data $data
                        $data.Clear()
                        Write-PSFMessage -Level Verbose -Message "Process - $rows rows processed"
                    }
                } `
                -End {
                    Write-SqlTable -Connection $targetConnection -Table Questions -Data $data
                    $data.Clear()
                    Write-PSFMessage -Level Verbose -Message "End - $rows rows processed"
                }
    } elseif ($cfg.Prefix -eq 'Ora') {
        Read-OraQuery -Connection $sourceConnection -Query "SELECT * FROM Posts WHERE PostTypeId = 1" | 
            ForEach-Object `
                -Begin {
                    Write-PSFMessage -Level Verbose -Message "Begin"
                    [System.Collections.ArrayList]$data = @() 
                    $rows = 0
                } `
                -Process {
                    $null = $data.Add($_)
                    $rows++
                    if ($rows%10000 -eq 0) {
                        Write-OraTable -Connection $targetConnection -Table Questions -Data $data
                        $data.Clear()
                        Write-PSFMessage -Level Verbose -Message "Process - $rows rows processed"
                    }
                } `
                -End {
                    Write-OraTable -Connection $targetConnection -Table Questions -Data $data
                    $data.Clear()
                    Write-PSFMessage -Level Verbose -Message "End - $rows rows processed"
                }
    } elseif ($cfg.Prefix -eq 'My') {
        Read-MyQuery -Connection $sourceConnection -Query "SELECT * FROM Posts WHERE PostTypeId = 1" | 
            ForEach-Object `
                -Begin {
                    Write-PSFMessage -Level Verbose -Message "Begin"
                    [System.Collections.ArrayList]$data = @() 
                    $rows = 0
                } `
                -Process {
                    $null = $data.Add($_)
                    $rows++
                    if ($rows%10000 -eq 0) {
                        Write-MyTable -Connection $targetConnection -Table Questions -Data $data
                        $data.Clear()
                        Write-PSFMessage -Level Verbose -Message "Process - $rows rows processed"
                    }
                } `
                -End {
                    Write-MyTable -Connection $targetConnection -Table Questions -Data $data
                    $data.Clear()
                    Write-PSFMessage -Level Verbose -Message "End - $rows rows processed"
                }
    } elseif ($cfg.Prefix -eq 'Pg') {
        Read-PgQuery -Connection $sourceConnection -Query "SELECT * FROM Posts WHERE PostTypeId = 1" | 
            ForEach-Object `
                -Begin {
                    Write-PSFMessage -Level Verbose -Message "Begin"
                    [System.Collections.ArrayList]$data = @() 
                    $rows = 0
                } `
                -Process {
                    $null = $data.Add($_)
                    $rows++
                    if ($rows%10000 -eq 0) {
                        Write-PgTable -Connection $targetConnection -Table Questions -Data $data
                        $data.Clear()
                        Write-PSFMessage -Level Verbose -Message "Process - $rows rows processed"
                    }
                } `
                -End {
                    Write-PgTable -Connection $targetConnection -Table Questions -Data $data
                    $data.Clear()
                    Write-PSFMessage -Level Verbose -Message "End - $rows rows processed"
                }
    }
    Invoke-Expression ('Invoke-{0}Query -Connection $connection -Query "DROP TABLE Questions" -EnableException' -f $cfg.Prefix)
}

Write-PSFMessage -Level Host -Message "Testing Transfer from SQLServer to Oracle"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Sql').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Ora').Instance
$sourceConnection = Connect-SqlInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-OraInstance @targetInstanceParams -EnableException
$tableInfo = Get-SqlTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-SqlTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-OraTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from SQLServer to MySQL"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Sql').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'My').Instance
$sourceConnection = Connect-SqlInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-MyInstance @targetInstanceParams -EnableException
$tableInfo = Get-SqlTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-SqlTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-MyTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from SQLServer to PostgreSQL"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Sql').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Pg').Instance
$sourceConnection = Connect-SqlInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-PgInstance @targetInstanceParams -EnableException
$tableInfo = Get-SqlTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-SqlTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-PgTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from Oracle to SQLServer"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Ora').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Sql').Instance
$sourceConnection = Connect-OraInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-SqlInstance @targetInstanceParams -EnableException
$tableInfo = Get-OraTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-OraTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-SqlTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from Oracle to MySQL"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Ora').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'My').Instance
$sourceConnection = Connect-OraInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-MyInstance @targetInstanceParams -EnableException
$tableInfo = Get-OraTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-OraTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-MyTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from Oracle to PostgreSQL"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Ora').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Pg').Instance
$sourceConnection = Connect-OraInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-PgInstance @targetInstanceParams -EnableException
$tableInfo = Get-OraTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-OraTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-PgTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from MySQL to SQLServer"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'My').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Sql').Instance
$sourceConnection = Connect-MyInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-SqlInstance @targetInstanceParams -EnableException
$tableInfo = Get-MyTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-MyTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-SqlTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from MySQL to Oracle"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'My').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Ora').Instance
$sourceConnection = Connect-MyInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-OraInstance @targetInstanceParams -EnableException
$tableInfo = Get-MyTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-MyTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-OraTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from MySQL to PostgreSQL"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'My').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Pg').Instance
$sourceConnection = Connect-MyInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-PgInstance @targetInstanceParams -EnableException
$tableInfo = Get-MyTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-MyTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-PgTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from PostgreSQL to SQLServer"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Pg').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Sql').Instance
$sourceConnection = Connect-PgInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-SqlInstance @targetInstanceParams -EnableException
$tableInfo = Get-PgTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-PgTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-SqlTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from PostgreSQL to Oracle"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Pg').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'Ora').Instance
$sourceConnection = Connect-PgInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-OraInstance @targetInstanceParams -EnableException
$tableInfo = Get-PgTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-PgTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    Write-OraTable -Connection $targetConnection -Table $info.Table -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Testing Transfer from PostgreSQL to MySQL"
$sourceInstanceParams = ($config | Where-Object Prefix -eq 'Pg').Instance
$targetInstanceParams = ($config | Where-Object Prefix -eq 'My').Instance
$sourceConnection = Connect-PgInstance @sourceInstanceParams -EnableException
$targetConnection = Connect-MyInstance @targetInstanceParams -EnableException
$tableInfo = Get-PgTableInformation -Connection $sourceConnection -Table $tables -EnableException
foreach ($info in $tableInfo) {
    $reader = Get-PgTableReader -Connection $sourceConnection -Table $info.Table -EnableException
    # PostgreSQL uses all lowercase names, for MySQL we need the original case.
    $targetTable = $tables | Where-Object { $_ -eq $info.Table }
    Write-MyTable -Connection $targetConnection -Table $targetTable -DataReader $reader -DataReaderRowCount $info.Rows -TruncateTable -EnableException
}

Write-PSFMessage -Level Host -Message "Finished"

