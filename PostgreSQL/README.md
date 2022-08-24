How to use PowerShell as a PostgreSQL database administrator.

## Server

See [Server.ps1](Server.ps1).


## Client

### Npgsql

https://github.com/npgsql/npgsql

https://www.nuget.org/packages/Npgsql

Looks good, but no DLL for Framework 4.5


### dotConnect for PostgreSQL 8.0 Express

https://www.devart.com/dotconnect/postgresql/download.html

https://www.devart.com/dotconnect/postgresql/docs/

Installation works, Add-Type as well.

```powershell
try {
    Add-Type -Path 'C:\Program Files (x86)\Devart\dotConnect\PostgreSQL\Devart.Data.PostgreSql.dll'
} catch {
    $ex = $_
    $ex.Exception.Message
    $ex.Exception.LoaderExceptions
}

$connection = [Devart.Data.PostgreSql.PgSqlConnection]::new()
$connection.Host = 'SQLLAB08'
$connection.Port = 5432
$connection.UserId = 'postgresql'
$connection.Password = 'start123'

$connection.Open()
```

Now my PostgreSQL server has to be configured...
