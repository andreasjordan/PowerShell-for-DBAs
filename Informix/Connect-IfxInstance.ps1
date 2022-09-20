function Connect-IfxInstance {
    [CmdletBinding()]
    [OutputType([IBM.Data.Informix.IfxConnection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [Parameter(Mandatory)][string]$Database,
        [switch]$PooledConnection,
        [string]$Protocol = 'olsoctcp',
        [switch]$EnableException
    )

    if ($Instance -match '^([^:]+):(\d+):([^:]+)$') {
        $ifxHost = $Matches[1]
        $ifxService = $Matches[2]
        $ifxServer = $Matches[3]
    } else {
        if ($EnableException) {
            throw "Instance does not contain <Host>:<Service>:<Server>"
        } else {
            Write-Warning -Message "Instance does not contain <Host>:<Service>:<Server>"
        }
    }

    Write-Verbose -Message "Creating connection to server [$Instance] and database [$Database]"

    $csb = [IBM.Data.Informix.IfxConnectionStringBuilder]::new()

    $csb.Host = $ifxHost
    $csb.Service = $ifxService
    $csb.Server = $ifxServer
    $csb.Protocol = $Protocol
    $csb.Database = $Database
    $csb['User ID'] = $Credential.UserName
    $csb['Password'] = $Credential.GetNetworkCredential().Password
    if ($PooledConnection) {
        Write-Verbose -Message "Using connection pooling"
        $csb.Pooling = $true
    } else {
        Write-Verbose -Message "Disabling connection pooling"
        $csb.Pooling = $false
    }

    $connection = [IBM.Data.Informix.IfxConnection]::new($csb.ConnectionString)

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
