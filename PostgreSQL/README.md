How to use PowerShell as a PostgreSQL database administrator.

## Server

See [Server.ps1](Server.ps1) which uses [Invoke-Program.ps1](../PowerShell/Invoke-Program.ps1).


## Client

### Npgsql

https://github.com/npgsql/npgsql

https://www.nuget.org/packages/Npgsql

Looks good, but no DLL for Framework 4.5


### dotConnect for PostgreSQL 8.0 Express

https://www.devart.com/dotconnect/postgresql/download.html

https://www.devart.com/dotconnect/postgresql/docs/

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

$connection = Connect-PgInstance -Instance $instance -Credential $credential -Verbose

$query = 'SELECT * FROM pg_file_settings'
$data = Invoke-PgQuery -Connection $connection -Query $query
$data | Out-GridView -Title $query

$query = 'SELECT setting FROM pg_file_settings WHERE name = :name'
$parameterValues = @{ name = 'port' }
$port = Invoke-PgQuery -Connection $connection -Query $query -ParameterValues $parameterValues -As SingleValue
"PostgreSQL is listening on port $port"
```
