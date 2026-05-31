#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework

$DatabaseDefinition = Get-Content -Path /tmp/tmp_DatabaseDefinition.json | ConvertFrom-Json

Write-PSFMessage -Level Host -Message "Creating database containers on docker"

foreach ($db in $DatabaseDefinition) {
    # $db = $DatabaseDefinition[0]
    Write-PSFMessage -Level Host -Message "Creating docker container $($db.ContainerName)"
    $null = Invoke-Expression "docker run --name $($db.ContainerName) --memory=$($db.ContainerMemoryGB)g $($db.ContainerConfig) --detach --restart always $($db.ContainerImage)"
}

Write-PSFMessage -Level Host -Message "OK"
