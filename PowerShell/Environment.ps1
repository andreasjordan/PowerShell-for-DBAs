$ErrorActionPreference = 'Stop'

# The following variables will be used in all the Client.ps1 and Application.ps1 to install the local clients and the sample application and data.
# The may also be used in other files using the sample application.

# The path to base directory for the database management software installation files.
# Under that path, there has to be a seperate directory for every dbms used: SQLServer, Oracle, PostgreSQL, MySQL, Db2, Informix
if (-not $EnvironmentSoftwareBase) {
    $EnvironmentSoftwareBase = '\\fs\Software'
}

# The name of the computer where all the database management software will be installed.
if (-not $EnvironmentServerComputerName) {
    $EnvironmentServerComputerName = 'SQLLAB08'
}

# The name of the user where all the sample tables will be installed.
if (-not $EnvironmentDatabaseUserName) {
    $EnvironmentDatabaseUserName = 'stackoverflow'
}

# As this is just a lab, set some simple passwords for the used database accounts
if (-not $EnvironmentDatabaseAdminPassword) {
    $EnvironmentDatabaseAdminPassword = 'start123'
}

if (-not $EnvironmentDatabaseUserPassword) {
    $EnvironmentDatabaseUserPassword = 'start456'
}
