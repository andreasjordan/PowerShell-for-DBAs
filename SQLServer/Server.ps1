$ErrorActionPreference = 'Stop'

$softwareSQLServer = [PSCustomObject]@{
    ExeFile      = '\\fs\Software\SQLServer\SQLEXPR_x64_ENU.exe'
    Sha256       = '702D304852293F76D563C8DB09680856D85E537B08EB1401B3E283BA7847607B'
    TempPath     = 'C:\temp_SQLServer_Express'

    ComputerName = $serverComputerName
    Credential   = $windowsAdminCredential
    Parameters   = @(
        '/IACCEPTSQLSERVERLICENSETERMS'
        '/QUIET'
        '/ACTION=INSTALL'
        '/UpdateEnabled=False'
        '/FEATURES=SQLENGINE'
        '/INSTANCENAME=SQLEXPRESS'
        '/INSTANCEDIR="D:\SQLServer"'
        '/SECURITYMODE=SQL'
        '/SAPWD=start123'
        '/TCPENABLED=1'
    )
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

$result = Invoke-Program -Session $session -FilePath "$($softwareSQLServer.TempPath)\setup.exe" -ArgumentList $softwareSQLServer.Parameters
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
    DisplayName = 'SQL Server'
    Name        = 'SQL Server'
    Group       = 'SQL Server'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    Program     = "D:\SQLServer\MSSQL15.SQLEXPRESS\MSSQL\Binn\sqlservr.exe"
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
        Remove-Item -Path 'D:\SQLServer' -Recurse -Force
        Remove-Item -Path $using:softwareSQLServer.TempPath -Recurse -Force
        Restart-Computer -Force
    }
} else {
    $result
}

# TODO: Remove firewall

#>
