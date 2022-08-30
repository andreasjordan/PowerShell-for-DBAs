$ErrorActionPreference = 'Stop'

# Needs SQL Server Express installed

Import-Module -Name dbatools  # Install-Module -Name dbatools -Scope CurrentUser
. .\Environment.ps1

$orderOfInitialQuestions = 'FavoriteCount DESC'

# Creates about 14 MB (compressed 4 MB) of data:
$nrOfInitialQuestions = 200
$nrOfBadges = 100
$nrOfVotes = 100

<# Creates about 250 MB (compressed 65 MB) of data:
$nrOfInitialQuestions = 20000
$nrOfBadges = 10000
$nrOfVotes = 10000
#>

$instance = "$serverComputerName\SQLEXPRESS"
$credential = Get-Credential -Message $instance -UserName sa  # start123

$server = Connect-DbaInstance -SqlInstance $instance -SqlCredential $credential -NonPooledConnection

$null = Remove-DbaDatabase -SqlInstance $server -Database StackOverflow2010 -Confirm:$false

Invoke-Command -ComputerName $serverComputerName -Credential $windowsAdminCredential -Authentication Credssp -ScriptBlock {
    Expand-Archive -Path \\fs\SampleDatabases\StackOverflow2010.zip -DestinationPath D:\SQLServer\MSSQL15.SQLEXPRESS\MSSQL\DATA
}

$fileStructure = [System.Collections.Specialized.StringCollection]::new()
$null = $fileStructure.Add("D:\SQLServer\MSSQL15.SQLEXPRESS\MSSQL\DATA\StackOverflow2010.mdf")
$null = $filestructure.Add("D:\SQLServer\MSSQL15.SQLEXPRESS\MSSQL\DATA\StackOverflow2010_log.ldf")
$null = Mount-DbaDatabase -SqlInstance $server -Database StackOverflow2010 -FileStructure $fileStructure


$server = Connect-DbaInstance -SqlInstance $server -Database StackOverflow2010

# Rename columns that use reserved words
try { Invoke-DbaQuery -SqlInstance $server -Query "EXEC sp_rename 'dbo.Badges.Date', 'CreationDate', 'COLUMN'" -EnableException } catch { }

# Create temp tables
Invoke-DbaQuery -SqlInstance $server -Query "CREATE TABLE #Posts (Id INT, LastEditorUserId INT, OwnerUserId INT)"
Invoke-DbaQuery -SqlInstance $server -Query "CREATE TABLE #Comments (Id INT, UserId INT)"
Invoke-DbaQuery -SqlInstance $server -Query "CREATE TABLE #Votes (Id INT, UserId INT)"
Invoke-DbaQuery -SqlInstance $server -Query "CREATE TABLE #Users (Id INT)"

# Select $nrOfInitialQuestions initial questions, related answers, comments and users
Invoke-DbaQuery -SqlInstance $server -Query "INSERT INTO #Posts SELECT TOP $nrOfInitialQuestions Id, LastEditorUserId, OwnerUserId FROM dbo.Posts WHERE ParentId = 0 ORDER BY $orderOfInitialQuestions"
Invoke-DbaQuery -SqlInstance $server -Query "INSERT INTO #Posts SELECT Id, LastEditorUserId, OwnerUserId FROM dbo.Posts WHERE ParentId IN (SELECT Id FROM #Posts)"
Invoke-DbaQuery -SqlInstance $server -Query "INSERT INTO #Comments SELECT Id, UserId FROM dbo.Comments WHERE PostId IN (SELECT Id FROM #Posts)"
Invoke-DbaQuery -SqlInstance $server -Query "INSERT INTO #Users SELECT LastEditorUserId FROM #Posts UNION SELECT OwnerUserId FROM #Posts UNION SELECT UserId FROM #Comments"

# Get data
# Only last $nrOfBadges badges
# Only postlinks between selected posts
# Only last $nrOfVotes votes from selectes users to selected posts
$badges = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT TOP $nrOfBadges * FROM dbo.Badges WHERE UserId IN (SELECT Id FROM #Users) ORDER BY CreationDate DESC"
$comments = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT * FROM dbo.Comments WHERE Id IN (SELECT Id FROM #Comments)"
$linktypes = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT * FROM dbo.LinkTypes"
$postlinks = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT * FROM dbo.PostLinks WHERE PostId IN (SELECT Id FROM #Posts) AND RelatedPostId IN (SELECT Id FROM #Posts)"
$posts = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT * FROM dbo.Posts WHERE Id IN (SELECT Id FROM #Posts)"
$posttypes = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT * FROM dbo.PostTypes"
$users = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT * FROM dbo.Users WHERE Id IN (SELECT Id FROM #Users)"
$votes = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT TOP $nrOfVotes * FROM dbo.Votes WHERE PostId IN (SELECT Id FROM #Posts) AND UserId IN (SELECT Id FROM #Users) ORDER BY CreationDate DESC"
$votetypes = Invoke-DbaQuery -SqlInstance $server -As PSObject -Query "SELECT * FROM dbo.VoteTypes"

# Output number of objects
"$($badges.Count) Badges"
"$($comments.Count) Comments"
"$($linktypes.Count) LinkTypes"
"$($postlinks.Count) PostLinks"
"$($posts.Count) Posts ($(($posts | Where-Object ParentId -eq 0).Count) questions, $(($posts | Where-Object ParentId -gt 0).Count) answers)"
"$($posttypes.Count) PostTypes"
"$($users.Count) Users"
"$($votes.Count) Votes"
"$($votetypes.Count) VoteTypes"

# Export data
$data = @{
    Badges    = $badges
    Comments  = $comments
    LinkTypes = $linktypes
    PostLinks = $postlinks
    Posts     = $posts
    PostTypes = $posttypes
    Users     = $users
    Votes     = $votes
    VoteTypes = $votetypes
}
$data | ConvertTo-Json -Compress | Set-Content -Path .\SampleData.json -Encoding UTF8
Compress-Archive -Path .\SampleData.json -DestinationPath .\SampleData.zip -CompressionLevel Optimal
