$ErrorActionPreference = 'Stop'

if (-not $Env:MYSQL_INSTANCE) {
    throw 'Environment variable MYSQL_INSTANCE not set'
}
if (-not $Env:MYSQL_DATABASE) {
    throw 'Environment variable MYSQL_DATABASE not set'
}
if (-not $Env:MYSQL_USERNAME) {
    throw 'Environment variable MYSQL_USERNAME not set'
}
if (-not $Env:MYSQL_PASSWORD) {
    $credential = Get-Credential -Message $Env:MYSQL_INSTANCE -UserName $Env:MYSQL_USERNAME
} else {
    $credential = [PSCredential]::new($Env:MYSQL_USERNAME, (ConvertTo-SecureString -String $Env:MYSQL_PASSWORD -AsPlainText -Force))
}

. $PSScriptRoot\Import-MyLibrary.ps1
. $PSScriptRoot\Connect-MyInstance.ps1
. $PSScriptRoot\Invoke-MyQuery.ps1
. $PSScriptRoot\Write-MyTable.ps1
. $PSScriptRoot\..\PowerShell\Import-Schema.ps1
. $PSScriptRoot\..\PowerShell\Import-Data.ps1

try {
    Import-MyLibrary -EnableException

    $connection = Connect-MyInstance -Instance $Env:MYSQL_INSTANCE -Credential $credential -Database $Env:MYSQL_DATABASE -EnableException

    $tables = Invoke-MyQuery -Connection $connection -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = '$($Env:MYSQL_USERNAME.ToLower())'" -As SingleValue -EnableException
    foreach ($table in $tables) {
        Invoke-MyQuery -Connection $connection -Query ("DROP TABLE $table") -EnableException
    }

    Import-Schema -Path $PSScriptRoot\..\PowerShell\SampleSchema.psd1 -DBMS MySQL -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path $PSScriptRoot\..\PowerShell\SampleData.json -DBMS MySQL -Connection $connection -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()
    
    Write-Host "Data import to $Env:MYSQL_INSTANCE finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $Env:MYSQL_INSTANCE failed: $_"
}
