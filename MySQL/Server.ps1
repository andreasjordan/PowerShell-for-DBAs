$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\EnvironmentServer.ps1

<#

Documentation for silent installation:
https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinw/installing-oracle-database-xe.html#GUID-E6A7B665-134B-4EF3-AB78-A33A54908EB9

Page for manual download:
https://www.oracle.com/database/technologies/xe-downloads.html

#>

$softwareMySQL = [PSCustomObject]@{
    MsiFile      = "$EnvironmentSoftwareBase\MySQL\mysql-installer-community-8.0.30.0.msi"
    Sha256       = '5A2181B9875B0B025B7FC776D61947AED1884E1D752BE6249FA9CE3541D22531'
    ComputerName = $EnvironmentServerComputerName
    Credential   = $EnvironmentWindowsAdminCredential
    Parameters   = @{
        Password   = $EnvironmentDatabaseAdminPassword
    }
}


# Test if software was downloaded

if (-not (Test-Path -Path $softwareMySQL.MsiFile)) {
    throw "file not found"
}


# Test for correct cecksum

if ((Get-FileHash -Path $softwareMySQL.MsiFile -Algorithm SHA256).Hash -ne $softwareMySQL.Sha256) {
    throw "Checksum does not match"
}


# Install software

# I have not found an easy way for a silent installation - so I recommended installing via mysql-installer-community-8.0.30.0.msi.
# Use the following settings:
# * Choosing a Setup Type: Server only
# * Config Type: Server Computer (or Dedicated Computer if this is the only DBMS installed)
# * MySQL Root Password: start123


# Test installation

if ((Get-Service -ComputerName $softwareMySQL.ComputerName -Name MySQL80).Count -ne 1) {
    throw "Installation failed"
}
