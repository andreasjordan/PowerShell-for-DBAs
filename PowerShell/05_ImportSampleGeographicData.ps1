[CmdletBinding()]
param (
    [String]$DatabaseDefinitionFile = '/tmp/tmp_DatabaseDefinition.json',
    [String]$DataUri = 'https://datahub.io/core/geo-countries/r/0.geojson'
)

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework

$DatabaseDefinition = Get-Content -Path $DatabaseDefinitionFile | ConvertFrom-Json

# Load geographic data
$geoJSON = Invoke-RestMethod -Method Get -Uri $DataUri

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'Oracle'
if ($dbDef) {
    try {
        $start = Get-Date
        . $PSScriptRoot\..\Oracle\Import-OraLibrary.ps1
        . $PSScriptRoot\..\Oracle\Connect-OraInstance.ps1
        . $PSScriptRoot\..\Oracle\Invoke-OraQuery.ps1
        Import-OraLibrary -EnableException
        $credential = [PSCredential]::new('geodemo', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-OraInstance -Instance $dbDef.Instance -Credential $credential -EnableException
        foreach ($feature in $geoJSON.features) {
            $invokeParams = @{
                Connection      = $connection
                Query           = 'INSERT INTO countries VALUES (:name, :iso, sdo_util.from_geojson(:geometry))'
                ParameterValues = @{
                    name     = $feature.properties.ADMIN
                    iso      = $feature.properties.ISO_A3
                    geometry = ($feature.geometry | ConvertTo-Json -Depth 4 -Compress) -replace '\.(\d{10})\d+', '.$1'
                }
                EnableException = $true
            }
            try {
                Invoke-OraQuery @invokeParams
            } catch {
                Write-PSFMessage -Level Warning -Message "Failed to import $($feature.properties.ADMIN): $_"
            }
        }
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Importing sample geographic data to Oracle finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Importing sample geographic data to Oracle failed: $_"
    }
}

$dbDef = $DatabaseDefinition | Where-Object ContainerName -eq 'PostGIS'
if ($dbDef) {
    try {
        $start = Get-Date
        . $PSScriptRoot\..\PostgreSQL\Import-PgLibrary.ps1
        . $PSScriptRoot\..\PostgreSQL\Connect-PgInstance.ps1
        . $PSScriptRoot\..\PostgreSQL\Invoke-PgQuery.ps1
        Import-PgLibrary -EnableException
        $credential = [PSCredential]::new('geodemo', (ConvertTo-SecureString -String $dbDef.AdminPassword -AsPlainText -Force))
        $connection = Connect-PgInstance -Instance $dbDef.Instance -Credential $credential -Database geodemo
        foreach ($feature in $geoJSON.features) {
            $invokeParams = @{
                Connection      = $connection
                Query           = 'INSERT INTO countries VALUES (:name, :iso, ST_GeomFromGeoJSON(:geometry))'
                ParameterValues = @{
                    name     = $feature.properties.ADMIN
                    iso      = $feature.properties.ISO_A3
                    geometry = $feature.geometry | ConvertTo-Json -Depth 4 -Compress 
                }
                EnableException = $true
            }
            try {
                Invoke-PgQuery @invokeParams
            } catch {
                Write-PSFMessage -Level Warning -Message "Failed to import $($feature.properties.ADMIN): $_"
            }
        }
        $duration = (Get-Date) - $start
        Write-PSFMessage -Level Host -Message "Importing sample geographic data to PostGIS finished in $($duration.TotalSeconds) seconds"
    } catch {
        Write-PSFMessage -Level Warning -Message "Importing sample geographic data to PostGIS failed: $_"
    }
}
