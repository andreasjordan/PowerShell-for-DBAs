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
        ContainerImage    = 'mcr.microsoft.com/mssql/server:2022-latest'
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
        ContainerImage    = 'container-registry.oracle.com/database/express:latest'
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
        ContainerImage    = 'mysql:latest'
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
        ContainerImage    = 'mariadb:latest'
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
        ContainerImage    = 'postgres:latest'
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
        ContainerImage    = 'postgis/postgis'
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
    $DatabaseDefinition = $DatabaseDefinition | Out-ConsoleGridView -Title 'Select docker conatiners to start'
}

$DatabaseDefinition | ConvertTo-Json | Set-Content -Path /tmp/tmp_DatabaseDefinition.json

Write-PSFMessage -Level Host -Message 'OK'
