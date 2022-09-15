$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1

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


# Expand software

if (-not (Test-Path -Path $softwareDb2.TempPath)) {
    Expand-Archive -Path $softwareDb2.ZipFile -DestinationPath $softwareDb2.TempPath
}


# Install software

# I don't have a silent installation yet - so I recommended installing via setup.exe gui.
# Use the following settings:
# * Select the installation type: Typical 
# * Select the installation folder: Directory: C:\Db2\SQLLIB\



# Test installation

try {
    Add-Type -Path "$EnvironmentSoftwareBase\Db2\Microsoft.ReportingServices.Interfaces.dll"
    Add-Type -Path "C:\Db2\SQLLIB\BIN\netf40\IBM.Data.DB2.dll"
} catch {
    throw "Installation failed: $_"
}


# Remove temp folder

Remove-Item -Path $softwareDb2.TempPath -Recurse -Force

