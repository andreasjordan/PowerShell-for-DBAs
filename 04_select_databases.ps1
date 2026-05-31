#!/usr/bin/pwsh

Param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ContainerName
)

$ErrorActionPreference = 'Stop'

Import-Module -Name PSFramework
Import-Module -Name Microsoft.PowerShell.ConsoleGuiTools

$password = 'Passw0rd!'
$hostname = 'localhost'

<# The content of $DatabaseDefinition is the same as in the setup via AutomatedLab. #>

$DatabaseDefinition = @(
    [PSCustomObject]@{
        ContainerName     = 'SQLServer'
        # To find latest SQL Server images, see https://mcr.microsoft.com/en-us/artifact/mar/mssql/server
        ContainerImage    = 'mcr.microsoft.com/mssql/server:2025-CU5-ubuntu-24.04'
        ContainerMemoryGB = 2
        ContainerConfig   = "-p 1433:1433 -e MSSQL_SA_PASSWORD='$password' -e ACCEPT_EULA=Y -e MSSQL_PID=Express"
        Instance          = $hostname
        AdminPassword     = $password
        SqlQueries        = @(
            "CREATE LOGIN StackOverflow WITH PASSWORD = '$password', CHECK_POLICY = OFF"
            'CREATE DATABASE StackOverflow'
            'ALTER AUTHORIZATION ON DATABASE::StackOverflow TO StackOverflow'
        )
    }
    [PSCustomObject]@{
        ContainerName     = 'Oracle'
        # To find latest Oracle images, see https://container-registry.oracle.com/ords/ocr/ba/database/express
        # From the website: 
        # The Oracle XE Database server Docker image contains Oracle Database Express Edition Release 21c (21.3.0.0) running on Oracle Linux 7. 
        # This image contains a default database in a multitenant configuration with one pluggable database.
        ContainerImage    = 'container-registry.oracle.com/database/express:21.3.0-xe'
        ContainerMemoryGB = 3
        ContainerConfig   = "-p 1521:1521 -e ORACLE_PWD='$password' -e ORACLE_CHARACTERSET=AL32UTF8"
        Instance          = "$hostname/XEPDB1"
        AdminPassword     = $password
        SqlQueries        = @(
            'CREATE USER stackoverflow IDENTIFIED BY "{0}" DEFAULT TABLESPACE users QUOTA UNLIMITED ON users TEMPORARY TABLESPACE temp' -f $password
            'GRANT CREATE SESSION TO stackoverflow'
            'GRANT ALL PRIVILEGES TO stackoverflow'
            'CREATE USER geodemo IDENTIFIED BY "{0}" DEFAULT TABLESPACE users QUOTA UNLIMITED ON users TEMPORARY TABLESPACE temp' -f $password
            'GRANT CREATE SESSION TO geodemo'
            'GRANT ALL PRIVILEGES TO geodemo'
        )
    }
    [PSCustomObject]@{
        ContainerName     = 'MySQL'
        # To find latest MySQL images, see https://hub.docker.com/_/mysql
        ContainerImage    = 'mysql:9.7.0'
        ContainerMemoryGB = 1
        ContainerConfig   = "-p 3306:3306 -e MYSQL_ROOT_PASSWORD='$password'"
        Instance          = $hostname
        AdminPassword     = $password
        SqlQueries        = @(
            #'SET GLOBAL local_infile=1'
            'SET PERSIST local_infile=1'
            "CREATE USER 'stackoverflow'@'%' IDENTIFIED BY '$password'"
            'CREATE DATABASE stackoverflow'
            "GRANT ALL PRIVILEGES ON stackoverflow.* TO 'stackoverflow'@'%'"
        )
    }
    [PSCustomObject]@{
        ContainerName     = 'MariaDB'
        # To find latest MariaDB images, see https://hub.docker.com/_/mariadb
        ContainerImage    = 'mariadb:12.2.2'
        ContainerMemoryGB = 1
        ContainerConfig   = "-p 13306:3306 -e MARIADB_ROOT_PASSWORD='$password'"
        Instance          = "$($hostname):13306"
        AdminPassword     = $password
        SqlQueries        = @(
            "CREATE USER 'stackoverflow'@'%' IDENTIFIED BY '$password'"
            'CREATE DATABASE stackoverflow'
            "GRANT ALL PRIVILEGES ON stackoverflow.* TO 'stackoverflow'@'%'"
        )
    }
    [PSCustomObject]@{
        ContainerName     = 'PostgreSQL'
        # To find latest PostgreSQL images, see https://hub.docker.com/_/postgres
        ContainerImage    = 'postgres:18.4'
        ContainerMemoryGB = 1
        ContainerConfig   = "-p 5432:5432 -e POSTGRES_PASSWORD='$password'"
        Instance          = $hostname
        AdminPassword     = $password
        SqlQueries        = @(
            "CREATE USER stackoverflow WITH PASSWORD '$password'"
            'CREATE DATABASE stackoverflow WITH OWNER stackoverflow'
        )
    }
    [PSCustomObject]@{
        ContainerName     = 'PostGIS'
        # To find latest PostGIS images, see https://hub.docker.com/r/postgis/postgis
        ContainerImage    = 'postgis/postgis:18-3.6'
        ContainerMemoryGB = 1
        ContainerConfig   = "-p 15432:5432 -e POSTGRES_PASSWORD='$password'"
        Instance          = "$($hostname):15432"
        AdminPassword     = $password
        SqlQueries        = @(
            "CREATE USER geodemo WITH PASSWORD '$password'"
            'CREATE DATABASE geodemo WITH OWNER geodemo'
            '\connect geodemo'
            'CREATE EXTENSION postgis'
        )
    }
)

# $DatabaseDefinition = $DatabaseDefinition | Where-Object ContainerName -in SQLServer, Oracle
if ($ContainerName) {
    $DatabaseDefinition = $DatabaseDefinition | Where-Object ContainerName -in $ContainerName
} else {
    $DatabaseDefinition = $DatabaseDefinition | Out-ConsoleGridView -Title 'Select docker containers to create'
}

$DatabaseDefinition | ConvertTo-Json | Set-Content -Path /tmp/tmp_DatabaseDefinition.json

Write-PSFMessage -Level Host -Message 'OK'
