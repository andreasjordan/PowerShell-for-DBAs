How to use PowerShell as a PostgreSQL database administrator.

## Install the server

You can use any existing server in your environment. If you want to setup a server just for tests, you find some recommendations in this section.

### Windows

I use the windows installer by [EDB](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads) of PostgreSQL 14.5 for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details on how to run an unattended installation from a remote computer.


### Docker

I use the image [postgres:latest](https://hub.docker.com/_/postgres) for my labs. See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


## Install the client

### Devart dotConnect for PostgreSQL 8.0 Express

I use the free Express edition of dotConnect by DevArt in my lab, as this is an easy to install client. See my install script [Client.ps1](Client.ps1) in this folder for details on how to run an unattended installation.

Works with PowerShell 5.1 and PowerShell 7.2 on Windows.

https://www.devart.com/dotconnect/postgresql/download.html

https://www.devart.com/dotconnect/postgresql/docs/


### NuGet package Npgsql

The [documentation](https://www.npgsql.org/doc/compatibility.html#net-frameworknet-coremono) says that the 4.x version is compatible with .NET Framework 4.6.1 and should work with PowerShell 5.1 - I could not get this working yet.

But for PowerShell 7.2 on Windows or Linux the latest version works.

https://github.com/npgsql/npgsql

https://www.nuget.org/packages/Npgsql

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Npgsql -OutFile npgsql.nupkg.zip -UseBasicParsing
Expand-Archive -Path npgsql.nupkg.zip -DestinationPath .\PostgreSQL
Remove-Item -Path npgsql.nupkg.zip
```

## Create an environment variable with the location of the dll

To be able to use the same scripts on all platforms and versions, I use an environment variable named "POSTGRESQL_DLL" with the complete path to the needed dll file.

I use local PowerShell profiles, but you can use other ways as well.

I use this code to create the profile if there is no profile:
```
if (!(Test-Path -Path $PROFILE)) { $null = New-Item -ItemType File -Path $PROFILE -Force }
```

I use this code for Npgsql:
```
"`$Env:POSTGRESQL_DLL = '$((Get-Location).Path)/lib/netstandard2.1/Npgsql.dll'" | Add-Content -Path $PROFILE
```

I use this code for the Devart client:
```
"`$Env:POSTGRESQL_DLL = 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'" | Add-Content -Path $PROFILE
```


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.


## Run some code

First sample code (using [Connect-PgInstance_Devart.ps1](Connect-PgInstance_Devart.ps1) and [Invoke-PgQuery_Devart.ps1](Invoke-PgQuery_Devart.ps1)):

```powershell
Add-Type -Path 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'

$instance = 'SQLLAB08:5432'
$instance = 'SQLLAB08'
$credential = Get-Credential -Message $instance -UserName postgres  # start123

$connection = Connect-PgInstance -Instance $instance -Credential $credential

$query = 'SELECT * FROM pg_file_settings'
$data = Invoke-PgQuery -Connection $connection -Query $query
$data | Out-GridView -Title $query

$query = 'SELECT setting FROM pg_file_settings WHERE name = :name'
$parameterValues = @{ name = 'port' }
$port = Invoke-PgQuery -Connection $connection -Query $query -ParameterValues $parameterValues -As SingleValue
"PostgreSQL is listening on port $port"
```
