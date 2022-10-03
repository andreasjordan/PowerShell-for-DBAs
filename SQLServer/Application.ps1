param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

Import-Module -Name dbatools  # Install-Module -Name dbatools -Scope CurrentUser

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

if ($EnvironmentServerComputerName -in 'localhost', 'SQLServer-1') {
    $instance = $EnvironmentServerComputerName
} else {
    $instance = "$EnvironmentServerComputerName\SQLEXPRESS"
}
$database = 'stackoverflow'

try {
    # $credentialUser = Get-Credential -Message $instance -UserName $EnvironmentDatabaseUserName
    $credential = [PSCredential]::new($EnvironmentDatabaseUserName, (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))
    $connection = Connect-DbaInstance -SqlInstance $instance -SqlCredential $credential -Database $database -NonPooledConnection

    $tables = Invoke-DbaQuery -SqlInstance $connection -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -As SingleValue
    foreach ($table in $tables) {
        Invoke-DbaQuery -SqlInstance $connection -Query ("DROP TABLE $table")
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS SQLServer -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS SQLServer -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $null = $connection | Disconnect-DbaInstance

    Write-Host "Data import to $EnvironmentServerComputerName finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $EnvironmentServerComputerName failed: $_"
}
