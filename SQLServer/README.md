How to use PowerShell as a Microsoft SQL Server database administrator.

If you are looking for a complete solution for managing Microsoft SQL Servers with PowerShell, then you should take a look at [dbatools](https://dbatools.io/) ([GitHub](https://github.com/dataplat/dbatools)). 

In general, Microsoft goes one step further than the other vendors. They publish a collection of objects (DLLs) that are designed for programming all aspects of managing Microsoft SQL Server: [Server Managed Objects (SMO)](https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo).
They give you a .NET interface to all layers within SQL Servers, such as the instances themselves, all logins, databases, tables, indexes, etc.
Best of all, it's now open source, you can take a look at the code here on [GitHub](https://github.com/microsoft/sqlmanagementobjects).

And to be honest: The functionality of dbatools inspired me to create this repository.
