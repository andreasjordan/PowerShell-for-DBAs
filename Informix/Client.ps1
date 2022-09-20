$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1

<#

Documentation for silent installation:

Page for manual download:

I use this version: Client-SDK 4.50.FC8

#>

$softwareInformix = [PSCustomObject]@{
    ZipFile     = "$EnvironmentSoftwareBase\Informix\INFO_CLT_SDK_WIN_64_4.50.FC8.zip"
    Sha256      = '0C23B1330BA95339CBC55C22F283CA2909B5ACBF4027A22A5C58F877BD9D8B9A'
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


# Expand software

if (-not (Test-Path -Path $softwareInformix.TempPath)) {
    Expand-Archive -Path $softwareInformix.ZipFile -DestinationPath $softwareInformix.TempPath
}


# Install software

# On Windows Server 2022, I had to install an older version of Java to get the installer running.
# I used jre-8u181-windows-x64.exe from https://www.oracle.com/de/java/technologies/javase/javase8-archive-downloads.html.
# Installed that to C:\Java and then run the the installer with "installclientsdk.exe LAX_VM C:\Java\bin\java.exe".

# I don't have a silent installation yet - so I recommended installing via installclientsdk.exe gui.
# Use the following settings:
# * Path: C:\Informix
# * Install Set: Typical


# Test installation

try {
    Add-Type -Path "C:\Informix\bin\netf40\IBM.Data.Informix.dll"
} catch {
    throw "Installation failed: $_"
}


# Remove temp folder

Remove-Item -Path $softwareInformix.TempPath -Recurse -Force
