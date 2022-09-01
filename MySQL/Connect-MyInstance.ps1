function Connect-MyInstance {
    [CmdletBinding()]
    [OutputType([Devart.Data.MySql.MySqlConnection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [string]$Database,
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

    $csb = [Devart.Data.MySql.MySqlConnectionStringBuilder]::new()
    $csb.Pooling = $false
    $csb.Unicode = $true   # To be able to use UTF8 data
    $csb.Host = $myHost
    $csb.Port = $myPort
    $csb.UserId = $Credential.UserName
    $csb.Password = $Credential.GetNetworkCredential().Password
    if ($Database) {
        $csb.Database = $Database
    }

    $connection = [Devart.Data.MySql.MySqlConnection]::new($csb.ConnectionString)

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
