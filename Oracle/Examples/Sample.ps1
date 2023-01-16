$ErrorActionPreference = 'Stop'

$oracleHome = 'D:\oracle\product\19.0.0\client_1'
$cmdPath = '.'

Add-Type -Path "$oracleHome\odp.net\managed\common\Oracle.ManagedDataAccess.dll"
. "$cmdPath\Connect-OraInstance.ps1"
. "$cmdPath\Invoke-OraQuery.ps1"

$instance = 'SQLLAB08/XEPDB1'
$credential = Get-Credential -Message $instance -UserName sys  # start123

$connection = Connect-OraInstance -Instance $instance -Credential $credential -AsSysdba

$query = 'SELECT * FROM v$parameter'

$data = Invoke-OraQuery -Connection $connection -Query $query

$data | Out-GridView -Title $query

$connection.Close()
$connection.Dispose()
