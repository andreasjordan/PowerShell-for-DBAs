$ErrorActionPreference = 'Stop'

# The following variables will be used in other scripts like all the Server.ps1 to run the installation from the client computer.

# The path to base directory for the database management software installation files.
# Under that path, there has to be a seperate directory for every dbms used: SQLServer, Oracle, PostgreSQL, MySQL, Db2, Informix
if (-not $EnvironmentSoftwareBase) {
    $EnvironmentSoftwareBase = '\\fs\Software'
}

# The name of the computer where all the database management software will be installed.
if (-not $EnvironmentServerComputerName) {
    $EnvironmentServerComputerName = 'SQLLAB08'
}

# The credential of a domain user that has administrative rights on the target server ($serverComputerName).
if (-not $EnvironmentWindowsAdminCredential) {
    $EnvironmentWindowsAdminCredential = Get-Credential -Message "Account to connect to target server with CredSSP" -UserName "$env:USERDOMAIN\$env:USERNAME"
}

# Test CredSSP
# Setting up CredSSP is currently out of scope of this script...
try {
    $null = Invoke-Command -ComputerName $EnvironmentServerComputerName -Credential $EnvironmentWindowsAdminCredential -Authentication Credssp -ScriptBlock { $true }
} catch {
    Write-Warning -Message "Failed to connect to [$EnvironmentServerComputerName] as [$($EnvironmentWindowsAdminCredential.UserName)] with CredSSP: $_"
}

# As this is just a lab, set some simple passwords for the used database accounts
if (-not $EnvironmentDatabaseAdminPassword) {
    $EnvironmentDatabaseAdminPassword = 'start123'
}
if (-not $EnvironmentDatabaseUserPassword) {
    $EnvironmentDatabaseUserPassword = 'start456'
}
