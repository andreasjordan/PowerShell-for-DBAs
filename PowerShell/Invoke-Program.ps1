# Command to run programms on a remote computer
# It is used to silently install the database management software

# Based on:
# https://github.com/dataplat/dbatools/blob/development/internal/functions/Invoke-Program.ps1
# https://github.com/adbertram/PSSqlUpdater/blob/master/SqlUpdater.ps1

function Invoke-Program {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [Parameter()]
        [string]$ComputerName,

        [Parameter()]
        [pscredential]$Credential,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$ArgumentList,

        [Parameter()]
        [bool]$ExpandStrings = $false,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$WorkingDirectory,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [uint32[]]$SuccessReturnCodes = @( 0 )
    )
    process    {
        try {
            $icmParams = @{ }

            if ($PSBoundParameters.ContainsKey('Session')) {
                Write-Verbose -Message "Using session to [$($Session.ComputerName)]"

                $icmParams.Session = $Session
                $ComputerName = $Session.ComputerName
            } elseif ($PSBoundParameters.ContainsKey('ComputerName')) {
                Write-Verbose -Message "Using ComputerName [$ComputerName]"

                $icmParams.ComputerName = $ComputerName
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    Write-Verbose -Message "Using Credential for [$($Credential.UserName)] and CredSSP as Authentication"

                    $icmParams.Credential = $Credential    
                    $icmParams.Authentication = 'CredSSP'
                }
            } else {
                Write-Verbose -Message "Running program on localhost"
            }

            Write-Verbose -Message "Acceptable success return codes are [$($SuccessReturnCodes -join ',')]"
            
            $icmParams.ArgumentList = @(
                $FilePath,
                $ArgumentList,
                $ExpandStrings,
                $WorkingDirectory,
                $SuccessReturnCodes
            )
            $icmParams.ScriptBlock = {
                param (
                    [string]$FilePath,
                    [string[]]$ArgumentList,
                    [bool]$ExpandStrings,
                    [string]$WorkingDirectory,
                    [uint32[]]$SuccessReturnCodes
                )

                $output = [PSCustomObject]@{
                    ComputerName     = $env:COMPUTERNAME
                    FilePath         = $FilePath
                    ArgumentList     = $ArgumentList
                    WorkingDirectory = $WorkingDirectory
                    Successful       = $false
                    StdOut           = $null
                    StdErr           = $null
                    ExitCode         = $null
                    Exception        = $null
                }

                try {
                    $processStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
                    $processStartInfo.FileName = $FilePath
                    if ($ArgumentList) {
                        $processStartInfo.Arguments = $ArgumentList
                        if ($ExpandStrings) {
                            $processStartInfo.Arguments = $ExecutionContext.InvokeCommand.ExpandString($ArgumentList)
                            $output.ArgumentList = $processStartInfo.Arguments
                        }
                    }
                    if ($WorkingDirectory) {
                        $processStartInfo.WorkingDirectory = $WorkingDirectory
                        if ($ExpandStrings) {
                            $processStartInfo.WorkingDirectory = $ExecutionContext.InvokeCommand.ExpandString($WorkingDirectory)
                            $output.WorkingDirectory = $processStartInfo.WorkingDirectory
                        }
                    }
                    $processStartInfo.UseShellExecute = $false; # This is critical for installs to function on core servers
                    $processStartInfo.CreateNoWindow = $true
                    $processStartInfo.RedirectStandardOutput = $true                    
                    $processStartInfo.RedirectStandardError = $true

                    $process = [System.Diagnostics.Process]::new()
                    $process.StartInfo = $processStartInfo

                    Write-Verbose -Message "Starting process with FileName [$($processStartInfo.FileName)], Arguments [$($processStartInfo.Arguments)] and WorkingDirectory [$($processStartInfo.WorkingDirectory)]"
                    $started = $process.Start()
                    if ($started) {
                        $stdOut = $process.StandardOutput.ReadToEnd()
                        $stdErr = $process.StandardError.ReadToEnd()
                        $process.WaitForExit()

                        $output.StdOut = $stdOut
                        $output.StdErr = $stdErr
                        $output.ExitCode = $process.ExitCode

                        if ($process.ExitCode -in $SuccessReturnCodes) {
                            $output.Successful = $true
                        }
                    }
                } catch {
                    $output.Exception = $_
                } finally {
                    $output
                }
            }
            
            Write-Verbose -Message "Running command line [$FilePath $ArgumentList] on $ComputerName"
            Invoke-Command @icmParams
        } catch {
            [PSCustomObject]@{
                ComputerName     = $ComputerName
                FilePath         = $FilePath
                ArgumentList     = $ArgumentList
                WorkingDirectory = $WorkingDirectory
                Successful       = $false
                Exception        = $_
            }
        }
    }
}
