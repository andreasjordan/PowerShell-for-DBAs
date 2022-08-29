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
		[string]$ComputerName = 'localhost',

		[Parameter()]
		[pscredential]$Credential,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$FilePath,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string[]]$ArgumentList,

		[Parameter()]
		[switch]$ExpandStrings,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$WorkingDirectory,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[uint32[]]$SuccessReturnCodes = @( 0 )
	)
	process	{
		try {
            if ($PSBoundParameters.ContainsKey('Session')) {
    			Write-Verbose -Message "Using session to [$($Session.ComputerName)]"

			    $icmParams = @{
				    Session = $Session
			    }
                $ComputerName = $Session.ComputerName
            } else {
    			Write-Verbose -Message "Using ComputerName [$ComputerName]"

			    $icmParams = @{
				    ComputerName = $ComputerName
			    }

			    if ($PSBoundParameters.ContainsKey('Credential')) {
        			Write-Verbose -Message "Using Credential for [$($Credential.UserName)] and CredSSP as Authentication"

				    $icmParams.Credential = $Credential	
			        $icmParams.Authentication = 'CredSSP'
			    }
            }

			Write-Verbose -Message "Acceptable success return codes are [$($SuccessReturnCodes -join ',')]"
			
			$icmParams.ScriptBlock = {
				$VerbosePreference = $using:VerbosePreference

                $output = [PSCustomObject]@{
                    ComputerName     = $env:COMPUTERNAME
                    FilePath         = $using:FilePath
                    ArgumentList     = $using:ArgumentList
                    WorkingDirectory = $using:WorkingDirectory
                    Successful       = $false
                    StdOut           = $null
                    StdErr           = $null
                    ExitCode         = $null
                    Exception        = $null
                }

				try {
					$processStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
					$processStartInfo.FileName = $using:FilePath
					if ($using:ArgumentList) {
						$processStartInfo.Arguments = $using:ArgumentList
						if ($using:ExpandStrings) {
							$processStartInfo.Arguments = $ExecutionContext.InvokeCommand.ExpandString($using:ArgumentList)
                            $output.ArgumentList = $processStartInfo.Arguments
						}
					}
					if ($using:WorkingDirectory) {
						$processStartInfo.WorkingDirectory = $using:WorkingDirectory
						if ($Using:ExpandStrings) {
							$processStartInfo.WorkingDirectory = $ExecutionContext.InvokeCommand.ExpandString($using:WorkingDirectory)
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

                        if ($process.ExitCode -in $using:SuccessReturnCodes) {
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
