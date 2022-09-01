$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\EnvironmentServer.ps1
. ..\PowerShell\Invoke-Program.ps1

$softwareSQLServer = [PSCustomObject]@{
    ExeFile      = "$EnvironmentSoftwareBase\SQLServer\SQLEXPR_x64_ENU.exe"
    Sha256       = '702D304852293F76D563C8DB09680856D85E537B08EB1401B3E283BA7847607B'
    TempPath     = 'C:\temp_SQLServer_Express'
    ComputerName = $EnvironmentServerComputerName
    Credential   = $EnvironmentWindowsAdminCredential
    Parameters   = @{
        INSTANCEDIR = 'D:\SQLServer'
        SAPWD       = $EnvironmentDatabaseAdminPassword
    }
}


# Test if software was downloaded

if (-not (Test-Path -Path $softwareSQLServer.ExeFile)) {
    throw "file not found"
}


# Test for correct cecksum

if ((Get-FileHash -Path $softwareSQLServer.ExeFile -Algorithm SHA256).Hash -ne $softwareSQLServer.Sha256) {
    throw "Checksum does not match"
}


# Install software

$session = New-PSSession -ComputerName $softwareSQLServer.ComputerName -Credential $softwareSQLServer.Credential -Authentication Credssp

if (-not (Invoke-Command -Session $session -ScriptBlock { Test-Path -Path $using:softwareSQLServer.TempPath })) {
    $result = Invoke-Program -Session $session -FilePath $softwareSQLServer.ExeFile -ArgumentList '/q', "/x:$($softwareSQLServer.TempPath)"
    if (-not $result.Successful) {
        $result
        throw "Extraction failed"
    }
}

$argumentList = @(
    '/IACCEPTSQLSERVERLICENSETERMS'
    '/QUIET'
    '/ACTION=INSTALL'
    '/UpdateEnabled=False'
    '/FEATURES=SQLENGINE'
    '/INSTANCENAME=SQLEXPRESS'
    '/INSTANCEDIR="{0}"' -f $softwareSQLServer.Parameters.INSTANCEDIR
    '/SECURITYMODE=SQL'
    '/SAPWD={0}' -f $softwareSQLServer.Parameters.SAPWD
    '/TCPENABLED=1'
)

$result = Invoke-Program -Session $session -FilePath "$($softwareSQLServer.TempPath)\setup.exe" -ArgumentList $argumentList
if (-not $result.Successful) {
    $result
    throw "Installation failed"
}

# In case of a failure:
# Invoke-Command -Session $session -ScriptBlock { Get-ChildItem -Path 'C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log' }
# $summary = Invoke-Command -Session $session -ScriptBlock { Get-Content -Path 'C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log\Summary.txt' }


# Test installation

if ((Get-Service -ComputerName $softwareSQLServer.ComputerName -Name 'MSSQL$SQLEXPRESS').Count -ne 1) {
    throw "Installation failed"
}


# Setup Firewall

$cimSession = New-CimSession -ComputerName $softwareSQLServer.ComputerName

$firewallConfig = @{
    DisplayName = 'SQL Server SQLEXPRESS Instance'
    Name        = 'SQL Server SQLEXPRESS Instance'
    Group       = 'SQL Server'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    Program     = "$($softwareSQLServer.Parameters.INSTANCEDIR)\MSSQL15.SQLEXPRESS\MSSQL\Binn\sqlservr.exe"
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$firewallConfig = @{
    DisplayName = 'SQL Server Browser'
    Name        = 'SQL Server Browser'
    Group       = 'SQL Server'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'UDP'
    LocalPort   = '1434'
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$cimSession | Remove-CimSession


# Remove temp folder

Invoke-Command -ComputerName $softwareSQLServer.ComputerName -Authentication Credssp -Credential $softwareSQLServer.Credential -ArgumentList $softwareSQLServer -ScriptBlock { 
    param($Software)
    Remove-Item -Path $Software.TempPath -Recurse -Force
}




<# Remove SQLServer:

$cimSession = New-CimSession -ComputerName $softwareSQLServer.ComputerName
Get-NetFirewallRule -CimSession $cimSession -Group 'SQL Server' | Remove-NetFirewallRule
$cimSession | Remove-CimSession

$session = New-PSSession -ComputerName $softwareSQLServer.ComputerName -Credential $softwareSQLServer.Credential -Authentication Credssp

if (-not (Invoke-Command -Session $session -ScriptBlock { Test-Path -Path $using:softwareSQLServer.TempPath })) {
    $result = Invoke-Program -Session $session -FilePath $softwareSQLServer.ExeFile -ArgumentList '/q', "/x:$($softwareSQLServer.TempPath)"
    if (-not $result.Successful) {
        $result
        throw "Extraction failed"
    }
}

$argumentList = @(
    '/IACCEPTSQLSERVERLICENSETERMS'
    '/QUIET'
    '/ACTION=UNINSTALL'
    '/FEATURES=SQLENGINE'
    '/INSTANCENAME=SQLEXPRESS'
)

$result = Invoke-Program -Session $session -FilePath "$($softwareSQLServer.TempPath)\setup.exe" -ArgumentList $argumentList
if ($result.Successful) {
    Invoke-Command -ComputerName $softwareSQLServer.ComputerName -ScriptBlock {
        Remove-Item -Path $using:softwareSQLServer.Parameters.INSTANCEDIR -Recurse -Force
        Remove-Item -Path $using:softwareSQLServer.TempPath -Recurse -Force
        Restart-Computer -Force
    }
} else {
    $result
    throw "Uninstallation failed"
}

$session | Remove-PSSession

#>
