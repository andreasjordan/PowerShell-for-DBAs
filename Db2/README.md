How to use PowerShell as an IBM Db2 database administrator.

## Install the server

You can use any existing server in your environment. If you want to setup a server just for tests, you find some recommendations in this section.

### Windows

I use the free community edition of IBM Db2 11.5.7.0 for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details.


### Docker

I use the image [ibmcom/db2:latest](https://hub.docker.com/r/ibmcom/db2) for my labs. See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


## Install the client for PowerShell 5.1 on Windows

### IBM Db2 11.5.7.0 Client

I use the IBM Db2 11.5.7.0 Client in my lab, as it is included in the software package. See my install script [Client.ps1](Client.ps1) in this folder for details.

Only with PowerShell 5.1 the included DLL has a non-solvable dependency to [Microsoft.ReportingServices.Interfaces, Version=10.0.0.0], but this can be ignored on Add-Type as the needed dll is loaded anyway. See [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details and [Application.ps1](Application.ps1) for the code to ignore the error. But you can also get the needed DLL from Reporting Services of SQL Server 2008 R2.


### Devart dotConnect for DB2 3.0 Professional

https://www.devart.com/dotconnect/db2/

As there is no free version available, I have not tested it.


## Install the client for PowerShell 7.2 on Windows

### NuGet package Net.IBM.Data.Db2

This package is compatible with .NET 6.0 and was recently updated, so this would be my first choice.

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder "Net.IBM.Data.Db2" with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Net.IBM.Data.Db2 -OutFile Net.IBM.Data.Db2.nupkg.zip -UseBasicParsing
Expand-Archive -Path Net.IBM.Data.Db2.nupkg.zip -DestinationPath .\Net.IBM.Data.Db2
Remove-Item -Path Net.IBM.Data.Db2.nupkg.zip
```

Add the "buildTransitive\clidriver\bin" path of the NuGet package to the PATH environment variable of the system.


### IBM Db2 11.5.7.0 Client

You can also use the IBM Db2 11.5.7.0 Client, as it is included in the software package. See my install script [Client.ps1](Client.ps1) in this folder for details.


### NuGet package IBM.Data.DB2.Core

This package is compatible with .NET Standard 2.1. Downside of this package is the namespace: The official client and the package Net.IBM.Data.Db2 use "IBM.Data.Db2", this package uses "IBM.Data.DB2.Core", so you would need a different implementation of the wrapper commands. The needed files have "Core" in their filename.

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder "IBM.Data.DB2.Core" with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/IBM.Data.DB2.Core -OutFile IBM.Data.DB2.Core.nupkg.zip -UseBasicParsing
Expand-Archive -Path IBM.Data.DB2.Core.nupkg.zip -DestinationPath .\IBM.Data.DB2.Core
Remove-Item -Path IBM.Data.DB2.Core.nupkg.zip
```

Add the "buildTransitive\clidriver\bin" path of the NuGet package to the PATH environment variable of the system.


### Devart dotConnect for DB2 3.0 Professional

https://www.devart.com/dotconnect/db2/

As there is no free version available, I have not tested it.


## Install the client for PowerShell 7.2 on Linux

### NuGet package Net.IBM.Data.Db2-lnx

This package is compatible with .NET 6.0 and was recently updated, so this would be my first choice.

I only download and extract the package, no need to use nuget or any other tool.

I run this code in a suitable location where a subfolder "Net.IBM.Data.Db2-lnx" with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Net.IBM.Data.Db2-lnx -OutFile Net.IBM.Data.Db2-lnx.nupkg.zip -UseBasicParsing
Expand-Archive -Path Net.IBM.Data.Db2-lnx.nupkg.zip -DestinationPath ./Net.IBM.Data.Db2-lnx
Remove-Item -Path Net.IBM.Data.Db2-lnx.nupkg.zip
```

Add the "buildTransitive/clidriver/lib" path of the NuGet package to the LD_LIBRARY_PATH environment variable of the system.


### NuGet package IBM.Data.DB2.Core-lnx

This package is compatible with .NET Standard 2.1. Downside of this package is the namespace: The official client and the package Net.IBM.Data.Db2-lnx use "IBM.Data.Db2", this package uses "IBM.Data.DB2.Core", so you would need a different implementation of the wrapper commands. The needed files have "Core" in their filename.

I only download and extract the package, no need to use nuget or any other tool.

I run this code in a suitable location where a subfolder "IBM.Data.DB2.Core-lnx" with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/IBM.Data.DB2.Core-lnx -OutFile IBM.Data.DB2.Core-lnx.nupkg.zip -UseBasicParsing
Expand-Archive -Path IBM.Data.DB2.Core-lnx.nupkg.zip -DestinationPath ./IBM.Data.DB2.Core-lnx
Remove-Item -Path IBM.Data.DB2.Core-lnx.nupkg.zip
```

Add the "buildTransitive/clidriver/lib" path of the NuGet package to the LD_LIBRARY_PATH environment variable of the system.


### IBM Db2 11.5.7.0 Client

There should be an official client for Linux, but I have not tested it.


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

I use this code for the NuGet package Net.IBM.Data.Db2 if the current location is the folder I started the extraction:
```
"`$Env:DB2_DLL = '$((Get-Location).Path)\Net.IBM.Data.Db2\lib\net6.0\IBM.Data.Db2.dll'" | Add-Content -Path $PROFILE
```


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

You have to create the windows user "stackoverflow" first. I created it as a domain user, a local user might also work. In my setup, the user does not need to be member of any group.

See my script [Application.ps1](Application.ps1) in this folder for details.
