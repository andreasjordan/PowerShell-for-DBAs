How to use PowerShell as an IBM Db2 database administrator.

## Install the server

I use the free community edition of IBM Db2 11.5.7.0 for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details.

But you can use any existing server in your environment.


## Install the client for PowerShell 5.1 on Windows

### IBM Db2 11.5.7.0 Client

I use the IBM Db2 11.5.7.0 Client in my lab, as it is included in the software package. See my install script [Client.ps1](Client.ps1) in this folder for details.

The included DLL has a non-solvable dependency to [Microsoft.ReportingServices.Interfaces, Version=10.0.0.0], but this can be ignored on Add-Type as the needed dll is loaded anyway. See [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details and [Application.ps1](Application.ps1) for the code to ignore the error. But you can also get the needed DLL from Reporting Services of SQL Server 2008 R2.


## Install the client for PowerShell 7.2 on Windows

...


## Create an environment variable with the location of the dll

To be able to use the same scripts on all platforms and versions, I use an environment variable named "DB2_DLL" with the complete path to the needed dll file.

I use local PowerShell profiles, but you can use other ways as well.

I use this code to create the profile if there is no profile:
```
if (!(Test-Path -Path $PROFILE)) { $null = New-Item -ItemType File -Path $PROFILE -Force }
```

I use this code for the IBM Db2 client if the current location is the SQLLIB folder:
```
"`$Env:DB2_DLL = '$((Get-Location).Path)\BIN\netf40\IBM.Data.DB2.dll'" | Add-Content -Path $PROFILE
```


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

You have to create the windows user "stackoverflow" first. I created it as a domain user, a local user might also work. In my setup, the user does not need to be member of any group.

See my script [Application.ps1](Application.ps1) in this folder for details.
