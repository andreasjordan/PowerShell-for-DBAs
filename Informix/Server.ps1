$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\EnvironmentServer.ps1
. ..\PowerShell\Invoke-Program.ps1

<#

Documentation for silent installation:
https://www.ibm.com/docs/en/informix-servers/14.10?topic=installations-running-silent-installation

I use this version: IBM Informix 14.10

#>

$softwareInformix = [PSCustomObject]@{
    ZipFile     = "$EnvironmentSoftwareBase\Informix\IDS.14.10.FC8.WIN.zip"
    Sha256      = '559D5B29887808275766B8CECFD49DF5FA8477C4395E36FAAD2978B3E8160688'
    TempPath    = 'C:\temp_Informix'
    ComputerName = $EnvironmentServerComputerName
    Credential   = $EnvironmentWindowsAdminCredential
}


# Test if software was downloaded

if (-not (Test-Path -Path $softwareInformix.ZipFile)) {
    throw "file not found"
}


# Test for correct cecksum

if ((Get-FileHash -Path $softwareInformix.ZipFile -Algorithm SHA256).Hash -ne $softwareInformix.Sha256) {
    throw "Checksum does not match"
}


# Install software

$session = New-PSSession -ComputerName $softwareInformix.ComputerName -Credential $softwareInformix.Credential -Authentication Credssp

if (-not (Invoke-Command -Session $session -ScriptBlock { Test-Path -Path $using:softwareInformix.TempPath })) {
    Invoke-Command -Session $session -ScriptBlock { Expand-Archive -Path $using:softwareInformix.ZipFile -DestinationPath $using:softwareInformix.TempPath }
}

$session | Remove-PSSession


# I don't have a silent installation yet - so I recommended installing via ids_install.exe gui.

# On Windows Server 2022, I had to install an older version of Java to get the installer running.
# I used jre-8u181-windows-x64.exe from https://www.oracle.com/de/java/technologies/javase/javase8-archive-downloads.html.
# Installed that to D:\Java and then run the the installer with "ids_install.exe LAX_VM D:\Java\bin\java.exe".

# Use the following settings:
# * Choose location for software installation: D:\Informix
# * Select the installation type or distribution method: Typical installation
# * Passwords: start123
# * Let the installer create the database server instance and the the installer initialize the instance after creation.
# * Select the expected number of database users: 1 - 100 users


# Test installation

if ((Get-Service -ComputerName $softwareInformix.ComputerName -DisplayName Informix*).Count -ne 1) {
    throw "Installation failed"
}


# Get service names and ports - needed to connect from the client

$serviceDetails = Invoke-Command -ComputerName $softwareInformix.ComputerName -Authentication Credssp -Credential $softwareInformix.Credential -ScriptBlock { 
    $service = Get-Service -DisplayName Informix*
    Get-Content -Path "$env:SystemRoot\System32\drivers\etc\services" | ForEach-Object -Process { 
        if ($_ -match "^((ol|dr)_$($service.Name.Substring(3)))\s+(\d+)" ) {
            [PSCustomObject]@{
                Service  = $Matches[1]
                Protocol = $Matches[2]
                Port     = $Matches[3]
            }
        }
    }
}
$serviceDetails | Format-Table -Property Service, Port


# Setup Firewall

$cimSession = New-CimSession -ComputerName $softwareInformix.ComputerName

foreach ($detail in $serviceDetails) {
    $firewallConfig = @{
        DisplayName = "IBM Informix $($detail.Service)"
        Name        = "IBM Informix $($detail.Service)"
        Group       = 'IBM Informix'
        Enabled     = 'True'
        Direction   = 'Inbound'
        Protocol    = 'TCP'
        LocalPort   = $detail.Port
    }
    $null = New-NetFirewallRule -CimSession $cimSession @firewallConfig
}

$cimSession | Remove-CimSession


# Disable IPv6
# https://www.ibm.com/docs/en/informix-servers/14.10?topic=communication-informix-support-ipv6-addresses

Invoke-Command -ComputerName $softwareInformix.ComputerName -Authentication Credssp -Credential $softwareInformix.Credential -ScriptBlock { 
    $null | Set-Content -Path D:\Informix\etc\IFX_DISABLE_IPV6
    Get-Service -DisplayName Informix* | Restart-Service
}


# Remove temp folder

Invoke-Command -ComputerName $softwareInformix.ComputerName -Authentication Credssp -Credential $softwareInformix.Credential -ArgumentList $softwareInformix -ScriptBlock { 
    param($Software)
    Remove-Item -Path $Software.TempPath -Recurse -Force
}
