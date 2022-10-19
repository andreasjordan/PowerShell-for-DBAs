function Connect-IfxInstance {
    [CmdletBinding()]
    [OutputType([Informix.Net.Core.IfxConnection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [Parameter(Mandatory)][string]$Database,
        [switch]$PooledConnection,
        [string]$Protocol = 'olsoctcp',
        [string]$ClientLocale = 'en_US.utf8',
        [string]$DbLocale = 'en_US.utf8',
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

    $csb = [Informix.Net.Core.IfxConnectionStringBuilder]::new()
    $csb.Host = $ifxHost
    $csb.Service = $ifxService
    $csb.Server = $ifxServer
    $csb.Protocol = $Protocol
    $csb.Database = $Database
    $csb['Client Locale'] = $ClientLocale
    $csb['Database Locale'] = $DbLocale
    $csb['User ID'] = $Credential.UserName
    $csb['Password'] = $Credential.GetNetworkCredential().Password
    if ($PooledConnection) {
        Write-Verbose -Message "Using connection pooling"
        $csb.Pooling = $true
    } else {
        Write-Verbose -Message "Disabling connection pooling"
        $csb.Pooling = $false
    }

    $connection = [Informix.Net.Core.IfxConnection]::new($csb.ConnectionString)

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
