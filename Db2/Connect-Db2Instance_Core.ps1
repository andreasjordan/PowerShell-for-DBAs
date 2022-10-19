function Connect-Db2Instance {
    [CmdletBinding()]
    [OutputType([IBM.Data.DB2.Core.DB2Connection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [Parameter(Mandatory)][string]$Database,
        [switch]$PooledConnection,
        [switch]$EnableException
    )

    Write-Verbose -Message "Creating connection to server [$Instance] and database [$Database]"

    $csb = [IBM.Data.DB2.Core.DB2ConnectionStringBuilder]::new()
    $csb.Server = $Instance
    $csb.Database = $Database
    $csb.UserID = $Credential.UserName
    $csb.Password = $Credential.GetNetworkCredential().Password
    if ($PooledConnection) {
        Write-Verbose -Message "Using connection pooling"
        $csb.Pooling = $true
    } else {
        Write-Verbose -Message "Disabling connection pooling"
        $csb.Pooling = $false
    }

    $connection = [IBM.Data.DB2.Core.DB2Connection]::new($csb.ConnectionString)

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
