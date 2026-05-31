# PowerShell for DBAs

This repository provides infrastructure as code, sample data and demo code to show how PowerShell can be used as a database administrator.


## What is my idea?

I don't want to build a product or module. I want to provide a proof of concept, a tutorial, a code example, maybe a guide or a source of ideas for your own implementation. 

This is about using publicly available software (like database clients or NuGet packages) and a few lines of PowerShell code to show database administrators how to work with PowerShell. 

The basic idea is to install the .NET driver for the specific database management software and use the included DLL in PowerShell. Two PowerShell commands with a few lines of code wrap up the use of the required classes: One to open the connection, the other to execute queries. For ease of use I added a command to download and import the required .NET libraries.

Because I needed it for a project, I implemented commands to transfer data from Oracle to SQL Server. To have the same functionality for all database systems, I created all the needed commands and even some more for the main four database systems I focus on in this project.


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


## Infrastructure

The repository is designed for and tested on a Windows 11 system with 32 GB of RAM. WSL2 is configured with Docker to run the databases inside containers.

The initial PowerShell code must be run inside WSL2 to set up the sample data.

The demo PowerShell code can be executed either inside WSL2 or on the Windows 11 system. However, to run all demos, PowerShell 7.5 or later is required.

A video of the installation is available here: https://youtu.be/0NNNqPau4Go


### Install WSL2

I use the Ubuntu 24.04 image by running `wsl --install -d Ubuntu-24.04` in an elevated Command Prompt or PowerShell on a current Windows 11 system. To start from scratch, you can remove Ubuntu by running `wsl --unregister Ubuntu-24.04`. At the end of the installation, Ubuntu starts automatically, and you are prompted to create a Unix user account. The username and password do not matter.


### Clone or download the repository

Open a non-elevated PowerShell and navigate to a folder of your choice. In this guide, I will use `C:\tmp`.

```
if (-not (Test-Path -Path C:\tmp)) {
    $null = New-Item -Path C:\tmp -ItemType Directory
}
Set-Location -Path C:\tmp
```

If you have git installed, you can just clone the repository:

```
git clone https://github.com/andreasjordan/PowerShell-for-DBAs.git
```

Or you can download and extract the repository:

```
[Net.WebClient]::new().DownloadFile('https://github.com/andreasjordan/PowerShell-for-DBAs/archive/refs/heads/main.zip', "$PWD\PowerShell-for-DBAs.zip")
Expand-Archive -Path $PWD\PowerShell-for-DBAs.zip -DestinationPath $PWD
Rename-Item -Path $PWD\PowerShell-for-DBAs-main -NewName PowerShell-for-DBAs
Remove-Item -Path $PWD\PowerShell-for-DBAs.zip
Get-ChildItem -Path $PWD\PowerShell-for-DBAs -Filter *.ps1 -Recurse | Unblock-File
```


### Start the installation

To run all setup steps, simply execute `01_setup.ps1` in a non-elevated PowerShell.

During the setup, you will be prompted to choose which database containers to create.

At the end, the script enters WSL2 to keep all Docker containers running. If you exit, WSL2 will shut down along with all containers.


### Work with the docker containers

I included some PowerShell scripts to work with the containers from a root WSL2 session:
* start_containers.ps1
* stop_containers.ps1
* remove_containers.ps1


## What sample data do I use?

My little "application" is based on the StackOverflow database.

I have taken the 10GB version you can download [here](https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/) from the website of Brent Ozar. It is small enough for the SQL Server Express Edition.

I then selected some of the most popular questions and all related data (like answers, comments, users, etc.) and put that data in the JSON file [SampleData.json](./PowerShell/SampleData.json). I also changed one table and renamed the column named "Date" to "CreationDate" to not mess with the identically named data type. I don't use all the fancy data types, but only those needed for the data: numbers, timestamps and characters. See [CreateSampleData.ps1](./PowerShell/CreateSampleData.ps1) for details.

So I have stored the table structure in a structured format as well ([SampleSchema.psd1](./PowerShell/SampleSchema.psd1)) and automatically generate the correct DDL statements for each database system. See [Import-Schema.ps1](./PowerShell/Import-Schema.ps1) and [03_ImportSampleDataFromJson.ps1](./PowerShell/03_ImportSampleDataFromJson.ps1) on how I load the data.

While working on the commands to transfer data between database systems, I also created commands to import and export data from and to files. The import command can read files in the xml format that the [Stack Exchange Data Dump](https://archive.org/details/stackexchange) uses. This makes it possible to import all the different files into the four database systems I'm focusing on in this project. See [04_ImportSampleDataFromStackexchange.ps1](./PowerShell/04_ImportSampleDataFromStackexchange.ps1) for details.


## What commands are included?

For every database system, I have the following set of commands. The noun is prefixed by "Sql", "Ora", "My" or "Pg" depending on the target database system.

### Import-Library

Imports the needed DLLs from the matching NuGet package. Downloads the package if needed. Not needed for SQL Server as I use the classes included in the .NET Framework.

### Connect-Instance

Takes information about the instance, connects to the instance and returns a connection object.

### Invoke-Query

Takes a connection object and a query, executes the query using a data adapter and returns the data.

### Read-Query

Takes a connection object and a query, executes the query using a data reader and returns the data row by row as PSCustomObject.

This command can be used in a pipeline where the data is consumed row by row by other commands. This way, the lange result of a query can we saved to a file row by row.

### Export-Table

Takes a connection object, a table name and a file path, selects the table line by line and writes the data line by line to the file. Each line will be encoded in json using `($row | ConvertTo-Json -Compress)`. The file can be imported using Import-Table.

### Import-Table

Takes a file path, a connection object and a table name, reads the file line by line and imports the data into the table in batches using bulk copy.

Supported file formats:
* xml: Format used by the [Stack Exchange Data Dump](https://archive.org/details/stackexchange). Every line is one row formated as xml and will be decoded with `([xml]$line).row`.
* json: My own idea. Every line is one row formated as json and will be decoded with `$line | ConvertFrom-Json`. This is the format that Export-Table writes.

### Get-TableInformation

Takes a connection object and optionally a list of table names. If no table names are given, all tables are processed. For every table an object with the table name, the number of pages/blocks and the numer of rows is returned. This information can be used to loop over the tables and to know how many rows will be transfered using Get-TableReader and Write-Table to be able to display a progress bar.

### Get-TableReader

Takes a connection object and a table name, returns a data reader object. This can be used with Write-Table to transfer data from one database to another.

### Write-Table

Takes a connection object, a table name and either an array of data objects or a data reader object. Imports the data into the table in batches using bulk copy.


## What command should I use?

As a starting point, always use Import-Library and Connect-Instance to set up a connection.

While working with small amounts of data that can be in memory all at once, use Invoke-Query to read data and Write-Table to write data.

To transfer large amounts of data between databases and files, use Export-Table and Import-Table in case the supported file formats meet your requirements. To be more flexible use Read-Query and Write-Table.

To transfer large amounts of data between databases, use Get-TableInformation, Get-TableReader and Write-Table.


## How can I use this for my job as a DBA? Do you have demos?

I use this technology for some time now in different projects with both SQL Server and Oracle.

On 2022-09-22 I presented some demos at the [DOAG in Nuremberg](https://shop.doag.org/events/anwenderkonferenz/2022/agenda/#eventDay.all#textSearch.PowerShell), you find the presentation and the democode in the folder [DOAG2022](./DOAG2022/README.md).

On 2022-12-08 I was guest at the [PowerShell UserGroup Inn-Salzach](https://www.meetup.com/de-DE/PowerShell-UserGroup-Inn-Salzach), you find the demo code and a link to the video on YouTube in the folder [PSUG](./PSUG/README.md).

On 2022-12-12 I held a workshop day at the [IT-Tage](https://www.ittage.informatik-aktuell.de/programm/2022/sql-server-powershell-fuer-datenbank-admins-dba.html), you find the demos in the folder [IT-Tage2022](./IT-Tage2022/README.md).


## History

It all began with a windows based lab. I learned how to install and configure the different database systems from a command line. It worked quite well, but even though I only used the free versions of the database systems, not all the programs I needed could be easily downloaded from the internet. So it was not completely "infrastructure-as-code".

Next step was to use docker containers, as I was able to get docker images for all the different database systems without having to log in anywhere. As Docker Desktop it not completly free anymore, I also moved to Linux based on WSL2 on my windows 11 maschine. Resetting the WSL2 was easy but still not a one click action as I had to enter username and password followd by configuring the networking.

I then used the PowerShell module AutomatedLab to set up my labs, as it also installs Linux systems without interaction. But the used Linux version was too old and the repository was shut down. So this part needs some updates - but I don't have time for that. If you could help, please contact me.

On the client side, I used three different sources to get the needed DLL for .NET: Vendor-provided clients (like the Oracle Client), third-party-provided clients (like those from DevArt), and NuGet packages. All three work very well, but there are small differences so the code has to be slightly adusted.

I now use only NuGet packages to have a common source for all database systems that is completely "infrastructure-as-code" based on publicly available software.

To reduce the repository but also keep the old version availably I decided to publish a release in january 2023 and afterwards remove these parts of the code:
* How to install database servers on a windows system
* How to use third-party-provided clients (like those from DevArt)
* How to use the new namespace Microsoft.Data.SqlClient instead of System.Data.SqlClient for SQL Server - because it is not easy to install the needed DLLs
* How to use dbatools for SQL Server - because I want the same interface and naming conventions for all databases

Please browse the [tag 2023-01](https://github.com/andreasjordan/PowerShell-for-DBAs/tree/2023-01) of this repository to see all the details.
