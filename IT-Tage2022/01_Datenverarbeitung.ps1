# Datenverarbeitung mit PowerShell

# Wir belegen eine Variable mit dem Pfad zum etc-Verzeichnis (Variablensubstitution, Umgebungsvariablen)
$etcPath = "$env:windir\system32\drivers\etc"

# Wir ermitteln den Inhalt des Verzeichnisses (also die "Kinder" des Pfades)
$etcFiles = Get-ChildItem -Path $etcPath

# Wir analysieren die erhaltenen Daten (Array, Zugriff auf einzelne Elemente eines Arrays, Methoden, Attribute, Piping)
$etcFiles.GetType().FullName
$etcFiles[0].GetType().FullName
$etcFiles[0] | Get-Member
$etcFiles[0].LastWriteTime.GetType().FullName
$etcFiles[0] | Format-List

# Wir durchlaufen die einzelnen Dateien:
foreach ($file in $etcFiles) {
    # $file = $etcFiles[0]
    [int]$hoursSinceChange = ([System.DateTime]::Now - $file.LastWriteTime).TotalHours
    if ($hoursSinceChange -lt 80) {
        Write-Warning -Message "Die Datei '$($file.Name)' wurde von $hoursSinceChange Stunden geändert"
    }
}

# Wir erzeugen die Daten selber:

# Hashtabellen:
$hashTable = @{
    Schlüssel = 'Wert'
    S2        = 1
}

# Objekte:
$object = [PSCustomObject]@{
    Attribut = 'Wert'
    A2       = 1
}

# Arrays:
$array = @(
    'Element'
    'E2'
)

# Arrays mit Objekten:
$objectArray = @(
    [PSCustomObject]@{
        Attribut = 'Wert1'
        A2       = 1
        Flag     = $true
    }
    [PSCustomObject]@{
        Attribut = 'Wert2'
        A2       = 2
        Flag     = $true
    }
    [PSCustomObject]@{
        Attribut = 'Wert3🌍'
        A2       = 3
        Flag     = $true
    }
    [PSCustomObject]@{
        Attribut = 'Wert3'
        A2       = 3
        Flag     = $false
    }
    [PSCustomObject]@{
        Attribut = 'Wert4'
        A2       = 4
        Flag     = $false
    }
)

$objectArray | Format-Table
$objectArray | Format-List

# Filtern:
$filteredObjectArray = $objectArray | 
    Where-Object -FilterScript { $_.Flag -eq $true } | 
    Sort-Object -Property A2 -Descending | 
    Select-Object -First 2 -Property Attribut, A2

# Formatieren als JSON:
$filteredObjectArray | ConvertTo-Json

# Wie sieht das bei "echten" Daten aus:
$etcFiles | 
    Select-Object -Property Name, FullName, LastWriteTime, LastAccessTime, Length, IsReadOnly |
    ConvertTo-Json

# Und ab in eine Datei:
$filteredObjectArray | ConvertTo-Json | Set-Content -Path C:\ITTage\filteredObjectArray.txt
$etcFiles | 
    Select-Object -Property Name, FullName, LastWriteTime, LastAccessTime, Length, IsReadOnly |
    ConvertTo-Json |
    Set-Content -Path C:\ITTage\etcFiles.txt

# Achtung "encoding":
$filteredObjectArray | ConvertTo-Json | Set-Content -Path C:\ITTage\filteredObjectArray.txt -Encoding UTF8


# Und wieder zurück:
Get-Content -Path C:\ITTage\filteredObjectArray.txt -Encoding UTF8 | ConvertFrom-Json

$restoredEtcFiles = Get-Content -Path C:\ITTage\etcFiles.txt -Encoding UTF8 | ConvertFrom-Json
$restoredEtcFiles | ft
$restoredEtcFiles | ogv

