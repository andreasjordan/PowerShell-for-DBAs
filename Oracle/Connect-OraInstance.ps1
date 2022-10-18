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

    Write-Verbose -Message "Creating connection to instance [$Instance]"

    $csb = [Oracle.ManagedDataAccess.Client.OracleConnectionStringBuilder]::new()
    $csb['Data Source'] = $Instance
    $csb['User ID'] = $Credential.UserName
    $csb.Password = $Credential.GetNetworkCredential().Password
    if ($PooledConnection) {
        Write-Verbose -Message "Using connection pooling"
        $csb.Pooling = $true
    } else {
        Write-Verbose -Message "Disabling connection pooling"
        $csb.Pooling = $false
    }
    if ($AsSysdba) {
        Write-Verbose -Message "Adding SYSDBA to connection string"
        $csb['DBA Privilege'] = 'SYSDBA'
    }
    $connection = [Oracle.ManagedDataAccess.Client.OracleConnection]::new($csb.ConnectionString)
    
    try {
        Write-Verbose -Message "Opening connection"
        $connection.Open()
        
        Write-Verbose -Message "Returning connection object"
        $connection
    } catch {
        $message = "Connection failed: $($_.Exception.InnerException.Message)"
        if ($EnableException) {
            Write-Error -Message $message -TargetObject $connection -ErrorAction Stop
        } else {
            Write-Warning -Message $message
        }
    }
}
