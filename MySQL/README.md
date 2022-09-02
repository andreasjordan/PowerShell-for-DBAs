How to use PowerShell as a MySQL database administrator.

## Install the server

I use the windows version of the [MySQL Installer 8.0.30](https://dev.mysql.com/downloads/installer/) (mysql-installer-community-8.0.30.0.msi) for my labs.

I have not yet found an easy way to run an unattended installation from a remote computer. So I ran an interactive installation on the target server and used the following options:
* Choosing a Setup Type: Server only
* Config Type: Server Computer (or Dedicated Computer if this is the only DBMS installed)
* MySQL Root Password: start123

But you can use any existing server in your environment. Just be sure to be able to connect from your client as root. In my lab, I ran `CREATE USER 'root'@'%' IDENTIFIED BY 'start123'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;` as the localhost root user.


## Install the client

### dotConnect for MySQL 9.0 Express

I use the free Express edition of dotConnect by DevArt in my lab, as this is an easy to install client. See my install script [Client.ps1](Client.ps1) in this folder for details on how to run an unattended installation.

Works with PowerShell 5.1 and PowerSehll 7.2.

https://www.devart.com/dotconnect/mysql/download.html

https://www.devart.com/dotconnect/mysql/docs/


### "Official client"

https://dev.mysql.com/downloads/connector/net/ is only 32bit and I think I had problems - still have to retry.

https://dev.mysql.com/downloads/windows/installer/8.0.html is the full install where I only installed the client.

Problem: 

```powershell
try {
    Add-Type -Path 'C:\Program Files (x86)\MySQL\Connector NET 8.0\Assemblies\v4.5.2\MySql.Data.dll'
} catch {
    $ex = $_
    $ex.Exception.Message
    $ex.Exception.LoaderExceptions
}
```

```
Unable to load one or more of the requested types. Retrieve the LoaderExceptions property for more information.
Could not load file or assembly 'System.Memory, Version=4.0.1.1, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' or one of its dependencies. The system cannot find the file specified.
```

I don't know where to get the requested version of "System.Memory". Using https://www.nuget.org/packages/System.Memory does not work.

Just asked here: https://forums.mysql.com/list.php?38


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
