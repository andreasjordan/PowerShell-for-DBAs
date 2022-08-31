How to use PowerShell as a MySQL database administrator.

## Install the server

First attempt:

```powershell
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy('http://192.168.128.2:3128')
$null = Invoke-Expression -Command ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
$null = choco config set proxy http://192.168.128.2:3128
choco install mysql --confirm --limitoutput --no-progress --params "/installLocation:D:\MySQL"
@"
ALTER USER 'root'@'localhost' IDENTIFIED BY 'start123';
flush privileges;
"@ | D:\MySQL\mysql\current\bin\mysql.exe -uroot


$firewallConfig = @{
    DisplayName = 'MySQL'
    Name        = 'MySQL'
    Group       = 'MySQL'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    LocalPort   = '3306'
}
$null = New-NetFirewallRule @firewallConfig


"ALTER USER 'root'@'%' IDENTIFIED BY 'start123'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; flush privileges;" | D:\MySQL\mysql\current\bin\mysql.exe -uroot -p
```


## Install the client

### dotConnect for MySQL 9.0 Express

https://www.devart.com/dotconnect/mysql/download.html

https://www.devart.com/dotconnect/mysql/docs/

See [Client.ps1](Client.ps1) for details on installation.


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
