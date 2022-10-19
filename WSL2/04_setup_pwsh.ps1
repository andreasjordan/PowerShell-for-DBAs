#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

# The script will install these PowerShell modules:
$modules = @(
    'Microsoft.PowerShell.ConsoleGuiTools'
    'PSFramework'
    'dbatools'
)

# The script will download these NuGet packages:
$packages = @(
    'Oracle.ManagedDataAccess.Core'
    'MySql.Data'
    'Npgsql'
    'Net.IBM.Data.Db2-lnx'
    'IBM.Data.DB2.Core-lnx'
)

try {
    # Trust the PSGallery
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    # Install my favorite PowerShell modules
    foreach ($module in $modules) {
        Install-Module -Name $module
    }

    # Download my favorite NuGet packages
    $null = New-Item -Path ~/NuGet -ItemType Directory
    foreach ($package in $packages) {
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile /tmp/package.zip -UseBasicParsing
        Expand-Archive -Path /tmp/package.zip -DestinationPath ~/NuGet/$package
        Remove-Item -Path /tmp/package.zip
    }

    Write-Host 'OK'
} catch {
    Write-Warning "Failure: $_"
}
