$ErrorActionPreference = 'Stop'

<#

Documentation for silent installation:
https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinw/installing-oracle-database-xe.html#GUID-E6A7B665-134B-4EF3-AB78-A33A54908EB9

Page for manual download:
https://www.oracle.com/database/technologies/xe-downloads.html

#>

$softwareOracleXe = [PSCustomObject]@{
    DownloadUrl  = 'https://download.oracle.com/otn-pub/otn_software/db-express/OracleXE213_Win64.zip'
    ZipFile      = '\\fs\Software\Oracle\OracleXE213_Win64.zip'
    Sha256       = '939742c3305c466566a55f607638621b6aa7033a183175f6bcd6cffb48e6bc3f'
    TempPath     = 'C:\temp_OracleXE213_Win64'
    ComputerName = 'SQLLAB08'
    Credential   = Get-Credential -Message "Account to connect to target server with CredSSP" -UserName "$env:USERDOMAIN\$env:USERNAME"
    OracleBase   = 'D:\oracle'
    Password     = 'start123'  # TODO: Which special characters would work?`"P@ssw0rd" does not work.
    SampleSchema = '\\fs\SampleDatabases\STACKOVERFLOW.DMP.zip'
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

Invoke-Command -ComputerName $softwareOracleXe.ComputerName -Authentication Credssp -Credential $softwareOracleXe.Credential -ArgumentList $softwareOracleXe -ScriptBlock { 
    param($Software)
    if (-not (Test-Path -Path $Software.TempPath)) {
        Expand-Archive -Path $Software.ZipFile -DestinationPath $Software.TempPath
    }
    $rspContent = @{
        INSTALLDIR     = "$($Software.OracleBase)\product\21c\"
        PASSWORD       = $Software.Password
        LISTENER_PORT  = '1521'
        EMEXPRESS_PORT = '5550'
        CHAR_SET       = 'AL32UTF8'
        DB_DOMAIN      = ''
    }
    Set-Content -Path "$($Software.TempPath)\myInstall.rsp" -Value $rspContent.GetEnumerator().ForEach({ "$($_.Name)=$($_.Value)" })
    $argumentList = "/s /v`"RSP_FILE=$($Software.TempPath)\myInstall.rsp`" /v`"/L*v $($Software.TempPath)\setup.log`" /v`"/qn`""
    Start-Process -FilePath "$($Software.TempPath)\setup.exe" -ArgumentList $argumentList -Wait
}


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
    Program     = "$($softwareOracleXe.OracleBase)\product\21c\dbhomeXE\bin\oracle.exe"
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$firewallConfig = @{
    DisplayName = 'Oracle Listener'
    Name        = 'Oracle Listener'
    Group       = 'Oracle'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    Program     = "$($softwareOracleXe.OracleBase)\product\21c\dbhomeXE\bin\tnslsnr.exe"
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$cimSession | Remove-CimSession


# Remove temp folder

Invoke-Command -ComputerName $softwareOracleXe.ComputerName -Authentication Credssp -Credential $softwareOracleXe.Credential -ArgumentList $softwareOracleXe -ScriptBlock { 
    param($Software)
    Remove-Item -Path $Software.TempPath -Recurse -Force
}


# Install sample schema

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


<# Remove XE:

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

