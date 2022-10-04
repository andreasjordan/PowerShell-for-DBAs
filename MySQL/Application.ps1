param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

if (-not $Env:MYSQL_DLL) {
    throw 'Environment variable MYSQL_DLL not set'
}
if (-not (Test-Path -Path $Env:MYSQL_DLL)) {
    throw "Environment variable MYSQL_DLL not set correctly, file [$Env:MYSQL_DLL] not found"
}
# Ignore the following errors: Could not load file or assembly
# For details see: https://community.oracle.com/tech/developers/discussion/4502297
try { Add-Type -Path $Env:MYSQL_DLL } catch { }
if ($Env:MYSQL_DLL -match 'Devart') {
    . .\Connect-MyInstance_Devart.ps1
    . .\Invoke-MyQuery_Devart.ps1
} else {
    . .\Connect-MyInstance.ps1
    . .\Invoke-MyQuery.ps1
}
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

. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

try {
    $connection = Connect-MyInstance -Instance $Env:MYSQL_INSTANCE -Credential $credential -Database $Env:MYSQL_DATABASE -EnableException

    $tables = Invoke-MyQuery -Connection $connection -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = '$($Env:MYSQL_USERNAME.ToLower())'" -As SingleValue -EnableException
    foreach ($table in $tables) {
        Invoke-MyQuery -Connection $connection -Query ("DROP TABLE $table") -EnableException
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS MySQL -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS MySQL -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()
    
    Write-Host "Data import to $Env:MYSQL_INSTANCE finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $Env:MYSQL_INSTANCE failed: $_"
}
