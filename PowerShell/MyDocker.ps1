function Invoke-MyProgram {
    [CmdletBinding()]
    Param(
        [string]$Path,
        [string[]]$ArgumentList,
        [bool]$ExpandStrings = $false,
        [string]$WorkingDirectory = '.',
        [int[]]$SuccessReturnCode = 0
    )

    $output = [PSCustomObject]@{
        Path             = $Path
        ArgumentList     = $ArgumentList
        WorkingDirectory = $WorkingDirectory
        Successful       = $false
        StdOut           = $null
        StdErr           = $null
        ExitCode         = $null
    }
    $processStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $processStartInfo.FileName = $Path
    if ($ArgumentList) {
        $processStartInfo.Arguments = $ArgumentList
        if ($ExpandStrings) {
            $processStartInfo.Arguments = $ExecutionContext.InvokeCommand.ExpandString($ArgumentList)
        }
    }
    if ($WorkingDirectory) {
        $processStartInfo.WorkingDirectory = $WorkingDirectory
        if ($ExpandStrings) {
            $processStartInfo.WorkingDirectory = $ExecutionContext.InvokeCommand.ExpandString($WorkingDirectory)
        }
    }
    $processStartInfo.UseShellExecute = $false # This is critical for installs to function on core servers
    $processStartInfo.CreateNoWindow = $true
    $processStartInfo.RedirectStandardError = $true
    $processStartInfo.RedirectStandardOutput = $true
    $ps = [System.Diagnostics.Process]::new()
    $ps.StartInfo = $processStartInfo
    $started = $ps.Start()
    if ($started) {
        $stdOut = $ps.StandardOutput.ReadToEnd()
        $stdErr = $ps.StandardError.ReadToEnd()
        $ps.WaitForExit()
        # assign output object values
        $output.StdOut = $stdOut -split [System.Environment]::NewLine
        $output.StdErr = $stdErr -split [System.Environment]::NewLine
        $output.ExitCode = $ps.ExitCode
        # Check the exit code of the process to see if it succeeded.
        if ($ps.ExitCode -in $SuccessReturnCode) {
            $output.Successful = $true
        }
    }
    $output
}


function Invoke-MyDocker {
    [CmdletBinding()]
    Param(
        [string[]]$ArgumentList,
        [switch]$RawOutput,
        [switch]$EnableException
    )

    if ($Env:USE_SUDO) {
        $ArgumentList = 'docker', $ArgumentList
        $result = Invoke-MyProgram -Path 'sudo' -ArgumentList $ArgumentList
    } else {
        $result = Invoke-MyProgram -Path 'docker' -ArgumentList $ArgumentList
    }

    if ($result.Successful) {
        if ($RawOutput) {
            $result
        } else {
            $result.StdOut.TrimEnd()
        }
    } else {
        if ($EnableException) {
            throw $result.StdErr
        } else {
            Write-Warning -Message $result.StdErr
        }
    }
}


function Get-MyDockerNetwork {
    [CmdletBinding()]
    Param(
        [string[]]$Name,
        [switch]$EnableException
    )

    try {
        $networkNames = Invoke-MyDocker -ArgumentList network, ls, '--format "{{.Name}}"' -EnableException
        $networks = Invoke-MyDocker -ArgumentList network, inspect, $networkNames -EnableException | ConvertFrom-Json
    
        if ($Name) {
            $networks = $networks | Where-Object Name -in $Name
        }
        
        $networks
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Getting docker network failed: $_"
        }
    }
}


function New-MyDockerNetwork {
    [CmdletBinding()]
    Param(
        [string]$Name,
        [switch]$EnableException
    )

    try {
        $null = Invoke-MyDocker -ArgumentList network, create, $Name -EnableException
        Invoke-MyDocker -ArgumentList network, inspect, $Name -EnableException | ConvertFrom-Json
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Creating docker network failed: $_"
        }
    }
}


function Remove-MyDockerNetwork {
    [CmdletBinding()]
    Param(
        [string]$Name,
        [switch]$EnableException
    )

    try {
        $null = Invoke-MyDocker -ArgumentList network, rm, $Name -EnableException
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Removing docker network failed: $_"
        }
    }
}


function Get-MyDockerContainer {
    [CmdletBinding()]
    Param(
        [string[]]$Name,
        [switch]$EnableException
    )

    try {
        $containerNames = Invoke-MyDocker -ArgumentList container, ls, '-a', '--format "{{.Names}}"' -EnableException
        if ($containerNames) {
            $container = Invoke-MyDocker -ArgumentList container, inspect, $containerNames -EnableException | ConvertFrom-Json

            if ($Name) {
                $container = $container | Where-Object { $_.Name.TrimStart('/') -in $Name }
            }
            
            $container
        }
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Getting docker container failed: $_"
        }
    }
}


function New-MyDockerContainer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Image,
        [string]$Network,
        [string]$Memory,
        [string[]]$Port,
        [string[]]$Volume,
        [string[]]$Environment,
        [switch]$Interactive,
        [switch]$Privileged,
        [switch]$EnableException
    )

    $argumentList = "run", "--name", $Name
    if ($Network) {
        $argumentList += "--network=$Network"
    }
    if ($Memory) {
        $argumentList += "--memory=$Memory"
    }
    foreach ($p in $Port) {
        $argumentList += "-p", $p
    }
    foreach ($v in $Volume) {
        $argumentList += "-v", $v
    }
    foreach ($e in $Environment) {
        $argumentList += "-e", $e
    }
    if ($Interactive) {
        $argumentList += "--interactive"
    }
    if ($Privileged) {
        $argumentList += "--privileged=true"
    }
    $argumentList += '--detach', $Image
    Write-Verbose -Message "Creating docker container with: $($argumentList -join ' ')"

    try {
        $null = Invoke-MyDocker -ArgumentList $argumentList -EnableException
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Creating docker container failed: $_"
        }
    }
}


function Start-MyDockerContainer {
    [CmdletBinding()]
    Param(
        [string[]]$Name,
        [switch]$EnableException
    )

    try {
        $null = Invoke-MyDocker -ArgumentList container, start, $Name -EnableException
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Starting docker container failed: $_"
        }
    }
}


function Stop-MyDockerContainer {
    [CmdletBinding()]
    Param(
        [string[]]$Name,
        [int]$Timeout = 10,
        [switch]$EnableException
    )

    try {
        $null = Invoke-MyDocker -ArgumentList container, stop, '--time', $Timeout, $Name -EnableException
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Starting docker container failed: $_"
        }
    }
}


function Remove-MyDockerContainer {
    [CmdletBinding()]
    Param(
        [string[]]$Name,
        [switch]$Force,
        [switch]$EnableException
    )

    $options = @('--volumes')
    if ($Force) {
        $options += '--force'
    }
    try {
        $null = Invoke-MyDocker -ArgumentList container, rm, $options, $Name -EnableException
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Removing docker container failed: $_"
        }
    }
}


function Invoke-MyDockerContainer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Shell,
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Environment,
        [switch]$EnableException
    )

    $argumentList = "exec", "--interactive"
    foreach ($e in $Environment) {
        $argumentList += "-e", $e
    }
    $Command = '"' + $Command.Replace('"', '""') + '"'
    $argumentList += $Name, $Shell, '-c', $Command
    Write-Verbose -Message "Running command inside docker container with: $($argumentList -join ' ')"

    try {
        Invoke-MyDocker -ArgumentList $argumentList -EnableException
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Running command inside docker container failed: $_"
        }
    }
}


function Wait-MyDockerContainer {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$LogRegex,
        [int]$Timeout = 600,
        [switch]$EnableException
    )

    $timeoutTime = [datetime]::Now.AddSeconds($Timeout)
    try {
        while (1) {
            $logs = Invoke-MyDocker -ArgumentList logs, $Name -RawOutput -EnableException
            if ($logs.StdOut -match $LogRegex -or $logs.StdErr -match $LogRegex) { 
                break
            } elseif ([datetime]::Now -gt $timeoutTime) {
                throw "Timeout reached"
            }
            Start-Sleep -Seconds 1
        }
        # Just to be save, we wait additional 5 seconds
        Start-Sleep -Seconds 5
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Waiting failed: $_"
        }
    }
}
