How to use PowerShell as an IBM Informix database administrator.

## Install the server

I use IBM Informix 14.10 for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details.

But you can use any existing server in your environment.


## Install the client for PowerShell 5.1 on Windows

### IBM Client-SDK 4.50.FC8

I use the Client-SDK 4.50.FC8 in my lab. See my install script [Client.ps1](Client.ps1) in this folder for details.


### IBM.Data.DB2.dll

https://www.ibm.com/docs/en/informix-servers/14.10?topic=options-differences-between-net-providers

"Although the name of the provider indicates IBM DB2, this is in fact the single .NET provider for IBM data servers including Informix and IBM DB2. This is the recommended assembly for new application development for Informix Version 11.10 or later, and this is the preferred .NET provider."

I just can't get it to work - help very much appreciated!


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
```
![image](https://user-images.githubusercontent.com/66946165/191231797-baf8a0d5-8858-4287-91aa-c8678a090a7f.png)

See my script [Application.ps1](Application.ps1) in this folder for details.
