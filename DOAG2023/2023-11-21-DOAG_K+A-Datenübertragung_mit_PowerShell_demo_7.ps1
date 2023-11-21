$ErrorActionPreference = 'Stop'
Set-Location -Path C:\demo

Get-ChildItem -Path . -Filter *-*.ps1 | ForEach-Object -Process { . $_ }

$credential = Get-Credential -Message 'Datenbank-Benutzer' -UserName stackoverflow

Import-MyLibrary
$mySqlConnection = Connect-MyInstance -Instance 192.168.101.30 -Database stackoverflow -Credential $credential
$mariaDbConnection = Connect-MyInstance -Instance 192.168.101.30:13306 -Database stackoverflow -Credential $credential

"Connected to MySQL. Version: $($mySqlConnection.ServerVersion)"
Get-MyTableInformation -Connection $mySqlConnection | Format-Table

"Connected to MariaDB. Version: $($mariaDbConnection.ServerVersion)"
Get-MyTableInformation -Connection $mariaDbConnection | Format-Table


Import-OraLibrary
$oracleConnection = Connect-OraInstance -Instance DEMO -Credential $credential
"Connected to Oracle. Version: $($oracleConnection.ServerVersion)"


# Version 2: Invoke-MyQuery / Write-OraTable
############################################

$data = Invoke-MyQuery -Connection $mySqlConnection -Query "SELECT * FROM Badges"
#$data = Invoke-MyQuery -Connection $mariaDbConnection -Query "SELECT * FROM Badges"

Write-OraTable -Connection $oracleConnection -Table badges -Data $data -TruncateTable



# Version 3: Get-SqlTableInformation + Get-SqlTableReader / Write-OraTable
##########################################################################

#$tableInformation = Get-MyTableInformation -Connection $mySqlConnection -Table Badges
#$dataReader = Get-MyTableReader -Connection $mySqlConnection -Table Badges
$tableInformation = Get-MyTableInformation -Connection $mariaDbConnection -Table Badges
$dataReader = Get-MyTableReader -Connection $mariaDbConnection -Table Badges

$invokeWriteTableParams = @{
    Connection         = $oracleConnection
    Table              = 'badges'
    DataReader         = $dataReader
    DataReaderRowCount = $tableInformation.Rows
    TruncateTable      = $true
}
Write-OraTable @invokeWriteTableParams
