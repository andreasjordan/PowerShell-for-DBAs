$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues = @{ "*-Pg*:EnableException" = $true }

Add-Type -Path $Env:POSTGRESQL_DLL
. ..\..\Connect-PgInstance.ps1
. ..\..\Invoke-PgQuery.ps1

$connection = Connect-PgInstance -Instance localhost:5433 -Credential geodemo

$query = 'CREATE TABLE countries (name VARCHAR(50), iso CHAR(3), geometry GEOMETRY)' 
Invoke-PgQuery -Connection $connection -Query $query

$geoJSON = Invoke-RestMethod -Method Get -Uri https://datahub.io/core/geo-countries/r/0.geojson

foreach ($feature in $geoJSON.features) {
    $invokeParams = @{
        Connection      = $connection
        Query           = 'INSERT INTO countries VALUES (:name, :iso, ST_GeomFromGeoJSON(:geometry))'
        ParameterValues = @{
            name     = $feature.properties.name
            iso      = $feature.properties.'ISO3166-1-Alpha-3'
            geometry = $feature.geometry | ConvertTo-Json -Depth 4 -Compress 
        }
    }
    try {
        Invoke-PgQuery @invokeParams
    } catch {
        Write-Warning -Message "Failed to import $($feature.properties.name): $_"
    }
}
