$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues = @{ "*-Ora*:EnableException" = $true }

Add-Type -Path $Env:ORACLE_DLL
. ..\..\Connect-OraInstance.ps1
. ..\..\Invoke-OraQuery.ps1

$connection = Connect-OraInstance -Instance localhost/XEPDB1 -Credential geodemo

$query = 'CREATE TABLE countries (name VARCHAR2(50), iso CHAR(3), geometry SDO_GEOMETRY)' 
Invoke-OraQuery -Connection $connection -Query $query

$geoJSON = Invoke-RestMethod -Method Get -Uri https://datahub.io/core/geo-countries/r/0.geojson

foreach ($feature in $geoJSON.features) {
    $invokeParams = @{
        Connection      = $connection
        Query           = 'INSERT INTO countries VALUES (:name, :iso, sdo_util.from_geojson(:geometry))'
        ParameterValues = @{
            name     = $feature.properties.ADMIN
            iso      = $feature.properties.ISO_A3
            geometry = ($feature.geometry | ConvertTo-Json -Depth 4 -Compress) -replace '\.(\d{10})\d+', '.$1'
        }
    }
    try {
        Invoke-OraQuery @invokeParams
    } catch {
        Write-Warning -Message "Failed to import $($feature.properties.ADMIN): $_"
    }
}

<#
Some info on why I have to limit the number of decimal places in line 22:
https://community.oracle.com/tech/developers/discussion/comment/16859191
#>
