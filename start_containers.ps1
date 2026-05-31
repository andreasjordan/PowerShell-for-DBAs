#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

# Start docker service
$null = service docker start

# Get list of container
$container = docker container ls -a --format '{{json .}}' | ConvertFrom-Json

# Select container to start
$startContainer = $container | Select-Object -Property Names, State, Image | Out-ConsoleGridView -Title 'Select container to start'

# Start the selected container
$startContainer | ForEach-Object -Process { 
    $null = docker start $_.Names
}
