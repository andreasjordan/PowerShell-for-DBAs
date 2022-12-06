$ErrorActionPreference = 'Stop'

$logPath = '~/ITTage.log'

try {
    $null = New-Item -Path ~/ITTage -ItemType Directory

    Invoke-WebRequest -Uri https://github.com/andreasjordan/PowerShell-for-DBAs/archive/refs/heads/main.zip -OutFile ~/ITTage/main.zip -UseBasicParsing
    Expand-Archive -Path ~/ITTage/main.zip -DestinationPath ~/ITTage
    Rename-Item ~/ITTage/PowerShell-for-DBAs-main -NewName PowerShell-for-DBAs
    Remove-Item ~/ITTage/main.zip

    $null = New-Item -Path ~/ITTage/NuGet -ItemType Directory
    foreach ($package in 'Oracle.ManagedDataAccess', 'Oracle.ManagedDataAccess.Core', 'MySql.Data', 'Npgsql', 'Microsoft.Extensions.Logging.Abstractions') {
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile ~/ITTage/NuGet/package.zip -UseBasicParsing
        Expand-Archive -Path ~/ITTage/NuGet/package.zip -DestinationPath ~/ITTage/NuGet/$package
        Remove-Item -Path ~/ITTage/NuGet/package.zip
    }
} catch {
    $message = "Setting up files for IT-Tage 2022 failed: $_"
    $message | Add-Content -Path $logPath
    Write-Warning -Message $message
}
