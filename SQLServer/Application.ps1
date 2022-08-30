$ErrorActionPreference = 'Stop'

Import-Module -Name dbatools  # Install-Module -Name dbatools -Scope CurrentUser

. ..\PowerShell\Environment.ps1
. ..\PowerShell\Import-Schema.ps1

$instance = "$serverComputerName\SQLEXPRESS"

$credentialAdmin = Get-Credential -Message $instance -UserName sa             # start123
$credentialUser  = Get-Credential -Message $instance -UserName stackoverflow  # start456

$connectionAdmin = Connect-DbaInstance -SqlInstance $instance -SqlCredential $credentialAdmin -NonPooledConnection

$null = Remove-DbaDatabase -SqlInstance $connectionAdmin -Database stackoverflow -Confirm:$false
$null = Remove-DbaLogin -SqlInstance $connectionAdmin -Login stackoverflow -Confirm:$false

$null = New-DbaLogin -SqlInstance $connectionAdmin -Login stackoverflow -SecurePassword $credentialUser.Password
$null = New-DbaDatabase -SqlInstance $connectionAdmin -Name stackoverflow -Owner stackoverflow

$null = $connectionAdmin | Disconnect-DbaInstance


$connectionUser = Connect-DbaInstance -SqlInstance $instance -SqlCredential $credentialUser -Database stackoverflow -NonPooledConnection

$schema = Import-Schema -Path ..\PowerShell\Schema.psd1 -DBMS SQLServer
foreach ($query in $schema) {
    Invoke-DbaQuery -SqlInstance $connectionUser -Query $query
}

$data = Get-Content -Path ..\PowerShell\SampleData.json -Encoding UTF8 | ConvertFrom-Json
$tableNames = $data.PSObject.Properties.Name | Sort-Object

$progressTableParameter = @{ Id = 1 ; Activity = 'Importing tables' }
$progressTableTotal = $tableNames.Count
$progressTableCompleted = 0 

foreach ($tableName in $tableNames) {
    $progressTableParameter.Status = "$progressTableCompleted of $progressTableTotal tables completed"
    $progressTableParameter.CurrentOperation = "processing table $tableName"
    Write-Progress @progressTableParameter
    $progressTableCompleted++

    $insertIntoSql1 = "INSERT INTO $tableName ("
    $insertIntoSql2 = " VALUES ("
    $columNames = ($data.$tableName | Select-Object -First 1).PSObject.Properties.Name
    foreach ($columnName in $columNames) {
        $insertIntoSql1 += "$columnName, "
        $insertIntoSql2 += "@$columnName, "
    }
    $insertIntoSql1 = $insertIntoSql1.TrimEnd(', ') + ')'
    $insertIntoSql2 = $insertIntoSql2.TrimEnd(', ') + ')'
    $insertIntoSql = $insertIntoSql1 + $insertIntoSql2

    $progressRowParameter = @{ Id = 2 ; Activity = 'Importing rows' }
    $progressRowTotal = $data.$tableName.Count
    $progressRowCompleted = 0 
    $progressRowStart = Get-Date

    foreach ($row in $data.$tableName) {
        if ($progressRowCompleted % 100 -eq 0) {
            $progressRowParameter.Status = "$progressRowCompleted of $progressRowTotal rows completed"
            $progressRowParameter.PercentComplete = $progressRowCompleted * 100 / $progressRowTotal
            if ($progressRowParameter.PercentComplete -gt 0) {
                $progressRowParameter.SecondsRemaining = ((Get-Date) - $progressRowStart).TotalSeconds / $progressRowParameter.PercentComplete * (100 - $progressRowParameter.PercentComplete)
                $progressRowParameter.Status += " ($([int]($progressRowCompleted / ((Get-Date) - $progressRowStart).TotalSeconds)) rows per second)"
            }
            Write-Progress @progressRowParameter
        }
        $progressRowCompleted++

        $parameterValues = @{}
        foreach ($column in $row.PSObject.Properties) {
            $parameterValues[$column.Name] = $column.Value
        }
        Invoke-DbaQuery -SqlInstance $connectionUser -Query $insertIntoSql -SqlParameter $parameterValues
    }

    Write-Progress @progressRowParameter -Completed
}

Write-Progress @progressTableParameter -Completed

$null = $connectionUser | Disconnect-DbaInstance
