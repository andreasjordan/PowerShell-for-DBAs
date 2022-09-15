How to use PowerShell as an IBM Db2 database administrator.

## Install the server

I use the free community edition of IBM Db2 11.5.7.0 for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details.

But you can use any existing server in your environment.


## Install the client

### IBM Db2 11.5.7.0 Client

I use the IBM Db2 11.5.7.0 Client Client in my lab, as it is included in the software package. See my install script [Client.ps1](Client.ps1) in this folder for details.

One problem: You also need the DLL "Microsoft.ReportingServices.Interfaces.dll" with the version "10.0.0.0" as this is required by the DLL "IBM.Data.DB2.dll". The needed DLL is included in an installation of Reporting Services of SQL Server 2008 R2.


## Create an environment variable with the location of the dll

To be able to use the same scripts on all platforms and versions, I use an environment variable named "DB2_DLL" with the complete path to the needed dll file.

As we also need the DLL from the ReportingServices, I use a second environment variable named "MSREP_DLL".

I use local PowerShell profiles, but you can use other ways as well.

I use this code to create the profile if there is no profile:
```
if (!(Test-Path -Path $PROFILE)) { $null = New-Item -ItemType File -Path $PROFILE -Force }
```

I use this code for the IBM Db2 client if the current location is the SQLLIB folder:
```
"`$Env:DB2_DLL = '$((Get-Location).Path)\BIN\netf40\IBM.Data.DB2.dll'" | Add-Content -Path $PROFILE
"`$Env:MSREP_DLL = '<Add path here>\Microsoft.ReportingServices.Interfaces.dll'" | Add-Content -Path $PROFILE
```
