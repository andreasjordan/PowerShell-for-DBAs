How to use PowerShell as an Oracle database administrator.

## Install the server

I use the free express edition of Oracle 21c for my labs. See my install script [Server.ps1](Server.ps1) in this folder for details on how to run an unattended installation from a remote computer.

But you can use any existing server in your environment.


## Install the client

I use the Oracle Database 19c Client, as this is the last client with a working DLL. See my install script [Client.ps1](Client.ps1) in this folder for details on how to run an unattended installation of only the needed components.

But can you also use other ways to install the client. If you are unsure what components to install, just install all of them. If the oracle client is automatically installed by a software distribution tool, test if the file "Oracle.ManagedDataAccess.dll" is present in the path "odp.net\managed\common" in your oracle home.

The newer versions have a non-solvable dependency, see [this discussion](https://community.oracle.com/tech/developers/discussion/4502297) for details.


## Install the application

I use a sample "application" (just a bunch of tables) that is based on the schema and data from the StackOverflow database.

See my script [Application.ps1](Application.ps1) in this folder for details.
