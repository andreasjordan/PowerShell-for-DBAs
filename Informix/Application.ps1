param(
    [int]$MaxRowsPerTable
)
$ErrorActionPreference = 'Stop'

if (-not $Env:INFORMIX_DLL) {
    throw 'Environment variable INFORMIX_DLL not set'
}
if (-not (Test-Path -Path $Env:INFORMIX_DLL)) {
    throw "Environment variable INFORMIX_DLL not set correctly, file [$Env:INFORMIX_DLL] not found"
}
if ($Env:INFORMIX_DLL -match 'IBM\.Data\.Db2\.dll') {
    # For NuGet package on Windows: Change $Env:PATH
    if ($Env:INFORMIX_DLL -match 'lib\\net6\.0\\IBM\.Data\.Db2\.dll') {
        $path = $Env:INFORMIX_DLL -replace 'lib\\net6\.0\\IBM\.Data\.Db2\.dll', 'buildTransitive\clidriver\bin'
        $Env:PATH = "$Env:PATH;$path"
    }

    try { Add-Type -Path $Env:INFORMIX_DLL } catch { }

    . .\Connect-IfxInstance_Db2.ps1
    . .\Invoke-IfxQuery_Db2.ps1
} elseif ($Env:INFORMIX_DLL -match 'IBM\.Data\.DB2\.Core\.dll') {
    # For NuGet package on Windows: Change $Env:PATH
    if ($Env:INFORMIX_DLL -match 'lib\\netstandard2\.1\\IBM\.Data\.DB2\.Core\.dll') {
        $path = $Env:INFORMIX_DLL -replace 'lib\\netstandard2\.1\\IBM\.Data\.DB2\.Core\.dll', 'buildTransitive\clidriver\bin'
        $Env:PATH = "$Env:PATH;$path"
    }

    Add-Type -Path $Env:INFORMIX_DLL

    . .\Connect-IfxInstance_Db2_Core.ps1
    . .\Invoke-IfxQuery_Db2_Core.ps1
} elseif ($Env:INFORMIX_DLL -match 'Informix\.Net\.Core\.dll') {
    Add-Type -Path $Env:INFORMIX_DLL

    . .\Connect-IfxInstance_Core.ps1
    . .\Invoke-IfxQuery_Core.ps1
} else {
    Add-Type -Path $Env:INFORMIX_DLL

    . .\Connect-IfxInstance.ps1
    . .\Invoke-IfxQuery.ps1
}
if (-not $Env:INFORMIX_INSTANCE) {
    throw 'Environment variable INFORMIX_INSTANCE not set'
}
if (-not $Env:INFORMIX_DATABASE) {
    throw 'Environment variable INFORMIX_DATABASE not set'
}
if (-not $Env:INFORMIX_USERNAME) {
    throw 'Environment variable INFORMIX_USERNAME not set'
}
if (-not $Env:INFORMIX_PASSWORD) {
    $credential = Get-Credential -Message $Env:INFORMIX_INSTANCE -UserName $Env:INFORMIX_USERNAME
} else {
    $credential = [PSCredential]::new($Env:INFORMIX_USERNAME, (ConvertTo-SecureString -String $Env:INFORMIX_PASSWORD -AsPlainText -Force))
}

. ..\PowerShell\Import-Schema.ps1
. ..\PowerShell\Import-Data.ps1

try {
    $connection = Connect-IfxInstance -Instance $Env:INFORMIX_INSTANCE -Credential $credential -Database $Env:INFORMIX_DATABASE -EnableException

    $tables = Invoke-IfxQuery -Connection $connection -Query "SELECT tabname FROM systables WHERE owner = USER" -As SingleValue -EnableException
    foreach ($table in $tables) {
        Invoke-IfxQuery -Connection $connection -Query "DROP TABLE $table" -EnableException
    }

    Import-Schema -Path ..\PowerShell\SampleSchema.psd1 -DBMS Informix -Connection $connection -EnableException
    $start = Get-Date
    Import-Data -Path ..\PowerShell\SampleData.json -DBMS Informix -Connection $connection -MaxRowsPerTable $MaxRowsPerTable -EnableException
    $duration = (Get-Date) - $start

    $connection.Dispose()
    
    Write-Host "Data import to $Env:INFORMIX_INSTANCE finished in $($duration.TotalSeconds) seconds"
} catch {
    Write-Host "Data import to $Env:INFORMIX_INSTANCE failed: $_"
}
