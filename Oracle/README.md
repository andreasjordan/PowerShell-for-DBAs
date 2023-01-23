How to use PowerShell as an Oracle database administrator.

Currently, this directory contains only the various wrapper commands and instructions on how to use them. If you are looking for information on how to install the database system and how to possibly use different clients, please use the [tag 2023-01](https://github.com/andreasjordan/PowerShell-for-DBAs/tree/2023-01) of this repository.


## Installation

If you don't want to download the complete repository, you can download the needed wrapper commands with this code from a suitable location:

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Import-OraLibrary.ps1 -OutFile Import-OraLibrary.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Connect-OraInstance.ps1 -OutFile Connect-OraInstance.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Invoke-OraQuery.ps1 -OutFile Invoke-OraQuery.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Read-OraQuery.ps1 -OutFile Read-OraQuery.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Export-OraTable.ps1 -OutFile Export-OraTable.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Import-OraTable.ps1 -OutFile Import-OraTable.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Get-OraTableInformation.ps1 -OutFile Get-OraTableInformation.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Get-OraTableReader.ps1 -OutFile Get-OraTableReader.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Write-OraTable.ps1 -OutFile Write-OraTable.ps1 -UseBasicParsing
```

To download the required libraries of the NuGet package, just dot source and run Import-OraLibrary:
```powershell
. ./Import-OraLibrary.ps1
Import-OraLibrary
```


## Importing

To make the wrapper commands available in the current session, just dot source them at the beginning of every skript:

```powershell
. ./Import-OraLibrary.ps1
. ./Connect-OraInstance.ps1
. ./Invoke-OraQuery.ps1
. ./Read-OraQuery.ps1
. ./Export-OraTable.ps1
. ./Import-OraTable.ps1
. ./Get-OraTableInformation.ps1
. ./Get-OraTableReader.ps1
. ./Write-OraTable.ps1
```

To import the NuGet libraries in the current session, just run Import-OraLibrary at the beginning of every skript:

```powershell
Import-OraLibrary
```


## The first connection

In case you have setup the lab using my AutomatedLab with DockerDatabases as the hostname and installed the sample database stackoverflow including the tables (see SetupSampleDatabases.ps1 and SetupSampleSchemaStackoverflow.ps1 for details) you can now connect to the Oracle instance:

```powershell
$connection = Connect-OraInstance -Instance DockerDatabases/XEPDB1 -Credential stackoverflow
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
Import-OraTable -Path ./Badges.xml -Connection $connection -Table Badges -ColumnMap @{ CreationDate = 'Date' }
Import-OraTable -Path ./Comments.xml -Connection $connection -Table Comments
Import-OraTable -Path ./PostLinks.xml -Connection $connection -Table PostLinks
Import-OraTable -Path ./Posts.xml -Connection $connection -Table Posts
Import-OraTable -Path ./Users.xml -Connection $connection -Table Users
Import-OraTable -Path ./Votes.xml -Connection $connection -Table Votes
```

In case there is already data in the tables, you can use `-TruncateTable` when calling `Import-OraTable`.


## Query data

Some ideas to query data:

```powershell
Invoke-OraQuery -Connection $connection -Query "SELECT * FROM Users WHERE Id = :Id" -ParameterValues @{ Id = -1 } | Format-List

Read-OraQuery -Connection $connection -Query "SELECT Id, DisplayName, Reputation FROM Users ORDER BY Reputation DESC" | Select-Object -First 5 | Format-Table
```

More ideas may follow...


## Change data

Some ideas to change data:

```powershell
Invoke-OraQuery -Connection $connection -Query "UPDATE Users SET Reputation = Reputation + 1 WHERE Id = :Id" -ParameterValues @{ Id = -1 }

Invoke-OraQuery -Connection $connection -Query "CREATE TABLE Test (Id INT, Text VARCHAR(100), Now TIMESTAMP(3))"
$params = @{
    Id   = 1
    Text = 'Just a text'
    Now  = [datetime]::Now
}
Invoke-OraQuery -Connection $connection -Query "INSERT INTO Test VALUES (:Id, :Text, :Now)" -ParameterValues $params
Invoke-OraQuery -Connection $connection -Query "SELECT * FROM Test" | Format-Table
Invoke-OraQuery -Connection $connection -Query "DROP TABLE Test"
```

More ideas may follow...


## And the DBA?

You can find some ideas on how to use the commands as a DBA in the DOAG2022 folder in this repository.

More ideas may follow...
