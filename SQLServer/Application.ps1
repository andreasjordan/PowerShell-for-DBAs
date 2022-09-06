$ErrorActionPreference = 'Stop'

Import-Module -Name dbatools  # Install-Module -Name dbatools -Scope CurrentUser

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

$instance = "$EnvironmentServerComputerName\SQLEXPRESS"

# $credentialAdmin = Get-Credential -Message $instance -UserName sa
$credentialAdmin = [PSCredential]::new('sa', (ConvertTo-SecureString -String $EnvironmentDatabaseAdminPassword -AsPlainText -Force))

# $credentialUser  = Get-Credential -Message $instance -UserName StackOverflow
$credentialUser = [PSCredential]::new('StackOverflow', (ConvertTo-SecureString -String $EnvironmentDatabaseUserPassword -AsPlainText -Force))


$connectionAdmin = Connect-DbaInstance -SqlInstance $instance -SqlCredential $credentialAdmin -NonPooledConnection

$null = Remove-DbaDatabase -SqlInstance $connectionAdmin -Database StackOverflow -Confirm:$false
$null = Remove-DbaLogin -SqlInstance $connectionAdmin -Login StackOverflow -Confirm:$false

$null = New-DbaLogin -SqlInstance $connectionAdmin -Login StackOverflow -SecurePassword $credentialUser.Password
$null = New-DbaDatabase -SqlInstance $connectionAdmin -Name StackOverflow -Owner StackOverflow

$null = $connectionAdmin | Disconnect-DbaInstance


$connectionUser = Connect-DbaInstance -SqlInstance $instance -SqlCredential $credentialUser -Database StackOverflow -NonPooledConnection

Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS SQLServer -Connection $connectionUser
$start = Get-Date
Import-Data -Path ..\PowerShell\SampleData.json -DBMS SQLServer -Connection $connectionUser
$duration = (Get-Date) - $start
Write-Host "Data import finished in $($duration.TotalSeconds) seconds"

$null = $connectionUser | Disconnect-DbaInstance
