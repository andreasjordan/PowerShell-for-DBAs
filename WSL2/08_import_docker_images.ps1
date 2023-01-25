#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework

$DatabaseDefinition = Get-Content -Path /tmp/tmp_DatabaseDefinition.json | ConvertFrom-Json

$baseImagePath = '/mnt/c/tmp/DockerImages'

Write-PSFMessage -Level Host -Message "Loading or pulling and saving docker images"

if (-not (Test-Path -Path $baseImagePath)) {
    Write-PSFMessage -Level Warning -Message "Path '$baseImagePath' not found. Please change this script and use an existing path as base path for saved docker images"
    exit 1
}

foreach ($db in $DatabaseDefinition) {
    $imagePath = "$baseImagePath/$($db.ContainerName).tar.gz"
    if (Test-Path -Path $imagePath) {
        Write-PSFMessage -Level Host -Message "Found saved image for $($db.ContainerName), will load image"
        Invoke-Expression "sudo docker load -i $imagePath"
    } else {
        Write-PSFMessage -Level Host -Message "No saved image found for $($db.ContainerName), will pull and save image"
        Invoke-Expression "sudo docker pull $($db.ContainerImage)"
        Invoke-Expression "sudo docker save -o $baseImagePath/$($db.ContainerName).tar $($db.ContainerImage)"
        Invoke-Expression "sudo gzip $baseImagePath/$($db.ContainerName).tar"
    }
}

Write-PSFMessage -Level Host -Message "OK"
