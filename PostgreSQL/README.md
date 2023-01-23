How to use PowerShell as a PostgreSQL database administrator.

Currently, this directory contains only the various wrapper commands and instructions on how to use them. If you are looking for information on how to install the database system and how to possibly use different clients, please use the [tag 2023-01](https://github.com/andreasjordan/PowerShell-for-DBAs/tree/2023-01) of this repository.


## Installation

If you don't want to download the complete repository, you can download the needed wrapper commands with this code from a suitable location:

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Import-PgLibrary.ps1 -OutFile Import-PgLibrary.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Connect-PgInstance.ps1 -OutFile Connect-PgInstance.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Invoke-PgQuery.ps1 -OutFile Invoke-PgQuery.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Read-PgQuery.ps1 -OutFile Read-PgQuery.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Export-PgTable.ps1 -OutFile Export-PgTable.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Import-PgTable.ps1 -OutFile Import-PgTable.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Get-PgTableInformation.ps1 -OutFile Get-PgTableInformation.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Get-PgTableReader.ps1 -OutFile Get-PgTableReader.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/PostgreSQL/Write-PgTable.ps1 -OutFile Write-PgTable.ps1 -UseBasicParsing
```

To download the required libraries of the NuGet package, just dot source and run Import-PgLibrary:
```powershell
. ./Import-PgLibrary.ps1
Import-PgLibrary
```


## Importing

To make the wrapper commands available in the current session, just dot source them at the beginning of every skript:

```powershell
. ./Import-PgLibrary.ps1
. ./Connect-PgInstance.ps1
. ./Invoke-PgQuery.ps1
. ./Read-PgQuery.ps1
. ./Export-PgTable.ps1
. ./Import-PgTable.ps1
. ./Get-PgTableInformation.ps1
. ./Get-PgTableReader.ps1
. ./Write-PgTable.ps1
```

To import the NuGet libraries in the current session, just run Import-PgLibrary at the beginning of every skript:

```powershell
Import-PgLibrary
```


## The first connection

In case you have setup the lab using my AutomatedLab with DockerDatabases as the hostname and installed the sample database stackoverflow including the tables (see SetupSampleDatabases.ps1 and SetupSampleSchemaStackoverflow.ps1 for details) you can now connect to the PostgreSQL instance:

```powershell
$connection = Connect-PgInstance -Instance DockerDatabases -Credential stackoverflow -Database stackoverflow
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
Import-PgTable -Path ./Badges.xml -Connection $connection -Table Badges -ColumnMap @{ CreationDate = 'Date' }
Import-PgTable -Path ./Comments.xml -Connection $connection -Table Comments
Import-PgTable -Path ./PostLinks.xml -Connection $connection -Table PostLinks
Import-PgTable -Path ./Posts.xml -Connection $connection -Table Posts
Import-PgTable -Path ./Users.xml -Connection $connection -Table Users
Import-PgTable -Path ./Votes.xml -Connection $connection -Table Votes
```

In case there is already data in the tables, you can use `-TruncateTable` when calling `Import-PgTable`.


## Query data

Some ideas to query data:

```powershell
Invoke-PgQuery -Connection $connection -Query "SELECT * FROM Users WHERE Id = :Id" -ParameterValues @{ Id = -1 } | Format-List

Read-PgQuery -Connection $connection -Query "SELECT Id, DisplayName, Reputation FROM Users ORDER BY Reputation DESC" | Select-Object -First 5 | Format-Table
```

More ideas may follow...


## Change data

Some ideas to change data:

```powershell
Invoke-PgQuery -Connection $connection -Query "UPDATE Users SET Reputation = Reputation + 1 WHERE Id = :Id" -ParameterValues @{ Id = -1 }

Invoke-PgQuery -Connection $connection -Query "CREATE TABLE Test (Id INT, Text VARCHAR(100), Now TIMESTAMP(3))"
$params = @{
    Id   = 1
    Text = 'Just a text'
    Now  = [datetime]::Now
}
Invoke-PgQuery -Connection $connection -Query "INSERT INTO Test VALUES (:Id, :Text, :Now)" -ParameterValues $params
Invoke-PgQuery -Connection $connection -Query "SELECT * FROM Test" | Format-Table
Invoke-PgQuery -Connection $connection -Query "DROP TABLE Test"
```

More ideas may follow...


## And the DBA?

You can find some ideas on how to use the commands as a DBA in the DOAG2022 folder in this repository - you just need to adapt them to PostgreSQL.

More ideas may follow...
