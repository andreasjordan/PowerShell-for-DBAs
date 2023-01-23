How to use PowerShell as a Microsoft SQL Server database administrator.

Currently, this directory contains only the various wrapper commands and instructions on how to use them. If you are looking for information on how to install the database system and how to possibly use different clients, please use the [tag 2023-01](https://github.com/andreasjordan/PowerShell-for-DBAs/tree/2023-01) of this repository.


## Installation

If you don't want to download the complete repository, you can download the needed wrapper commands with this code from a suitable location:

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/SQLServer/Connect-SqlInstance.ps1 -OutFile Connect-SqlInstance.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/SQLServer/Invoke-SqlQuery.ps1 -OutFile Invoke-SqlQuery.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/SQLServer/Read-SqlQuery.ps1 -OutFile Read-SqlQuery.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/SQLServer/Export-SqlTable.ps1 -OutFile Export-SqlTable.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/SQLServer/Import-SqlTable.ps1 -OutFile Import-SqlTable.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/SQLServer/Get-SqlTableInformation.ps1 -OutFile Get-SqlTableInformation.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/SQLServer/Get-SqlTableReader.ps1 -OutFile Get-SqlTableReader.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/SQLServer/Write-SqlTable.ps1 -OutFile Write-SqlTable.ps1 -UseBasicParsing
```


## Importing

To make the wrapper commands available in the current session, just dot source them at the beginning of every skript:

```powershell
. ./Connect-SqlInstance.ps1
. ./Invoke-SqlQuery.ps1
. ./Read-SqlQuery.ps1
. ./Export-SqlTable.ps1
. ./Import-SqlTable.ps1
. ./Get-SqlTableInformation.ps1
. ./Get-SqlTableReader.ps1
. ./Write-SqlTable.ps1
```


## The first connection

In case you have setup the lab using my AutomatedLab with DockerDatabases as the hostname and installed the sample database stackoverflow including the tables (see SetupSampleDatabases.ps1 and SetupSampleSchemaStackoverflow.ps1 for details) you can now connect to the SQL Server instance:

```powershell
$connection = Connect-SqlInstance -Instance DockerDatabases -Credential StackOverflow -Database StackOverflow
```


## Importing more sample data

To download some sample data from the [Stack Exchange Data Dump](https://archive.org/details/stackexchange) you can use this code:

```powershell
Invoke-WebRequest -Uri https://archive.org/download/stackexchange/dba.meta.stackexchange.com.7z -OutFile tmp.7z -UseBasicParsing
# Extract the file tmp.7z using 7zip.
# On Linux use: 7za e tmp.7z
# On Windows use: C:\Progra~1\7-Zip\7z.exe e tmp.7z
# This should create some xml files in the current directory.
```

To import the xml files to the corresponding tables you can use this code:

```powershell
Import-SqlTable -Path ./Badges.xml -Connection $connection -Table Badges -ColumnMap @{ CreationDate = 'Date' }
Import-SqlTable -Path ./Comments.xml -Connection $connection -Table Comments
Import-SqlTable -Path ./PostLinks.xml -Connection $connection -Table PostLinks
Import-SqlTable -Path ./Posts.xml -Connection $connection -Table Posts
Import-SqlTable -Path ./Users.xml -Connection $connection -Table Users
Import-SqlTable -Path ./Votes.xml -Connection $connection -Table Votes
```

In case there is already data in the tables, you can use `-TruncateTable` when calling `Import-SqlTable`.


## Query data

Some ideas to query data:

```powershell
Invoke-SqlQuery -Connection $connection -Query "SELECT * FROM Users WHERE Id = @Id" -ParameterValues @{ Id = -1 } | Format-List

Read-SqlQuery -Connection $connection -Query "SELECT Id, DisplayName, Reputation FROM Users ORDER BY Reputation DESC" | Select-Object -First 5 | Format-Table
```

More ideas may follow...


## Change data

Some ideas to change data:

```powershell
Invoke-SqlQuery -Connection $connection -Query "UPDATE Users SET Reputation = Reputation + 1 WHERE Id = @Id" -ParameterValues @{ Id = -1 }

Invoke-SqlQuery -Connection $connection -Query "CREATE TABLE Test (Id INT, Text VARCHAR(100), Now DATETIME)"
$params = @{
    Id   = 1
    Text = 'Just a text'
    Now  = [datetime]::Now
}
Invoke-SqlQuery -Connection $connection -Query "INSERT INTO Test VALUES (@Id, @Text, @Now)" -ParameterValues $params
Invoke-SqlQuery -Connection $connection -Query "SELECT * FROM Test" | Format-Table
Invoke-SqlQuery -Connection $connection -Query "DROP TABLE Test"
```

More ideas may follow...


## And the DBA?

You can find some ideas on how to use the commands as a DBA in the DOAG2022 folder in this repository - you just need to adapt them to SQL Server.

More ideas may follow...
