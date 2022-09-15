How to use PowerShell as a Microsoft SQL Server database administrator.

## Install the server

I use the free express edition of SQL Server 2019 for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details on how to run an unattended installation from a remote computer. The PowerShell module dbatools also has a command to run the installation.

But you can use any existing server in your environment.


## Install the client

We can use (nearly) the same sources and installation code on all the target environments:
* PowerShell 5.1 on Windows
* PowerShell 7.2 on Windows
* PowerShell 7.2 on Linux

### PowerShell module dbatools

https://dbatools.io/

https://github.com/dataplat/dbatools

This open source PowerShell module is a complete solution for managing Microsoft SQL Servers with PowerShell. And to be honest: The functionality of dbatools inspired me to create this repository.

For details on installing dbatools see my blog posts ["How to install the PowerShell module dbatools?"](https://blog.ordix.de/how-do-i-install-the-powershell-module-dbatools) and ["Installation and use of dbatools on a computer without internet connection"](https://blog.ordix.de/installation-and-use-of-dbatools-on-a-computer-without-internet-connection).

In general, Microsoft goes one step further than the other vendors. They publish a collection of objects (DLLs) that are designed for programming all aspects of managing Microsoft SQL Server: [Server Managed Objects (SMO)](https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo).
They give you a .NET interface to all layers within SQL Servers, such as the instances themselves, all logins, databases, tables, indexes, etc.
Best of all, it's now open source, you can take a look at the code here on [GitHub](https://github.com/microsoft/sqlmanagementobjects).


### PowerShell module SqlServer

https://www.powershellgallery.com/packages/SqlServer

https://docs.microsoft.com/en-us/powershell/module/sqlserver

This is the official PowerShell module by Microsoft and has a command [Invoke-Sqlcmd](https://docs.microsoft.com/en-us/powershell/module/sqlserver/invoke-sqlcmd) that can be used to execute a query.


### NuGet package Microsoft.SqlServer.SqlManagementObjects

https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/installing-smo

https://www.nuget.org/packages/Microsoft.SqlServer.SqlManagementObjects

I definitly want to try that - but there are dependencies like [Microsoft.Data.SqlClient](https://www.nuget.org/packages/Microsoft.Data.SqlClient/) which also has dependencies. And I still have not enough knowledge about installing NuGet packages with PowerShell.


### Devart dotConnect for SQL Server 4.0 Standard

https://www.devart.com/dotconnect/sqlserver/

This free version might also be an option, but is for Windows only.


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
