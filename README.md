# PowerShell for DBAs
How to use PowerShell as a database administrator.

I don't want to build a product or module. I want to provide a proof of concept, a tutorial, a code example, maybe a guide or a source of ideas for your own implementation. 

This is about using publicly available software (like database clients or NuGet packages) and a few lines of PowerShell code to show database administrators how to work with PowerShell. 

The basic idea is to install the .NET driver for the specific database management software and use the included DLL in PowerShell. Two PowerShell commands with a few lines of code wrap up the use of the required classes: One to open the connection, the other to execute queries. Other commands are possible, maybe there will be ideas about that here too.

Today I work exclusively with Windows, so this can all be installed on a single Windows server or a small lab with Windows systems. But my plan is to implement this later on Linux with PowerShell Core.
