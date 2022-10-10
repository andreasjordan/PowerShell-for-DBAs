function Connect-SqlInstance {
    [CmdletBinding()]
    [OutputType([Microsoft.SqlServer.Management.Smo.Server])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [string]$Database,
        [switch]$PooledConnection,
        [switch]$EnableException
    )

    Write-Verbose -Message "Creating connection to instance [$Instance]"

    $sqlConnectionInfo = [Microsoft.SqlServer.Management.Common.SqlConnectionInfo]::new($Instance)
    $sqlConnectionInfo.UserName = $Credential.UserName
    $sqlConnectionInfo.SecurePassword = $Credential.Password
    if ($Database) {
        $sqlConnectionInfo.DatabaseName = $Database
    }
    if ($PooledConnection) {
        Write-Verbose -Message "Using connection pooling"
        $sqlConnectionInfo.Pooled = $true
    } else {
        Write-Verbose -Message "Disabling connection pooling"
        $sqlConnectionInfo.Pooled = $false
    }
    $serverConnection = [Microsoft.SqlServer.Management.Common.ServerConnection]::new($sqlConnectionInfo)
    $server = [Microsoft.SqlServer.Management.Smo.Server]::new($serverConnection)

    try {
        Write-Verbose -Message "Opening connection"
        $null = $server.ConnectionContext.ExecuteWithResults("SELECT 1")
        
        Write-Verbose -Message "Returning server object"
        $server
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Connection could not be opened: $($_.Exception.InnerException.Message)"
        }
    }
}
