How to use PowerShell as an Oracle database administrator.

## Install the server

I use the free express edition of Oracle 21c for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details.

The sample schema is currently not included, but will probably be in the future.


## Install the client

I use the Oracle Database 19c Client, as this is the last client with a working DLL. See my install script [Client.ps1](Client.ps1) in this folder for details.

The newer versions have a non-solvable dependency, see [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details.


## Install the wrapper commands

Download the two wrapper commands [Connect-OraInstance.ps1](Connect-OraInstance.ps1) and [Invoke-OraQuery.ps1](Invoke-OraQuery.ps1) in this folder and place them in a suitable location.


## Test connection with sample code

Download the sample code file [Sample.ps1](Sample.ps1) and try to connect to the Oracle database.
