#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

# Start docker service
$null = sudo service docker start

# Get list of container
$container = sudo docker container ls -a --format '{{json .}}' | ConvertFrom-Json

# Select container to stop
$stopContainer = $container | Select-Object -Property Names, State, Image | Out-ConsoleGridView -Title 'Select container to stop'

# Stop the selected container
$stopContainer | ForEach-Object -Process { 
    $null = sudo docker stop $_.Names
}
