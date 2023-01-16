How to use PowerShell as a Microsoft SQL Server database administrator.

If you are missing some files, please download the 2023-01 release of this repository to find them.

## Install the server

You can use any existing server in your environment. If you want to setup a server just for tests, you find some recommendations in this section.

### Windows

You can use the free express edition of SQL Server. You will find further details in the 2023-01 release of this repository.

### Docker

I use the image [mcr.microsoft.com/mssql/server:2019-latest](https://hub.docker.com/_/microsoft-mssql-server) for my labs. See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


## Install the client

### System.Data.SqlClient

As PowerShell and Windows are both from Microsoft: The client is just nativly build into PowerShell. If you want to use the namespace System.Data.SqlClient, there is nothing that you need to do.

See [Connect-SqlInstance.ps1](Connect-SqlInstance.ps1), [Invoke-SqlQuery.ps1](Invoke-SqlQuery.ps1) and [Application.ps1](Application.ps1) on how to use this client.


### PowerShell module dbatools

https://dbatools.io/

https://github.com/dataplat/dbatools

This open source PowerShell module is a complete solution for managing Microsoft SQL Servers with PowerShell. And to be honest: The functionality of dbatools inspired me to create this repository.

For details on installing dbatools see my blog posts ["How to install the PowerShell module dbatools?"](https://blog.ordix.de/how-do-i-install-the-powershell-module-dbatools) and ["Installation and use of dbatools on a computer without internet connection"](https://blog.ordix.de/installation-and-use-of-dbatools-on-a-computer-without-internet-connection).

In general, Microsoft goes one step further than the other vendors. They publish a collection of objects (DLLs) that are designed for programming all aspects of managing Microsoft SQL Server: [Server Managed Objects (SMO)](https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo).
They give you a .NET interface to all layers within SQL Servers, such as the instances themselves, all logins, databases, tables, indexes, etc.
Best of all, it's now open source, you can take a look at the code here on [GitHub](https://github.com/microsoft/sqlmanagementobjects).

You will find further details in the 2023-01 release of this repository.


### PowerShell module SqlServer

https://www.powershellgallery.com/packages/SqlServer

https://docs.microsoft.com/en-us/powershell/module/sqlserver

This is the official PowerShell module by Microsoft and has a command [Invoke-Sqlcmd](https://docs.microsoft.com/en-us/powershell/module/sqlserver/invoke-sqlcmd) that can be used to execute a query.


### NuGet package Microsoft.Data.SqlClient

https://www.nuget.org/packages/Microsoft.SqlServer.SqlManagementObjects

This is the new version of the SQL Client from Microsoft and I definitly want to try that - but there are some dependencies. And I still have not enough knowledge about installing NuGet packages with dependencies.

But dbatools include all the needed DLLs and they can be loaded without loading the module itself.

You will find further details in the 2023-01 release of this repository.


### Devart dotConnect for SQL Server 4.0 Standard

https://www.devart.com/dotconnect/sqlserver/

This free version might also be an option, but is for Windows only.


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
