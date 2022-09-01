$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\EnvironmentServer.ps1
. ..\PowerShell\Invoke-Program.ps1

<#

Documentation for silent installation:
https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinw/installing-oracle-database-xe.html#GUID-E6A7B665-134B-4EF3-AB78-A33A54908EB9

Page for manual download:
https://www.oracle.com/database/technologies/xe-downloads.html

#>

$softwareOracleXe = [PSCustomObject]@{
    DownloadUrl  = 'https://download.oracle.com/otn-pub/otn_software/db-express/OracleXE213_Win64.zip'
    ZipFile      = "$EnvironmentSoftwareBase\Oracle\OracleXE213_Win64.zip"
    Sha256       = '939742c3305c466566a55f607638621b6aa7033a183175f6bcd6cffb48e6bc3f'
    TempPath     = 'C:\temp_OracleXE213_Win64'
    ComputerName = $EnvironmentServerComputerName
    Credential   = $EnvironmentWindowsAdminCredential
    Parameters   = @{
        OracleBase = 'D:\oracle'
        Password   = $EnvironmentDatabaseAdminPassword  # TODO: Which special characters would work?`"P@ssw0rd" does not work.
    }
}


# Download software if needed

if (-not (Test-Path -Path $softwareOracleXe.ZipFile)) {
    Invoke-WebRequest -Uri $softwareOracleXe.DownloadUrl -UseBasicParsing -OutFile $softwareOracleXe.ZipFile
}


# Test for correct cecksum

if ((Get-FileHash -Path $softwareOracleXe.ZipFile -Algorithm SHA256).Hash -ne $softwareOracleXe.Sha256) {
    throw "Checksum does not match"
}


# Install software

$session = New-PSSession -ComputerName $softwareOracleXe.ComputerName -Credential $softwareOracleXe.Credential -Authentication Credssp

if (-not (Invoke-Command -Session $session -ScriptBlock { Test-Path -Path $using:softwareOracleXe.TempPath })) {
    Invoke-Command -Session $session -ScriptBlock { Expand-Archive -Path $using:softwareOracleXe.ZipFile -DestinationPath $using:softwareOracleXe.TempPath }
}


# The silent installation only works from time to time - so I recommended installing via setup.exe gui.
# Use the following settings:
"* Install Oracle Database 21c Express Edition to: $($softwareOracleXe.Parameters.OracleBase)\product\21c\"
"* Enter database password: $($softwareOracleXe.Parameters.Password)"

<# 

Invoke-Command -Session $session -ScriptBlock {
    $rspContent = @{
        INSTALLDIR     = "$($using:softwareOracleXe.Parameters.OracleBase)\product\21c\"
        PASSWORD       = $using:softwareOracleXe.Parameters.Password
        LISTENER_PORT  = '1521'
        EMEXPRESS_PORT = '5550'
        CHAR_SET       = 'AL32UTF8'
        DB_DOMAIN      = ''
    }
    Set-Content -Path "$($using:softwareOracleXe.TempPath)\myInstall.rsp" -Value $rspContent.GetEnumerator().ForEach({ "$($_.Name)=$($_.Value)" })
}

$argumentList = @(
    '/s'
    '/v"RSP_FILE={0}\myInstall.rsp"' -f $softwareOracleXe.TempPath
    '/v"/L*v {0}\setup.log"' -f $softwareOracleXe.TempPath
)
$result = Invoke-Program -Session $session -FilePath "$($softwareOracleXe.TempPath)\setup.exe" -ArgumentList $argumentList

$session | Remove-PSSession

#>

# Test installation

if ((Get-Service -ComputerName $softwareOracleXe.ComputerName -Name Oracle*).Count -ne 5) {
    throw "Installation failed"
}


# Setup Firewall

$cimSession = New-CimSession -ComputerName $softwareOracleXe.ComputerName

$firewallConfig = @{
    DisplayName = 'Oracle Database'
    Name        = 'Oracle Database'
    Group       = 'Oracle'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    Program     = "$($softwareOracleXe.Parameters.OracleBase)\product\21c\dbhomeXE\bin\oracle.exe"
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$firewallConfig = @{
    DisplayName = 'Oracle Listener'
    Name        = 'Oracle Listener'
    Group       = 'Oracle'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    Program     = "$($softwareOracleXe.Parameters.OracleBase)\product\21c\dbhomeXE\bin\tnslsnr.exe"
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$cimSession | Remove-CimSession


# Remove temp folder

Invoke-Command -ComputerName $softwareOracleXe.ComputerName -Authentication Credssp -Credential $softwareOracleXe.Credential -ArgumentList $softwareOracleXe -ScriptBlock { 
    param($Software)
    Remove-Item -Path $Software.TempPath -Recurse -Force
}


<# Install sample schema:

$softwareOracleXe.SampleSchema = '\\fs\SampleDatabases\STACKOVERFLOW.DMP.zip'
Invoke-Command -ComputerName $softwareOracleXe.ComputerName -Authentication Credssp -Credential $softwareOracleXe.Credential -ArgumentList $softwareOracleXe -ScriptBlock { 
    param($Software)

    $schema = $Software.SampleSchema.Split('\')[-1].Split('.')[0]
    $null = New-Item -Path "$($Software.OracleBase)\datapump" -ItemType Directory
    Expand-Archive -Path $Software.SampleSchema -DestinationPath "$($Software.OracleBase)\datapump"

    $null = "CREATE DIRECTORY DATAPUMP AS '$($Software.OracleBase)\datapump';" | sqlplus.exe -S "sys/$($Software.Password)@$($Software.ComputerName)/XEPDB1 AS SYSDBA"
    $null = "GRANT READ, WRITE ON DIRECTORY DATAPUMP TO SYSTEM;" | sqlplus.exe -S "sys/$($Software.Password)@$($Software.ComputerName)/XEPDB1 AS SYSDBA"
    $argumentList = @( "system/$($Software.Password)@$($software.ComputerName)/XEPDB1", 'SILENT=ALL', "SCHEMAS=$schema", 'directory=DATAPUMP', "dumpfile=$schema.DMP", "logfile=$($schema)_imp.log")
    Start-Process -FilePath "$($Software.OracleBase)\product\21c\dbhomeXE\bin\impdp.exe" -ArgumentList $argumentList -Wait
}

#>


<# Remove XE:

$cimSession = New-CimSession -ComputerName $softwareOracleXe.ComputerName
Get-NetFirewallRule -CimSession $cimSession -Group 'Oracle' | Remove-NetFirewallRule
$cimSession | Remove-CimSession

$session = New-PSSession -ComputerName $softwareOracleXe.ComputerName -Credential $softwareOracleXe.Credential -Authentication Credssp

if (-not (Invoke-Command -Session $session -ScriptBlock { Test-Path -Path $using:softwareOracleXe.TempPath })) {
    Invoke-Command -Session $session -ScriptBlock { Expand-Archive -Path $using:softwareOracleXe.ZipFile -DestinationPath $using:softwareOracleXe.TempPath }
}

$argumentList = @(
    '/s'
    '/x'
    '/v"/qn"'  # Not needed at install, but needed here to suppress questions
    '/v"/L*v {0}\setup.log"' -f $softwareOracleXe.TempPath
)
$result = Invoke-Program -Session $session -FilePath "$($softwareOracleXe.TempPath)\setup.exe" -ArgumentList $argumentList
# TODO: Why does this fail? 

$session | Remove-PSSession


# Old version:

Invoke-Command -ComputerName $softwareOracleXe.ComputerName -Authentication Credssp -Credential $softwareOracleXe.Credential -ArgumentList $softwareOracleXe -ScriptBlock { 
    param($Software)
    if (-not (Test-Path -Path $Software.TempPath)) {
        Expand-Archive -Path $Software.ZipFile -DestinationPath $Software.TempPath
    }
    $argumentList = "/s /x /v`"/qn /Lv $($Software.TempPath)\setup.log`""
    Start-Process -FilePath "$($Software.TempPath)\setup.exe" -ArgumentList $argumentList -Wait
    Remove-Item -Path $Software.OracleBase -Recurse -Force
    Remove-Item -Path $Software.TempPath -Recurse -Force
    Get-NetFirewallRule -Group Oracle | Remove-NetFirewallRule
}

Restart-Computer -ComputerName $softwareOracleXe.ComputerName

#>
