[CmdletBinding()]
Param(
    [Parameter(Position = 0, Mandatory = $true)][string]$UserName,
    [Parameter(Position = 1, Mandatory = $true)][string]$Password,
    [Parameter(Position = 2, Mandatory = $false)][string]$Path = "$env:LOCALAPPDATA\OraCredential.xml"
)
$secureString = ConvertTo-SecureString -String $Password -AsPlainText -Force
$credential = [PSCredential]::new($UserName, $secureString)
$credential | Export-Clixml -Path $Path
