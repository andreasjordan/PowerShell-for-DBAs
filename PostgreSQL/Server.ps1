$ErrorActionPreference = 'Stop'

<#

Documentation for silent installation:
https://silentinstallhq.com/postgresql-12-silent-install-how-to-guide/

Page for manual download:
https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
https://sbp.enterprisedb.com/getfile.jsp?fileid=1258170

#>

$softwarePostgreSQL = [PSCustomObject]@{
    DownloadUrl  = 'https://sbp.enterprisedb.com/getfile.jsp?fileid=1258170'
    ExeFile      = '\\fs\Software\PostgreSQL\postgresql-14.5-1-windows-x64.exe'
    Sha256       = 'E91B3AA882A0AF54FDA36043F492252E472C878904E2C3D92E6C799C33E75DEA'
    ComputerName = 'SQLLAB08'
    Credential   = Get-Credential -Message "Account to connect to target server with CredSSP" -UserName "$env:USERDOMAIN\$env:USERNAME"
    Parameters   = @{
        prefix           = 'D:\PostgreSQL\14'
        datadir          = 'D:\PostgreSQL\14\data'
        mode             = 'unattended'
        unattendedmodeui = 'none'
        servicename      = 'postgresql'
        serviceaccount   = 'postgresql'
        servicepassword  = 'start123'
        superpassword    = 'start123'
    }
}


# Download software if needed

if (-not (Test-Path -Path $softwarePostgreSQL.ExeFile)) {
    Invoke-WebRequest -Uri $softwarePostgreSQL.DownloadUrl -UseBasicParsing -OutFile $softwarePostgreSQL.ExeFile
}


# Test for correct cecksum

if ((Get-FileHash -Path $softwarePostgreSQL.ExeFile -Algorithm SHA256).Hash -ne $softwarePostgreSQL.Sha256) {
    throw "Checksum does not match"
}


# Install software

$argumentList = @( )
foreach ($key in $softwarePostgreSQL.Parameters.Keys) {
    $argumentList += "--$key"
    $argumentList += $softwarePostgreSQL.Parameters.$key
}

$scriptBlock = {
    Param  (
        $Path,
        $ArgumentList
    )
    $output = [PSCustomObject]@{
        Successful       = $false
        StdOut           = $null
        StdErr           = $null
        ExitCode         = $null
    }
    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processStartInfo.FileName = $Path
    if ($ArgumentList) {
        $processStartInfo.Arguments = $ArgumentList
    }
    $processStartInfo.UseShellExecute = $false # This is critical for installs to function on core servers
    $processStartInfo.CreateNoWindow = $true
    $processStartInfo.RedirectStandardError = $true
    $processStartInfo.RedirectStandardOutput = $true
    $ps = New-Object System.Diagnostics.Process
    $ps.StartInfo = $processStartInfo
    $started = $ps.Start()
    if ($started) {
        $stdOut = $ps.StandardOutput.ReadToEnd()
        $stdErr = $ps.StandardError.ReadToEnd()
        $ps.WaitForExit()
        # assign output object values
        $output.StdOut = $stdOut
        $output.StdErr = $stdErr
        $output.ExitCode = $ps.ExitCode
        # Check the exit code of the process to see if it succeeded.
        if ($ps.ExitCode -eq 0) {
            $output.Successful = $true
        }
        $output
    }
}

$params = @{
    ScriptBlock    = $scriptBlock
    ArgumentList   = @(
        $softwarePostgreSQL.ExeFile,
        $argumentList
    )
    ComputerName   = $softwarePostgreSQL.ComputerName
    Credential     = $softwarePostgreSQL.Credential
    Authentication = 'Credssp'
    ErrorAction    = 'Stop'
}

$output = Invoke-Command @params


# Test installation

if (-not $output.Successful) {
    $output
    throw "Installation failed"
}

if ((Get-Service -ComputerName $softwarePostgreSQL.ComputerName -Name $softwarePostgreSQL.Parameters.servicename).Count -ne 1) {
    throw "Installation failed"
}


# Setup Firewall

$cimSession = New-CimSession -ComputerName $softwarePostgreSQL.ComputerName

$firewallConfig = @{
    DisplayName = 'PostgreSQL'
    Name        = 'PostgreSQL'
    Group       = 'PostgreSQL'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    LocalPort   = '5432'
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$cimSession | Remove-CimSession



<# Remove PostgreSQL:

$params = @{
    ScriptBlock    = $scriptBlock
    ArgumentList   = @(
        'D:\PostgreSQL\14\uninstall-postgresql.exe',
        @(
            '--mode'
            'unattended'
            '--unattendedmodeui'
            'none'
        )
    )
    ComputerName   = $softwarePostgreSQL.ComputerName
    Credential     = $softwarePostgreSQL.Credential
    Authentication = 'Credssp'
    ErrorAction    = 'Stop'
}

$output = Invoke-Command @params
$output

Restart-Computer -ComputerName $softwarePostgreSQL.ComputerName

#>
