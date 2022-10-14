$ErrorActionPreference = 'Stop'

$nuGetPath = '~\NuGet'

if (-not (Test-Path -Path $nuGetPath)) {
    $null = New-Item -Path $nuGetPath -ItemType Directory
}

foreach ($package in 'Oracle.ManagedDataAccess', 'Oracle.ManagedDataAccess.Core', 'MySql.Data', 'Npgsql', 'Net.IBM.Data.Db2', 'IBM.Data.DB2.Core') {
    if (-not (Test-Path -Path $nuGetPath\$package)) {
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/$package -OutFile package.zip -UseBasicParsing
        Expand-Archive -Path package.zip -DestinationPath $nuGetPath\$package
        Remove-Item -Path package.zip
    }
}

