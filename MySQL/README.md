How to use PowerShell as a MySQL database administrator.

## Install the server

I use the windows version of the [MySQL Installer 8.0.30](https://dev.mysql.com/downloads/installer/) (mysql-installer-community-8.0.30.0.msi) for my labs.

I have not yet found an easy way to run an unattended installation from a remote computer. So I ran an interactive installation on the target server and used the following options:
* Choosing a Setup Type: Server only
* Config Type: Server Computer (or Dedicated Computer if this is the only DBMS installed)
* MySQL Root Password: start123

But you can use any existing server in your environment. Just be sure to be able to connect from your client as root. In my lab, I ran `CREATE USER 'root'@'%' IDENTIFIED BY 'start123'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;` as the localhost root user.


## Install the client for PowerShell 5.1 on Windows
 
### NuGet package MySql.Data 6.10.9

The newer versions have problems with the dependencies, will have a deepler look later.

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder MySQL with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/MySql.Data/6.10.9 -OutFile mysql.data.6.10.9.nupkg.zip -UseBasicParsing
Expand-Archive -Path mysql.data.6.10.9.nupkg.zip -DestinationPath .\MySQL
Remove-Item -Path mysql.data.6.10.9.nupkg.zip
```


### MySQL Connector/NET 8.0.30

I have problems with the dependencies, will have a deepler look later.
 
https://dev.mysql.com/downloads/connector/net/

I run this code in a suitable location where a subfolder MySQL with the content of the connector will be created:

```
Invoke-WebRequest -Uri https://dev.mysql.com/get/Downloads/Connector-Net/mysql-connector-net-8.0.30-noinstall.zip -OutFile mysql-connector-net-8.0.30-noinstall.zip -UseBasicParsing
Expand-Archive -Path mysql-connector-net-8.0.30-noinstall.zip -DestinationPath .\MySQL
Remove-Item -Path mysql-connector-net-8.0.30-noinstall.zip
```

When I try to load the dll, I get:
```
Unable to load one or more of the requested types. Retrieve the LoaderExceptions property for more information.
Could not load file or assembly 'System.Memory, Version=4.0.1.1, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' or one of its dependencies. The system cannot find the file specified.
```

I don't know where to get the requested version of "System.Memory". Just asked here: https://forums.mysql.com/list.php?38 - but the question is still not published...


### dotConnect for MySQL 9.0 Express

https://www.devart.com/dotconnect/mysql/

This free version might also be an option. See my install script [Client.ps1](Client.ps1) in this folder for details on how to run an unattended installation.
See [Connect-MyInstance_Devart.ps1](Connect-MyInstance_Devart.ps1) and [Invoke-MyQuery_Devart.ps1](Invoke-MyQuery_Devart.ps1) on how to use this client.


## Install the client for PowerShell 7.2 on Windows
 
### MySQL Connector/NET 8.0.30

This is the current version and works very well on PowerShell 7.2.

https://dev.mysql.com/downloads/connector/net/

I run this code in a suitable location where a subfolder MySQL with the content of the connector will be created:

```
Invoke-WebRequest -Uri https://dev.mysql.com/get/Downloads/Connector-Net/mysql-connector-net-8.0.30-noinstall.zip -OutFile mysql-connector-net-8.0.30-noinstall.zip -UseBasicParsing
Expand-Archive -Path mysql-connector-net-8.0.30-noinstall.zip -DestinationPath .\MySQL
Remove-Item -Path mysql-connector-net-8.0.30-noinstall.zip
```


### NuGet package MySql.Data 6.10.9

The newer versions have problems with the dependencies, will have a deepler look later.

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder MySQL with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/MySql.Data/6.10.9 -OutFile mysql.data.6.10.9.nupkg.zip -UseBasicParsing
Expand-Archive -Path mysql.data.6.10.9.nupkg.zip -DestinationPath .\MySQL
Remove-Item -Path mysql.data.6.10.9.nupkg.zip
```


### dotConnect for MySQL 9.0 Express

https://www.devart.com/dotconnect/mysql/

This free version might also be an option. See my install script [Client.ps1](Client.ps1) in this folder for details on how to run an unattended installation. See [Connect-MyInstance_Devart.ps1](Connect-MyInstance_Devart.ps1) and [Invoke-MyQuery_Devart.ps1](Invoke-MyQuery_Devart.ps1) on how to use this client.


## Install the client for PowerShell 7.2 on Linux
 
### MySQL Connector/NET 8.0.30

This is the current version and works very well on PowerShell 7.2.

https://dev.mysql.com/downloads/connector/net/

I run this code in a suitable location where a subfolder MySQL with the content of the connector will be created:

```
Invoke-WebRequest -Uri https://dev.mysql.com/get/Downloads/Connector-Net/mysql-connector-net-8.0.30-noinstall.zip -OutFile mysql-connector-net-8.0.30-noinstall.zip -UseBasicParsing
Expand-Archive -Path mysql-connector-net-8.0.30-noinstall.zip -DestinationPath ./MySQL
Remove-Item -Path mysql-connector-net-8.0.30-noinstall.zip
```


### NuGet package MySql.Data 6.10.9

The newer versions have problems with the dependencies, will have a deepler look later.

I only download and extract the package, no need to use nuget.exe or any other tool.

I run this code in a suitable location where a subfolder MySQL with the content of the Nuget package will be created:

```
Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/MySql.Data/6.10.9 -OutFile mysql.data.6.10.9.nupkg.zip -UseBasicParsing
Expand-Archive -Path mysql.data.6.10.9.nupkg.zip -DestinationPath ./MySQL
Remove-Item -Path mysql.data.6.10.9.nupkg.zip
```


## Create an environment variable with the location of the dll

To be able to use the same scripts on all platforms and versions, I use an environment variable named "MYSQL_DLL" with the complete path to the needed dll file.

I use local PowerShell profiles, but you can use other ways as well.

I use this code to create the profile if there is no profile:
```
if (!(Test-Path -Path $PROFILE)) { $null = New-Item -ItemType File -Path $PROFILE -Force }
```

I use this code for the MySQL Connector/NET 8.0.30:
```
"`$Env:MYSQL_DLL = '$((Get-Location).Path)/MySQL/net6.0/MySql.Data.dll'" | Add-Content -Path $PROFILE
```

I use this code for the NuGet package MySql.Data:
```
"`$Env:MYSQL_DLL = '$((Get-Location).Path)/MySQL/lib/net452/MySql.Data.dll'" | Add-Content -Path $PROFILE
```

I use this code for the Devart client:
```
"`$Env:MYSQL_DLL = 'C:\Program Files (x86)\Devart\dotConnect\MySQL\Devart.Data.MySQL.dll'" | Add-Content -Path $PROFILE
```


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
