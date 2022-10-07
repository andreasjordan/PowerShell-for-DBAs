How to use PowerShell as an IBM Informix database administrator.

## Install the server

You can use any existing server in your environment. If you want to setup a server just for tests, you find some recommendations in this section.

### Windows

I use IBM Informix 14.10 for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details.


### Docker

I use the image [ibmcom/informix-developer-database:latest](https://hub.docker.com/r/ibmcom/informix-developer-database) for my labs. See my install script [SetupServerWithDocker.ps1](../PowerShell/SetupServerWithDocker.ps1) in the PowerShell folder for details.


## Install the client for PowerShell 5.1 on Windows

### IBM Client-SDK 4.50.FC8

I use the Client-SDK 4.50.FC8 in my lab. See my install script [Client.ps1](Client.ps1) in this folder for details.


### IBM.Data.DB2.dll

Works well, see Db2. Will update the text here later.


## Create an environment variable with the location of the dll

To be able to use the same scripts on all platforms and versions, I use an environment variable named "INFORMIX_DLL" with the complete path to the needed dll file.

I use local PowerShell profiles, but you can use other ways as well.

I use this code to create the profile if there is no profile:
```
if (!(Test-Path -Path $PROFILE)) { $null = New-Item -ItemType File -Path $PROFILE -Force }
```

I use this code for the IBM Client-SDK 4.50.FC8 if the current location is the folder it installed to:
```
"`$Env:INFORMIX_DLL = '$((Get-Location).Path)\bin\netf40\IBM.Data.Informix.dll'" | Add-Content -Path $PROFILE
```


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

You have to create the windows user "stackoverflow" first. I created it as a domain user, a local user might also work. In my setup, the user does not need to be member of any group.

I created the database using dbaccess on the server as the user informix with the following commands:
```
set DB_LOCALE=en_US.utf8
dbaccess - -
CREATE DATABASE stackoverflow WITH BUFFERED LOG;
GRANT CONNECT TO stackoverflow;
GRANT RESOURCE TO stackoverflow;
```
![image](https://user-images.githubusercontent.com/66946165/191233196-3f86d778-801d-43f2-920f-c3ac67da21f1.png)


See my script [Application.ps1](Application.ps1) in this folder for details.
