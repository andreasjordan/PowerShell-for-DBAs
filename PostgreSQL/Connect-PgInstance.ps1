function Connect-PgInstance {
    [CmdletBinding()]
    [OutputType([Devart.Data.PostgreSql.PgSqlConnection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [string]$Database,
        [switch]$EnableException
    )

    if ($Instance -match '^([^:]+):(\d+)$') {
        $pgHost = $Matches[1]
        $pgPort = $Matches[2]
    } else {
        $pgHost = $Instance
        $pgPort = 5432
    }

    Write-Verbose -Message "Creating connection to host [$pgHost] on port [$pgPort]"
    $connection = [Devart.Data.PostgreSql.PgSqlConnection]::new()
    $connection.Host = $pgHost
    $connection.Port = $pgPort
    $connection.UserId = $Credential.UserName
    $connection.Password = $Credential.GetNetworkCredential().Password

    if ($Database) {
        $connection.Database = $Database
    }

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
