How to use PowerShell as a PostgreSQL database administrator.

## Install the server

I use the windows installer by [EDB](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads) of PostgreSQL 14.5 for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details on how to run an unattended installation from a remote computer.

But you can use any existing server in your environment. Just be sure to be able to connect from your client. In my lab, I add "host all all samenet scram-sha-256" to the file "pg_hba.conf".


## Install the client

### dotConnect for PostgreSQL 8.0 Express

I use the free Express edition of dotConnect by DevArt in my lab, as this is an easy to install client. See my install script [Client.ps1](Client.ps1) in this folder for details on how to run an unattended installation.

https://www.devart.com/dotconnect/postgresql/download.html

https://www.devart.com/dotconnect/postgresql/docs/


### Npgsql

Looks good, but no DLL for Framework 4.5 - so will try that later...

https://github.com/npgsql/npgsql

https://www.nuget.org/packages/Npgsql


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.


## Run some code

First sample code (using [Connect-PgInstance.ps1](Connect-PgInstance.ps1) and [Invoke-PgQuery.ps1](Invoke-PgQuery.ps1)):

```powershell
try {
    Add-Type -Path 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'
} catch {
    $ex = $_
    $ex.Exception.Message
    $ex.Exception.LoaderExceptions
}

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
