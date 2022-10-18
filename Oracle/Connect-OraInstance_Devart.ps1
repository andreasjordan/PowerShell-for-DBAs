function Connect-OraInstance {
    [CmdletBinding()]
    [OutputType([Devart.Data.Oracle.OracleConnection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [switch]$AsSysdba,
        [switch]$PooledConnection,
        [switch]$EnableException
    )

    Write-Verbose -Message "Creating connection to instance [$Instance]"

    $csb = [Devart.Data.Oracle.OracleConnectionStringBuilder]::new()
    $csb.Server = $Instance
    $csb.UserId = $Credential.UserName
    $csb.Password = $Credential.GetNetworkCredential().Password
    if ($PooledConnection) {
        Write-Verbose -Message "Using connection pooling"
        $csb.Pooling = $true
    } else {
        Write-Verbose -Message "Disabling connection pooling"
        $csb.Pooling = $false
    }
    $csb.Unicode = $true   # To be able to use UTF8 data
    $connection = [Devart.Data.Oracle.OracleConnection]::new($csb.ConnectionString)
    if ($AsSysdba) {
        Write-Verbose -Message "Changing ConnectMode to SysDba"
        $connection.ConnectMode = [Devart.Data.Oracle.OracleConnectMode]::SysDba
    }

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
