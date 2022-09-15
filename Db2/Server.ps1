$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\EnvironmentServer.ps1
. ..\PowerShell\Invoke-Program.ps1

<#

Documentation for silent installation:
https://www.ibm.com/docs/en/db2/11.5?topic=file-windows

Page for manual download:
https://www.ibm.com/db2/trials
Db2 Community Edition
I use this version: IBM Db2 Community Edition 11.5.7.0 (Community)

Sorry, there is no direct download link, you have to sign in and download the file.

If file extention is exe, rename to zip to be able to work with Expand-Archive.

#>

$softwareDb2 = [PSCustomObject]@{
    ZipFile     = "$EnvironmentSoftwareBase\Db2\v11.5.7_ntx64_server_dec.zip"
    Sha256      = 'B041F51D322B99A4F5AA31ABBF2F84A323EE2EB29AADC01E52865B8779E892FF'
    TempPath    = 'C:\temp_Db2'
    ComputerName = $EnvironmentServerComputerName
    Credential   = $EnvironmentWindowsAdminCredential
}


# Test if software was downloaded

if (-not (Test-Path -Path $softwareDb2.ZipFile)) {
    throw "file not found"
}


# Test for correct cecksum

if ((Get-FileHash -Path $softwareDb2.ZipFile -Algorithm SHA256).Hash -ne $softwareDb2.Sha256) {
    throw "Checksum does not match"
}


# Install software

$session = New-PSSession -ComputerName $softwareDb2.ComputerName -Credential $softwareDb2.Credential -Authentication Credssp

if (-not (Invoke-Command -Session $session -ScriptBlock { Test-Path -Path $using:softwareDb2.TempPath })) {
    Invoke-Command -Session $session -ScriptBlock { Expand-Archive -Path $using:softwareDb2.ZipFile -DestinationPath $using:softwareDb2.TempPath }
}

$session | Remove-PSSession


# Set up accounts and groups:
# Create the group DB2ADMNS in the domain and add the domain account that runs the installation on the target server
# Create the group DB2USERS in the domain
# Create the user db2admin in the domain and add it to the domain DB2ADMNS group and the local Administrators group on the target server

# I don't have a silent installation yet - so I recommended installing via setup.exe gui.
# Use the following settings:
# * Select the installation type: Typical 
# * Select the installation folder: Directory: D:\Db2\SQLLIB\
# * Set user information for the DB2 Administrator Server: Use global user
# * Set up notifications: Uncheck box
# * Enable operating system security for DB2 objects: Use global groups


# Test installation

if ((Get-Service -ComputerName $softwareDb2.ComputerName -Name DB2*).Count -ne 6) {
    throw "Installation failed"
}


# Setup Firewall

$cimSession = New-CimSession -ComputerName $softwareDb2.ComputerName

$firewallConfig = @{
    DisplayName = 'IBM Db2'
    Name        = 'IBM Db2'
    Group       = 'IBM Db2'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    LocalPort   = '25000'
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$cimSession | Remove-CimSession


# Remove temp folder

Invoke-Command -ComputerName $softwareDb2.ComputerName -Authentication Credssp -Credential $softwareDb2.Credential -ArgumentList $softwareDb2 -ScriptBlock { 
    param($Software)
    Remove-Item -Path $Software.TempPath -Recurse -Force
}

