How to use PowerShell as an IBM Db2 database administrator.

## Install the server

I use the free community edition of IBM Db2 11.5.7.0 for my labs. See my install script Server.ps1 in this folder for details.

But you can use any existing server in your environment.


## Install the client

Details follow...

But:

```
Could not load file or assembly 'Microsoft.ReportingServices.Interfaces, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' or one of its dependencies. The system cannot find the file specified.
```

The DLL is part of Reporting Services of SQL Server 2008 R2. Copying this DLL works. But I think this is a bug. Have to get in contact with IBM...
