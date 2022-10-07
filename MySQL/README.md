How to use PowerShell as a MySQL or MariaDB database administrator.

## Install the server

You can use any existing server in your environment. If you want to setup a server just for tests, you find some recommendations in this section.

### MySQL on Windows

I use the windows version of the [MySQL Installer 8.0.30](https://dev.mysql.com/downloads/installer/) (mysql-installer-community-8.0.30.0.msi) for my labs.

I have not yet found an easy way to run an unattended installation from a remote computer. So I ran an interactive installation on the target server and used the following options:
* Choosing a Setup Type: Server only
* Config Type: Server Computer (or Dedicated Computer if this is the only DBMS installed)
* MySQL Root Password: start123


### MySQL on Docker

I use the image [mysql:latest](https://hub.docker.com/_/mysql) for my labs. See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


### MariaDB on Docker

I use the image [mariadb:latest](https://hub.docker.com/_/mariadb) for my labs. See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


## Install the client

We can use (nearly) the same sources and installation code on all the target environments:
* PowerShell 5.1 on Windows
* PowerShell 7.2 on Windows
* PowerShell 7.2 on Linux


### NuGet package MySql.Data

Versions after 6.10.9 have a lot of non-solvable dependencies, but this can be ignored on Add-Type as the needed dll is loaded anyway. See [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details and [Application.ps1](Application.ps1) for the code to ignore the error.

I only download and extract the package, no need to use nuget or any other tool.

I run this code in a suitable location where a subfolder MySQL with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/MySql.Data -OutFile mysql.data.nupkg.zip -UseBasicParsing
Expand-Archive -Path mysql.data.nupkg.zip -DestinationPath .\MySQL
Remove-Item -Path mysql.data.nupkg.zip
```


### MySQL Connector/NET 8.0.30

Like with the NuGet package, we have non-solvable dependencies on some target environments, but this can be ignored on Add-Type as the needed dll is loaded anyway. See [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details and [Application.ps1](Application.ps1) for the code to ignore the error.

https://dev.mysql.com/downloads/connector/net/

I run this code in a suitable location where a subfolder MySQL with the content of the connector will be created:

```
Invoke-WebRequest -Uri https://dev.mysql.com/get/Downloads/Connector-Net/mysql-connector-net-8.0.30-noinstall.zip -OutFile mysql-connector-net-noinstall.zip -UseBasicParsing
Expand-Archive -Path mysql-connector-net-noinstall.zip -DestinationPath .\MySQL
Remove-Item -Path mysql-connector-net-noinstall.zip
```


### Devart dotConnect for MySQL 9.0 Express

https://www.devart.com/dotconnect/mysql/

This free version might also be an option, but is for Windows only. See my install script [Client.ps1](Client.ps1) in this folder for details on how to run an unattended installation.
See [Connect-MyInstance_Devart.ps1](Connect-MyInstance_Devart.ps1) and [Invoke-MyQuery_Devart.ps1](Invoke-MyQuery_Devart.ps1) on how to use this client.


## Create an environment variable with the location of the dll

To be able to use the same scripts on all platforms and versions, I use an environment variable named "MYSQL_DLL" with the complete path to the needed dll file.

I use local PowerShell profiles, but you can use other ways as well.

I use this code to create the profile if there is no profile:
```
if (!(Test-Path -Path $PROFILE)) { $null = New-Item -ItemType File -Path $PROFILE -Force }
```

I use this code for the MySQL Connector/NET 8.0.30 for PowerShell 5.1:
```
"`$Env:MYSQL_DLL = '$((Get-Location).Path)/v4.5.2/MySql.Data.dll'" | Add-Content -Path $PROFILE
```

I use this code for the NuGet package MySql.Data:
```
"`$Env:MYSQL_DLL = '$((Get-Location).Path)/MySQL/lib/net6.0/MySql.Data.dll'" | Add-Content -Path $PROFILE
```

I use this code for the Devart client:
```
"`$Env:MYSQL_DLL = 'C:\Program Files (x86)\Devart\dotConnect\MySQL\Devart.Data.MySQL.dll'" | Add-Content -Path $PROFILE
```


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
