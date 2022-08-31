$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1

<#

Documentation for silent installation:
https://docs.oracle.com/en/database/oracle/oracle-database/19/ntcli/installing-and-configuring-oracle-database-client-using-response-files.html

Page for manual download:
https://www.oracle.com/database/technologies/oracle19c-windows-downloads.html
Oracle Database 19c Client (19.3) for Microsoft Windows x64 (64-bit)
WINDOWS.X64_193000_client.zip
(64-bit) (1,043,502,535 bytes) (sha256sum - 3fa278fe33e0cd3bbed6c84f34b5698962c1feeb74cced1c9713435ebdb2a24f )

Sorry, there is no direct download link, you have to sign in and download the file.

#>

$softwareOracleClient19c = [PSCustomObject]@{
    ZipFile     = "$EnvironmentSoftwareBase\Oracle\WINDOWS.X64_193000_client.zip"
    Sha256      = '3fa278fe33e0cd3bbed6c84f34b5698962c1feeb74cced1c9713435ebdb2a24f'
    TempPath    = 'C:\temp_X64_193000_client'
    OracleBase  = 'D:\oracle'
    OracleHome  = 'D:\oracle\product\19.0.0\client_1'
}


# Test if software was downloaded

if (-not (Test-Path -Path $softwareOracleClient19c.ZipFile)) {
    throw "file not found"
}


# Test for correct cecksum

if ((Get-FileHash -Path $softwareOracleClient19c.ZipFile -Algorithm SHA256).Hash -ne $softwareOracleClient19c.Sha256) {
    throw "Checksum does not match"
}


# Expand software

if (-not (Test-Path -Path $softwareOracleClient19c.TempPath)) {
    Expand-Archive -Path $softwareOracleClient19c.ZipFile -DestinationPath $softwareOracleClient19c.TempPath
}


# Install software

$rspContent = @{
    'ORACLE_BASE'                                      = $softwareOracleClient19c.OracleBase
    'ORACLE_HOME'                                      = $softwareOracleClient19c.OracleHome
    'oracle.install.responseFileVersion'               = '/oracle/install/rspfmt_clientinstall_response_schema_v19.0.0'
    'oracle.install.IsBuiltInAccount'                  = 'true'
    'oracle.install.client.installType'                = 'Custom'
    'oracle.install.client.customComponents'           = 'oracle.ntoledb.odp_net_2:19.0.0.0.0,oracle.sqlplus:19.0.0.0.0'
}
Set-Content -Path "$($softwareOracleClient19c.TempPath)\myInstall.rsp" -Value $rspContent.GetEnumerator().ForEach({ "$($_.Name)=$($_.Value)" })

$argumentList = "-silent -responseFile $($softwareOracleClient19c.TempPath)\myInstall.rsp -noConsole"
Start-Process -FilePath "$($softwareOracleClient19c.TempPath)\client\setup.exe" -ArgumentList $argumentList -Wait


# Test installation

try {
    Add-Type -Path "$($softwareOracleClient19c.OracleHome)\odp.net\managed\common\Oracle.ManagedDataAccess.dll"
} catch {
    throw "Installation failed: $_"
}


# Remove temp folder

Remove-Item -Path $softwareOracleClient19c.TempPath -Recurse -Force

