$ErrorActionPreference = 'Stop'

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Invoke-Program.ps1

<#

Documentation:
https://www.devart.com/dotconnect/postgresql/docs/

#>

# Install client

$programParams = @{
    FilePath     = "$EnvironmentSoftwareBase\PostgreSQL\dcpostgresqlfree.exe"
    ArgumentList = @( '/TYPE=COMPACT', '/VERYSILENT', '/NOICONS')
}
$result = Invoke-Program @programParams


# Test installation

if (-not $result.Successful) {
    $result
    throw "Installation failed"
}


<# Uninstall:

$programParams = @{
    FilePath     = 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Uninstall\unins000.exe'
    ArgumentList = @( '/VERYSILENT', '/NOFEEDBACK' )
}
$result = Invoke-Program @programParams

#>
