$ErrorActionPreference = 'Stop'

$logPath = "$Env:USERPROFILE/ITTage.log"

try {
    $null = New-Item -Path C:\ITTage -ItemType Directory

    Invoke-WebRequest -Uri https://github.com/andreasjordan/PowerShell-for-DBAs/archive/refs/heads/main.zip -OutFile C:\ITTage\main.zip -UseBasicParsing
    Expand-Archive -Path C:\ITTage\main.zip -DestinationPath C:\ITTage
    Rename-Item C:\ITTage\PowerShell-for-DBAs-main -NewName PowerShell-for-DBAs
    Remove-Item C:\ITTage\main.zip

    $null = New-Item -Path C:\ITTage\NuGet -ItemType Directory
    foreach ($package in 'Oracle.ManagedDataAccess', 'Oracle.ManagedDataAccess.Core', 'MySql.Data', 'Npgsql', 'Microsoft.Extensions.Logging.Abstractions') {
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile C:\ITTage\NuGet\package.zip -UseBasicParsing
        Expand-Archive -Path C:\ITTage\NuGet\package.zip -DestinationPath C:\ITTage\NuGet\$package
        Remove-Item -Path C:\ITTage\NuGet\package.zip
    }
} catch {
    $message = "Setting up files for IT-Tage 2022 failed: $_"
    $message | Add-Content -Path $logPath
    Write-Warning -Message $message
}
