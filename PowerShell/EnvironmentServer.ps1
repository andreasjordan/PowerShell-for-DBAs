$ErrorActionPreference = 'Stop'

# The following variables will be used in all the Server.ps1 to run the installation from the client computer.
# They are not needed to install the local clients or the sample application and data.

# The credential of a domain user that has administrative rights on the target server ($serverComputerName).
if (-not $EnvironmentWindowsAdminCredential) {
    $EnvironmentWindowsAdminCredential = Get-Credential -Message "Account to connect to target server with CredSSP" -UserName "$env:USERDOMAIN\$env:USERNAME"
}

# Test CredSSP
# Setting up CredSSP is currently out of scope of this script...
# But on the client you would need to execute in an admin PowerShell: $null = Enable-WSManCredSSP -DelegateComputer $EnvironmentServerComputerName -Role Client -Force
try {
    $null = Invoke-Command -ComputerName $EnvironmentServerComputerName -Credential $EnvironmentWindowsAdminCredential -Authentication Credssp -ScriptBlock { $true }
} catch {
    Write-Warning -Message "Failed to connect to [$EnvironmentServerComputerName] as [$($EnvironmentWindowsAdminCredential.UserName)] with CredSSP: $_"
}
