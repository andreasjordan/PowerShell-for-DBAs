How to use PowerShell as a PostgreSQL database administrator.

If you are missing some files, please download the 2023-01 release of this repository to find them.

## Install the server

You can use any existing server in your environment. If you want to setup a server just for tests, you find some recommendations in this section.

### Windows

You can use the windows installer by [EDB](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads) of PostgreSQL 14.5. You will find further details in the 2023-01 release of this repository.


### Docker

I use the image [postgres:latest](https://hub.docker.com/_/postgres) for my labs. See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


## Install the client

### Devart dotConnect for PostgreSQL 8.0 Express

You can use the free Express edition of dotConnect by DevArt, as this is an easy to install client. You will find further details in the 2023-01 release of this repository.

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

## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
