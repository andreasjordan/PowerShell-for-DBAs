#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

Set-Location -Path ~/GitHub/PowerShell-for-DBAs/PowerShell

try {
    if (-not (Test-Path -Path ~/Software)) {
        $null = New-Item -Path ~/Software -ItemType Directory
    }
    $Env:USE_SUDO = 'YES'
    ./SetupServerWithDocker.ps1 -StopContainer
    
    Write-Host 'OK'
} catch {
    Write-Warning "Failure: $_"
}
