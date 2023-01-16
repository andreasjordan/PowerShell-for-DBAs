How to use PowerShell as an Oracle database administrator.

If you are missing some files, please download the 2023-01 release of this repository to find them.

## Install the server

You can use any existing server in your environment. If you want to setup a server just for tests, you find some recommendations in this section.

### Windows

You can use the free express edition of Oracle 21c. You will find further details in the 2023-01 release of this repository.


### Docker

I use the image [container-registry.oracle.com/database/express:latest](https://container-registry.oracle.com/) for my labs. Click on "Database" and then on "express" to get to the "Oracle Database XE Release 21c (21.3.0.0) Docker Image Documentation". See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


## Install the client for PowerShell 5.1 on Windows

### Oracle Database 19c Client

You can use the Oracle Database 19c Client, as this is the last client with a ready-to-use DLL. In the later versions, there are only NuGet packaged included. If you want to use the NuGet packages, I think it is much easier to install them directly without the client. But if you are not allowed to download things from the internet, using the 21c client might be a good option. You will find further details in the 2023-01 release of this repository.

But you can also use other ways to install the client. If you are unsure what components to install, just install all of them. If the oracle client is automatically installed by a software distribution tool, test if the file "Oracle.ManagedDataAccess.dll" is present in the path "odp.net\managed\common" in your oracle home.


### NuGet package Oracle.ManagedDataAccess

Versions after 19.16.0 have a non-solvable dependency to [System.Text.Json, Version=4.0.1.1], but this can be ignored on Add-Type as the needed dll is loaded anyway. See [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details and [Application.ps1](Application.ps1) for the code to ignore the error.

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder Oracle with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Oracle.ManagedDataAccess -OutFile oracle.manageddataaccess.nupkg.zip -UseBasicParsing
Expand-Archive -Path oracle.manageddataaccess.nupkg.zip -DestinationPath .\Oracle
Remove-Item -Path oracle.manageddataaccess.nupkg.zip
```


### Devart dotConnect for Oracle 10.0 Express

https://www.devart.com/dotconnect/oracle/

This free version might also be an option. You will find further details in the 2023-01 release of this repository.


## Install the client for PowerShell 7.2 on Windows

### NuGet package Oracle.ManagedDataAccess.Core

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder Oracle with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Oracle.ManagedDataAccess.Core -OutFile oracle.manageddataaccess.core.nupkg.zip -UseBasicParsing
Expand-Archive -Path oracle.manageddataaccess.core.nupkg.zip -DestinationPath .\Oracle 
Remove-Item -Path oracle.manageddataaccess.core.nupkg.zip
```


## Install the client for PowerShell 7.2 on Linux

### NuGet package Oracle.ManagedDataAccess.Core

I only download and extract the package, no need to use nuget or any other tool.

I run this code in a suitable location where a subfolder Oracle with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Oracle.ManagedDataAccess.Core -OutFile oracle.manageddataaccess.core.nupkg.zip -UseBasicParsing
Expand-Archive -Path oracle.manageddataaccess.core.nupkg.zip -DestinationPath ./Oracle 
Remove-Item -Path oracle.manageddataaccess.core.nupkg.zip
```


## Create an environment variable with the location of the dll

To be able to use the same scripts on all platforms and versions, I use an environment variable named "ORACLE_DLL" with the complete path to the needed dll file.

I use local PowerShell profiles, but you can use other ways as well.

I use this code to create the profile if there is no profile:
```
if (!(Test-Path -Path $PROFILE)) { $null = New-Item -ItemType File -Path $PROFILE -Force }
```

I use this code for the 19c client if the current location is the ORACLE_HOME:
```
"`$Env:ORACLE_DLL = '$((Get-Location).Path)\odp.net\managed\common\Oracle.ManagedDataAccess.dll'" | Add-Content -Path $PROFILE
```

I use this code for the NuGet package Oracle.ManagedDataAccess:
```
"`$Env:ORACLE_DLL = '$((Get-Location).Path)\Oracle\lib\net462\Oracle.ManagedDataAccess.dll'" | Add-Content -Path $PROFILE
```

I use this code for the NuGet package Oracle.ManagedDataAccess.Core:
```
"`$Env:ORACLE_DLL = '$((Get-Location).Path)/Oracle/lib/netstandard2.1/Oracle.ManagedDataAccess.dll'" | Add-Content -Path $PROFILE
```


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
