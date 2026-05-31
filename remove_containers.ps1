#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

# Get list of container
$container = docker container ls -a --format '{{json .}}' | ConvertFrom-Json

# Select container to remove
$removeContainer = $container | Select-Object -Property Names, State, Image | Out-ConsoleGridView -Title 'Select container to remove'

# Remove the selected container
$removeContainer | ForEach-Object -Process { 
    $null = docker rm -f $_.Names
}
