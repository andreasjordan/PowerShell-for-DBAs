# PowerShell for DBAs
How to use PowerShell as a database administrator.

## What is my idea?

I don't want to build a product or module. I want to provide a proof of concept, a tutorial, a code example, maybe a guide or a source of ideas for your own implementation. 

This is about using publicly available software (like database clients or NuGet packages) and a few lines of PowerShell code to show database administrators how to work with PowerShell. 

The basic idea is to install the .NET driver for the specific database management software and use the included DLL in PowerShell. Two PowerShell commands with a few lines of code wrap up the use of the required classes: One to open the connection, the other to execute queries. Other commands are possible, maybe there will be ideas about that here too.


## What database management systems do I cover?

Already covered database management systems:
* Microsoft SQL Server
* Oracle
* MySQL
* PostgreSQL

Planned in the near future:
* IMB Db2
* IBM Informix


## What client operating systems do I use?

Today I work mostly with Windows, so this can all be installed on a single Windows server or a small lab with Windows systems. But I also use WSL2 on Windows 10 with an Ubuntu image to test all clients from Linux as well. So you will find information about PowerShell 5.1 and 7.2 on Windows and PowerShell 7.2 on Linux. And it should work on MacOS as well.

I created [InstallAllClients.ps1](./PowerShell/InstallAllClients.ps1) for my lab - there you will find the exact versions and libraries I have tested with.


## What sample data do I use?

My little "application" is based on the StackOverflow database.

I have taken the 10GB version you can download [here](https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/) from the website of Brenz Ozar. It is small enough for the SQL Server Express Edition.

I then selected some of the most popular questions and all related data (like answers, comments, users, etc.) and put that data in the JSON file [SampleData.json](./PowerShell/SampleData.json). I also changed one table and renamed the column named "Date" to "CreationDate" to not mess with the identically named data type. I don't use all the fancy data types, but only those needed for the data: numbers, timestamps and characters. See [CreateSampleData.ps1](./PowerShell/CreateSampleData.ps1) for details.

So I have stored the table structure in a structured format as well ([SampleSchema.psd1](./PowerShell/SampleSchema.psd1)) and automatically generate the correct DDL statements for each database system. See [Import-Schema.ps1](./PowerShell/Import-Schema.ps1) and [Import-Data.ps1](./PowerShell/Import-Data.ps1) on how I load the data.

