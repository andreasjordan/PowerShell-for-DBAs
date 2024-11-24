# Ein Bild sagt mehr als 1000 Zeilen - Oracle AWR mit PowerShell visualisieren

Am 21.11.2024 habe ich auf der DOAG Konferenz + Ausstellung einen Vortrag zum Thema "Ein Bild sagt mehr als 1000 Zeilen - Oracle AWR mit PowerShell visualisieren" gehalten. Hier finden Sie die [Präsentation](2024-11-21-DOAG_2024_AWR_PowerShell.pdf) sowie den im Vortrag erwähnten [Code](2024-11-21-DOAG_2024_AWR_PowerShell.ps1).


## Notwendige Voraussetzungen

Um die benötigten Daten aus der Oracle Datenbank abfragen zu können, werden einige der [hier](https://github.com/andreasjordan/PowerShell-for-DBAs/tree/main/Oracle) von mir bereitgestellten Funktionen sowie die von Oracle bereitgestellte Bibliothek "Oracle.ManagedDataAccess.dll" benötigt.
Um automatisiert Excel-Dateien erzeugen zu können, wird das PowerShell-Modul [ImportExcel](https://github.com/dfinke/ImportExcel) benötigt.

Um alle Dateien an einem zentralen Ort ablegen zu können, erstellen Sie bitte ein neues Verzeichnis, ich verwende im Folgenden `C:\DOAG\`.


### 1. PowerShell-Funktionen

Es werden die Funktionen [Import-OraLibrary](https://github.com/andreasjordan/PowerShell-for-DBAs/blob/main/Oracle/Import-OraLibrary.ps1), [Connect-OraInstance](https://github.com/andreasjordan/PowerShell-for-DBAs/blob/main/Oracle/Connect-OraInstance.ps1) sowie [Invoke-OraQuery](https://github.com/andreasjordan/PowerShell-for-DBAs/blob/main/Oracle/Invoke-OraQuery.ps1) benötigt.

Um die drei Dateien per PowerShell herunterzuladen, können Sie folgenden Code verwenden:
```
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Import-OraLibrary.ps1 -OutFile C:\DOAG\Import-OraLibrary.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Connect-OraInstance.ps1 -OutFile C:\DOAG\Connect-OraInstance.ps1 -UseBasicParsing
Invoke-WebRequest -Uri https://raw.githubusercontent.com/andreasjordan/PowerShell-for-DBAs/main/Oracle/Invoke-OraQuery.ps1 -OutFile C:\DOAG\Invoke-OraQuery.ps1 -UseBasicParsing
```


### 2. Bibliothek Oracle.ManagedDataAccess.dll

Diese Bibliothek kann aus verschiedenen Quellen kopiert werden.

#### Oracle Client

Oracle stellt die Bibliothek als Teil des Oracle Client 19c bereit. In den neueren Versionen des Client werden leider nur noch die neueren NuGet-Pakete mitgeliefert, die wie weiter unten beschrieben leider weitere Abhängigkeiten haben.
Sollten Sie eine komplette Installation des Oracle Client vorliegen haben, so finden Sie die Datei im Verzeichnis `\odp.net\managed\common`. Alternativ können Sie sich die Datei `WINDOWS.X64_193000_client_home.zip` von [Oracle](https://www.oracle.com/de/database/technologies/oracle19c-windows-downloads.html) herunterladen und die Datei von dort extrahieren.

#### NuGet

Oracle stellt die Bibliothek auch als Teil des NuGet-Pakets [Oracle.ManagedDataAccess](https://www.nuget.org/packages/Oracle.ManagedDataAccess) zur Verfügung. Leider haben die aktuellen Versionen weitere Abhängigkeiten und benötigen daher weitere Pakete. Die letzte einfach zu verwendende Version ist aktuell die Version [19.25.0](https://www.nuget.org/packages/Oracle.ManagedDataAccess/19.25.0).
Für den Fall, dass Sie einen Weg gefunden haben, auch die aktuellen Versionen einsetzen zu können, würde ich mich über eine [Kontaktaufnahme](https://www.ordix.de/kontakt) sehr freuen.

Sie können das Paket entweder selbst herunterladen, auspacken (es ist ganz klassisch ZIP-komprimiert) und die DLL aus dem Verzeichnis `lib\net462\` kopieren. Oder aber die Funktion `Import-OraLibrary` verwenden, die bei der ersten Verwendung das Paket herunterlädt und daraus die DLL entpackt.


### 3. PowerShell-Modul ImportExcel

Die einfachste Variante der Installation ist die Verwendung des PowerShell-Befehls `Install-Module`. Wenn Sie lokale Administrationsrechte besitzen, dann starten Sie eine PowerShell "als Administrator" und nutzen den Befehl `Install-Module -Name ImportExcel`. Alternativ können Sie das Modul auch in einer "normalen" PowerShell im Kontext des aktuellen Benutzers installieren. Verwenden Sie dazu den Befehl `Install-Module -Name ImportExcel -Scope CurrentUser`. Bei der Installation werden evtl. Rückfragen gestellt, diese müssen Sie jeweils mit "Ja" beantworten.


## Der Beispiel-Code und notwendige Anpassungen

Den Beispiel-Code finden Sie [hier](2024-11-21-DOAG_2024_AWR_PowerShell.ps1).

Im Code sind einige Kommentare enthalten, die auf notwendige Anpassungen hinweisen. Vor allem die Verbindung zu Oracle muss entsprechend Ihrer Umgebung angepasst werden.

Generell ist dies nur Beispiel-Code und keine vollumfängliche Applikation. Im besten Fall sind alle Anpassungen auch ohne einen PowerShell-Experten durchführbar und erzeugen die Excel-Datei `dba_hist_sqlstat.xlsx`.

Wenn Sie Unterstützung benötigen, beispielsweise weil Sie auch die im Vortrag vorgestellten Daten aus `dba_hist_system_event` und `dba_hist_sysmetric_summary` auswerten oder Statspack als Quelle nutzen möchten, nehmen Sie gerne [Kontakt](https://www.ordix.de/kontakt) zu uns auf.
