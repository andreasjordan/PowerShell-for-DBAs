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
            geometry = $feature.geometry | ConvertTo-Json -Depth 4
        }
    }
    try {
        Invoke-OraQuery @invokeParams
    } catch {
        # When using NuGet package Oracle.ManagedDataAccess.Core, Kazakhstan failed to import with "ORA-40441: JSON syntax error".
        Write-Warning -Message "Failed to import $($feature.properties.ADMIN): $_"
    }
}

<#
Some info on why I don't use -Compress with ConvertTo-Json in line 22:
ConvertFrom-Json (which is used by Invoke-RestMethod) works different on PowerShell 5.1 and 7.3. 
It returns Decimal on 5.1 and Double on 7.3 - so on PowerShell 7.3 some values are rounded.
I still don't know why exactly, but with the rounded values, the data for Kazakhstan produces an "invalid" (only for Oracle invalid) string when -Compress is used. 
But if I send an uncompressed JSON string to Oracle, everything works with the rounded values on PowerShell 7.3
See also: https://community.oracle.com/tech/developers/discussion/comment/16859191
#>
