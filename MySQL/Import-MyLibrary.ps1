function Import-MyLibrary {
    [CmdletBinding()]
    param (
        [string[]]$Path = $PSScriptRoot,
        [switch]$EnableException
    )

    Write-Verbose -Message "Importing library from path: $($Path -join ', ')"

    $library = @(
        @{
            Package = 'MySqlConnector'
            LibPath = 'net9.0\MySqlConnector.dll'
        }
        @{
            Package = 'Microsoft.Extensions.Logging.Abstractions'
            LibPath = 'net9.0\Microsoft.Extensions.Logging.Abstractions.dll'
        }
    )

    try {
        if ($Path -match '\.dll$') {
            try {
                Add-Type -Path ($Path -match '\.dll$')
            } catch [System.Reflection.ReflectionTypeLoadException] {
                # Can be ignored
            }
        } else {
            foreach ($lib in $library) {
                $packagePath = "$($Path[0])\$($lib.Package)"
                if (-not (Test-Path -Path $packagePath)) {
                    Write-Verbose -Message "Nuget package '$($lib.Package)' has to be downloaded"
                    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/$($lib.Package)" -OutFile package.zip -UseBasicParsing
                    Expand-Archive -Path package.zip -DestinationPath $packagePath
                    Remove-Item -Path package.zip
                    Get-ChildItem -Path $packagePath -Exclude lib | Remove-Item -Recurse -Force
                }
                try {
                    Add-Type -Path "$packagePath\lib\$($lib.LibPath)"
                } catch [System.Reflection.ReflectionTypeLoadException] {
                    # Can be ignored
                }
            }
        }
    } catch {
        $message = "Import failed: $($_.Exception.Message)"
        if ($EnableException) {
            Write-Error -Message $message -TargetObject $Path -ErrorAction Stop
        } else {
            Write-Warning -Message $message
        }
    }
}
