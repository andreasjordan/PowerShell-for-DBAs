#!/usr/bin/pwsh

$ErrorActionPreference = 'Stop'

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name PSFramework
Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools

Import-Module -Name PSFramework

Write-PSFMessage -Level Host -Message 'OK'
