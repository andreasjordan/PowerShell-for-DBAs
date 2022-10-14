[CmdletBinding()]
param (
    [switch]$All,
    [ValidateSet("SMO", "dbatools")][string[]]$SQLServer,
    [ValidateSet("NuGet", "client")][string[]]$Oracle,
    [ValidateSet("NuGet")][string[]]$MySQL,
    [ValidateSet("NuGet")][string[]]$MariaDB,
    [ValidateSet("NuGet")][string[]]$PostgreSQL,
    [ValidateSet("NuGet")][string[]]$Db2,
    [ValidateSet("NuGet1", "NuGet2")][string[]]$Informix,
    [int]$MaxRowsPerTable
)

$ErrorActionPreference = 'Stop'

$nuGetPath = '~\NuGet'

if ($all -or $SQLServer -contains 'SMO') {
    $Env:SQLSERVER_INSTANCE = 'MULTIDB'
    $Env:SQLSERVER_DATABASE = 'StackOverflow'
    $Env:SQLSERVER_USERNAME = 'StackOverflow'
    $Env:SQLSERVER_PASSWORD = 'start456'

    Push-Location -Path ..\SQLServer
    .\Application.ps1 -MaxRowsPerTable $MaxRowsPerTable
    Pop-Location
}

if ($all -or $SQLServer -contains 'dbatools') {
    $Env:SQLSERVER_INSTANCE = 'MULTIDB'
    $Env:SQLSERVER_DATABASE = 'StackOverflow'
    $Env:SQLSERVER_USERNAME = 'StackOverflow'
    $Env:SQLSERVER_PASSWORD = 'start456'

    Push-Location -Path ..\SQLServer
    .\Application_dbatools.ps1 -MaxRowsPerTable $MaxRowsPerTable
    Pop-Location
}

if ($all -or $Oracle -contains 'NuGet') {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        $Env:ORACLE_DLL = "$nuGetPath\Oracle.ManagedDataAccess\lib\net462\Oracle.ManagedDataAccess.dll"
    } else {
        $Env:ORACLE_DLL = "$nuGetPath\Oracle.ManagedDataAccess.Core\lib\netstandard2.1\Oracle.ManagedDataAccess.dll"
    }

    $Env:ORACLE_INSTANCE = 'MULTIDB/XEPDB1'
    $Env:ORACLE_USERNAME = 'stackoverflow'
    $Env:ORACLE_PASSWORD = 'start456'

    Push-Location -Path ..\Oracle
    .\Application.ps1 -MaxRowsPerTable $MaxRowsPerTable
    Pop-Location
}

if ($all -or $MySQL -contains 'NuGet') {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        $Env:MYSQL_DLL = "$nuGetPath\MySql.Data\lib\net452\MySql.Data.dll"
    } else {
        $Env:MYSQL_DLL = "$nuGetPath\MySql.Data\lib\net6.0\MySql.Data.dll"
    }

    $Env:MYSQL_INSTANCE = 'MULTIDB'
    $Env:MYSQL_DATABASE = 'stackoverflow'
    $Env:MYSQL_USERNAME = 'stackoverflow'
    $Env:MYSQL_PASSWORD = 'start456'
    
    Push-Location -Path ..\MySQL
    .\Application.ps1 -MaxRowsPerTable $MaxRowsPerTable
    Pop-Location
}

if ($all -or $MariaDB -contains 'NuGet') {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        $Env:MYSQL_DLL = "$nuGetPath\MySql.Data\lib\net452\MySql.Data.dll"
    } else {
        $Env:MYSQL_DLL = "$nuGetPath\MySql.Data\lib\net6.0\MySql.Data.dll"
    }

    $Env:MYSQL_INSTANCE = 'MULTIDB:3307'
    $Env:MYSQL_DATABASE = 'stackoverflow'
    $Env:MYSQL_USERNAME = 'stackoverflow'
    $Env:MYSQL_PASSWORD = 'start456'
    
    Push-Location -Path ..\MySQL
    .\Application.ps1 -MaxRowsPerTable $MaxRowsPerTable
    Pop-Location
}

if ($all -or $PostgreSQL -contains 'NuGet') {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Write-Warning -Message "There is no NuGet package for PowerShell 5.1"
    } else {
        $Env:POSTGRESQL_DLL = "$nuGetPath\Npgsql\lib\net6.0\Npgsql.dll"

        $Env:POSTGRESQL_INSTANCE = 'MULTIDB'
        $Env:POSTGRESQL_DATABASE = 'stackoverflow'
        $Env:POSTGRESQL_USERNAME = 'stackoverflow'
        $Env:POSTGRESQL_PASSWORD = 'start456'
        
        Push-Location -Path ..\PostgreSQL
        .\Application.ps1 -MaxRowsPerTable $MaxRowsPerTable
        Pop-Location
    }
}

if ($all -or $Db2 -contains 'NuGet') {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Write-Warning -Message "There is no NuGet package for PowerShell 5.1"
    } else {
        $Env:CLIENT_LOCALE = 'en_US.utf8'
        $Env:PATH = 

        $Env:MYSQL_DLL = "$nuGetPath\Net.IBM.Data.Db2\lib\net6.0\IBM.Data.Db2.dll"

        $Env:DB2_INSTANCE = 'MULTIDB:50000'
        $Env:DB2_DATABASE = 'DEMO'
        $Env:DB2_USERNAME = 'stackoverflow'
        $Env:DB2_PASSWORD = 'start456'
            
        Push-Location -Path ..\Db2
        .\Application.ps1 -MaxRowsPerTable $MaxRowsPerTable
        Pop-Location
    }
}

if ($all -or $Informix -contains 'NuGet1') {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Write-Warning -Message "There is no NuGet package for PowerShell 5.1"
    } else {
        $Env:MYSQL_DLL = "$nuGetPath\Net.IBM.Data.Db2\lib\net6.0\IBM.Data.Db2.dll"

        $Env:INFORMIX_INSTANCE = 'MULTIDB:9089'
        $Env:INFORMIX_DATABASE = 'stackoverflow'
        $Env:INFORMIX_USERNAME = 'stackoverflow'
        $Env:INFORMIX_PASSWORD = 'start456'
                    
        Push-Location -Path ..\Informix
        .\Application.ps1 -MaxRowsPerTable $MaxRowsPerTable
        Pop-Location
    }
}

if ($all -or $Informix -contains 'NuGet2') {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Write-Warning -Message "There is no NuGet package for PowerShell 5.1"
    } else {
        $Env:MYSQL_DLL = "$nuGetPath\IBM.Data.DB2.Core\lib\netstandard2.1\IBM.Data.DB2.Core.dll"

        $Env:INFORMIX_INSTANCE = 'MULTIDB:9089'
        $Env:INFORMIX_DATABASE = 'stackoverflow'
        $Env:INFORMIX_USERNAME = 'stackoverflow'
        $Env:INFORMIX_PASSWORD = 'start456'

        Push-Location -Path ..\Informix
        .\Application.ps1 -MaxRowsPerTable $MaxRowsPerTable
        Pop-Location
    }
}
