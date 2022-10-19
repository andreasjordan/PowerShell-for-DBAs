#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

# Start docker service
$null = sudo service docker start

# List of possible database systems
$dbms = @(
    'SQLServer'
    'Oracle'
    'MySQL'
    'MariaDB'
    'PostgreSQL'
    'Db2'
    'Informix'
)

# Select database systems to build
$buildDbms = $dbms | Out-ConsoleGridView -Title 'Select database systems to build'

# Build the selected database systems
if ($buildDbms) {
    $Env:USE_SUDO = 'YES'
    Set-Location -Path ~/GitHub/PowerShell-for-DBAs/PowerShell
    ./SetupServerWithDocker.ps1 -DBMS $buildDbms
}
