function Connect-SqlInstance {
    [CmdletBinding()]
    [OutputType([Microsoft.Data.SqlClient.SqlConnection])]
    param (
        [Parameter(Mandatory)][string]$Instance,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [string]$Database,
        [switch]$PooledConnection,
        [switch]$EnableException
    )

    Write-Verbose -Message "Creating connection to instance [$Instance]"

    $csb = [Microsoft.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $csb['Data Source'] = $Instance
    $csb['User ID'] = $Credential.UserName
    $csb.Password = $Credential.GetNetworkCredential().Password
    $csb['Initial Catalog'] = $Database
    if ($PooledConnection) {
        Write-Verbose -Message "Using connection pooling"
        $csb.Pooling = $true
    } else {
        Write-Verbose -Message "Disabling connection pooling"
        $csb.Pooling = $false
    }
    $connection = [Microsoft.Data.SqlClient.SqlConnection]::new($csb.ConnectionString)

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
