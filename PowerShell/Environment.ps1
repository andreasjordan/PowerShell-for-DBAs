$ErrorActionPreference = 'Stop'

# The following two variables will be used in other scripts like all the Server.ps1 to run the installation from the client computer.

# The name of the computer where all the database management software will be installed.
$serverComputerName = 'SQLLAB08'

# The credential of a domain user that has administrative rights on the target server ($serverComputerName).
$windowsAdminCredential = Get-Credential -Message "Account to connect to target server with CredSSP" -UserName "$env:USERDOMAIN\$env:USERNAME"

# Test CredSSP
try {
    $null = Invoke-Command -ComputerName $serverComputerName -Credential $windowsAdminCredential -Authentication Credssp -ScriptBlock { $true }
} catch {
    Write-Warning -Message "Failed to connect to [$serverComputerName] as [$($windowsAdminCredential.UserName)] with CredSSP: $_"
}

# Setting up CredSSP is currently out of scope of this script...
