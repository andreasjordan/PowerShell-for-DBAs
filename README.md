# PowerShell for DBAs
How to use PowerShell as a database administrator.

## What is my idea?

I don't want to build a product or module. I want to provide a proof of concept, a tutorial, a code example, maybe a guide or a source of ideas for your own implementation. 

This is about using publicly available software (like database clients or NuGet packages) and a few lines of PowerShell code to show database administrators how to work with PowerShell. 

The basic idea is to install the .NET driver for the specific database management software and use the included DLL in PowerShell. Two PowerShell commands with a few lines of code wrap up the use of the required classes: One to open the connection, the other to execute queries. Other commands are possible, maybe there will be ideas about that here too.


## What database management systems do I cover?

Already covered database management systems:
* [Microsoft SQL Server](./SQLServer/README.md)
* [Oracle](./Oracle/README.md)
* [MySQL / MariaDB](./MySQL/README.md)
* [PostgreSQL](./PostgreSQL/README.md)

Already covered database management systems, but details are only available in the 2023-01 release of this repository:
* [IBM Db2](./Db2/README.md)
* [IBM Informix](./Informix/README.md)

Work in progress and help is needed:
* [Apache Cassandra](./Cassandra/README.md) 

Are there other database systems that I should add here?


## What client operating systems do I use?

Today I work mostly with Windows, so this can all be installed on a single Windows server or a small lab with Windows systems. But I also use WSL2 on Windows 10 with an Ubuntu image to test all clients from Linux as well. So you will find information about PowerShell 5.1 and 7.2 on Windows and PowerShell 7.2 on Linux. And it should work on MacOS as well.

I created [InstallAllClients.ps1](./PowerShell/InstallAllClients.ps1) for my lab - there you will find the exact versions and libraries I have tested with.

While setting up all databases on docker, I also set up two PowerShell containers and tested from there. See [SetupServerWithDocker.ps1](./PowerShell/SetupServerWithDocker.ps1) for details.


## What sample data do I use?

My little "application" is based on the StackOverflow database.

I have taken the 10GB version you can download [here](https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/) from the website of Brent Ozar. It is small enough for the SQL Server Express Edition.

I then selected some of the most popular questions and all related data (like answers, comments, users, etc.) and put that data in the JSON file [SampleData.json](./PowerShell/SampleData.json). I also changed one table and renamed the column named "Date" to "CreationDate" to not mess with the identically named data type. I don't use all the fancy data types, but only those needed for the data: numbers, timestamps and characters. See [CreateSampleData.ps1](./PowerShell/CreateSampleData.ps1) for details.

So I have stored the table structure in a structured format as well ([SampleSchema.psd1](./PowerShell/SampleSchema.psd1)) and automatically generate the correct DDL statements for each database system. See [Import-Schema.ps1](./PowerShell/Import-Schema.ps1) and [Import-Data.ps1](./PowerShell/Import-Data.ps1) on how I load the data.


## How can I use this for my job as a DBA? Do you have demos?

I use this technology for some time now in different projects with both SQL Server and Oracle.

On 2022-09-22 I presented some demos at the [DOAG in Nuremberg](https://shop.doag.org/events/anwenderkonferenz/2022/agenda/#eventDay.all#textSearch.PowerShell), you find the presentation and the democode in the folder [DOAG2022](./DOAG2022/README.md).

On 2022-12-12 I will hold a workshop day at the [IT-Tage](https://www.ittage.informatik-aktuell.de/programm/2022/sql-server-powershell-fuer-datenbank-admins-dba.html) and afterwords share the demos here in this repo.


## History

It all began with a windows based lab. I learned how to install and configure the different database systems from a command line. It worked quite well, but even though I only used the free versions of the database systems, not all the programs I needed could be easily downloaded from the internet. So it was not completely "infrastructure-as-code".

Next step was to use docker containers, as I was able to get docker images for all the different database systems without having to log in anywhere. As Docker Desktop it not completly free anymore, I also moved to Linux based on WSL2 on my windows 10 maschine. Resetting the WSL2 was easy but still not a one click action as I had to enter username and password followd by configuring the networking.

I now use the PowerShell module AutomatedLab to set up my labs, as it also installs Linux systems without interaction.

On the client side, I used three different sources to get the needed DLL for .NET: Vendor-provided clients (like the Oracle Client), third-party-provided clients (like those from DevArt), and NuGet packages. All three work very well, but there are small differences so the code has to be slightly adusted.

I now use only NuGet packages to have a common source for all database systems that is completely "infrastructure-as-code" based on publicly available software.

To reduce the repository but also keep the old version availably I decided to publish a release in january 2023 and afterwards remove these parts of the code:
* How to install database servers on a windows system
* How to use third-party-provided clients (like those from DevArt)
* How to use the new namespace Microsoft.Data.SqlClient instead of System.Data.SqlClient for SQL Server - because it is not easy to install the needed DLLs
* How to use dbatools for SQL Server - because I want the same interface and naming conventions for all databases
