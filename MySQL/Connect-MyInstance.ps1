function Connect-MyInstance {
    [CmdletBinding()]
    [OutputType([MySql.Data.MySqlClient.MySqlConnection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [string]$Database,
        [switch]$PooledConnection,
        [switch]$EnableException
    )

    if ($Instance -match '^([^:]+):(\d+)$') {
        $myHost = $Matches[1]
        $myPort = $Matches[2]
    } else {
        $myHost = $Instance
        $myPort = 3306
    }

    Write-Verbose -Message "Creating connection to host [$myHost] on port [$myPort]"

    $csb = [MySql.Data.MySqlClient.MySqlConnectionStringBuilder]::new()
    $csb.Server = $myHost
    $csb.Port = $myPort
    $csb.UserID = $Credential.UserName
    $csb.Password = $Credential.GetNetworkCredential().Password
    if ($Database) {
        $csb.Database = $Database
    }
    if ($PooledConnection) {
        Write-Verbose -Message "Using connection pooling"
        $csb.Pooling = $true
    } else {
        Write-Verbose -Message "Disabling connection pooling"
        $csb.Pooling = $false
    }
    # $csb.CharacterSet = 'UTF8'   # To be able to use UTF8 data

    $connection = [MySql.Data.MySqlClient.MySqlConnection]::new($csb.ConnectionString)

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
