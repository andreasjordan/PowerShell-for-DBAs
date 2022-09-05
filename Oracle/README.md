How to use PowerShell as an Oracle database administrator.

## Install the server

I use the free express edition of Oracle 21c for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details on how to run an unattended installation from a remote computer.

But you can use any existing server in your environment.


## Install the client for PowerShell 5.1 on Windows

### Oracle Database 19c Client

I use the Oracle Database 19c Client in my lab, as this is the last client with a working DLL. See my install script [Client.ps1](Client.ps1) in this folder for details on how to run an unattended installation of only the needed components.

But you can also use other ways to install the client. If you are unsure what components to install, just install all of them. If the oracle client is automatically installed by a software distribution tool, test if the file "Oracle.ManagedDataAccess.dll" is present in the path "odp.net\managed\common" in your oracle home.


### NuGet package Oracle.ManagedDataAccess 19.16.0

The newer versions have a non-solvable dependency, see [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details.

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder Oracle with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Oracle.ManagedDataAccess/19.16.0 -OutFile oracle.manageddataaccess.19.16.0.nupkg.zip -UseBasicParsing
Expand-Archive -Path oracle.manageddataaccess.19.16.0.nupkg.zip -DestinationPath .\Oracle
Remove-Item -Path oracle.manageddataaccess.19.16.0.nupkg.zip
```


### dotConnect for Oracle 10.0 Express

https://www.devart.com/dotconnect/oracle/

This free version might also be an option. See [Connect-OraInstance_Devart.ps1](Connect-OraInstance_Devart.ps1) and [Invoke-OraQuery_Devart.ps1](Invoke-OraQuery_Devart.ps1) on how to use this client.


## Install the client for PowerShell 7.2 on Windows

### NuGet package Oracle.ManagedDataAccess 2.19.160

The newer versions have a non-solvable dependency, see [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details.

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder Oracle with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Oracle.ManagedDataAccess.Core/2.19.160 -OutFile oracle.manageddataaccess.core.2.19.160.nupkg.zip -UseBasicParsing
Expand-Archive -Path oracle.manageddataaccess.core.2.19.160.nupkg.zip -DestinationPath .\Oracle 
Remove-Item -Path oracle.manageddataaccess.core.2.19.160.nupkg.zip
```


## Install the client for PowerShell 7.2 on Linux

### NuGet package Oracle.ManagedDataAccess 2.19.160

The newer versions have a non-solvable dependency, see [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details.

I only download and extract the package, no need to use nuget or any other tool.

I run this code in a suitable location where a subfolder Oracle with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Oracle.ManagedDataAccess.Core/2.19.160 -OutFile oracle.manageddataaccess.core.2.19.160.nupkg.zip -UseBasicParsing
Expand-Archive -Path oracle.manageddataaccess.core.2.19.160.nupkg.zip -DestinationPath ./Oracle 
Remove-Item -Path oracle.manageddataaccess.core.2.19.160.nupkg.zip
```


## Create an environment variable with the location of the dll

To be able to use the same scripts on all platforms and versions, I use an environment variable named "ORACLE_DLL" with the complete path to the needed dll file.

I use local PowerShell profiles, but you can use other ways as well.

I use this code to create the profile if there is no profile:
```
if (!(Test-Path -Path $PROFILE)) { $null = New-Item -ItemType File -Path $PROFILE -Force }
```

I use this code for the NuGet package Oracle.ManagedDataAccess:
```
"`$Env:ORACLE_DLL = '$((Get-Location).Path)/Oracle/lib/net40/Oracle.ManagedDataAccess.dll'" | Add-Content -Path $PROFILE
```

I use this code for the NuGet package Oracle.ManagedDataAccess.Core:
```
"`$Env:ORACLE_DLL = '$((Get-Location).Path)/Oracle/lib/netstandard2.0/Oracle.ManagedDataAccess.dll'" | Add-Content -Path $PROFILE
```

I use this code for the Devart client:
```
"`$Env:ORACLE_DLL = 'C:\Program Files (x86)\Devart\dotConnect\Oracle\Devart.Data.Oracle.dll'" | Add-Content -Path $PROFILE
```


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
