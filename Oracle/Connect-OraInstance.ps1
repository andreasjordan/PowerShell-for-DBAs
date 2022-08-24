function Connect-OraInstance {
    [CmdletBinding()]
    [OutputType([Oracle.ManagedDataAccess.Client.OracleConnection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [switch]$AsSysdba,
        [switch]$PooledConnection,
        [switch]$EnableException
    )

    Write-Verbose -Message "Creating basic connection string"
    $connectionString = "Data Source=$Instance;User Id=$($Credential.UserName);Password=$($Credential.GetNetworkCredential().Password);Pooling=$PooledConnection"
    if ($AsSysdba) {
        Write-Verbose -Message "Adding SYSDBA to connection string"
        $connectionString += ';DBA Privilege=SYSDBA'
    }
    Write-Verbose -Message $connectionString

    Write-Verbose -Message "Creating connection"
    $connection = [Oracle.ManagedDataAccess.Client.OracleConnection]::new($connectionString)
    
    try {
        Write-Verbose -Message "Opening connection"
        $connection.Open()
        
        Write-Verbose -Message "Returning connection object"
        $connection
    } catch {
        if ($EnableException) {
            throw
        } else {
            Write-Warning -Message "Connection could not be opened: $($_.Exception.InnerException.Message)"
        }
    }
}
