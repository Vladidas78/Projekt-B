# Datenexport auf dem Server betreiben

Ziel: Das Export-Skript läuft nicht mehr auf dem Notebook von VKU, sondern rund um die Uhr auf einem Server (z. B. dem OT-Testserver). Für das Board und die Kollegen ändert sich nichts.

Dafür gibt es eine eigene Server-Fassung des Skripts: `tools/SupportBoard-Export-Server.ps1`. Sie nutzt dieselbe Abfrage (`SupportBoard-Abfrage.sql`) und schreibt dieselbe CSV wie die Arbeitsplatz-Fassung, bringt aber die Einrichtung der Aufgabenplanung, das Dienstkonto und die Prüfung gleich mit.

## Wo liegt was: die Empfehlung

**CSV und Team-Datei bleiben auf dem Teamshare, im selben Ordner wie das Board.** Der Server schreibt die CSV nur dorthin, sonst nichts.

| Datei | Ort | Wer schreibt | Wer liest |
|---|---|---|---|
| `SupportBoard-Export-Server.ps1`, `SupportBoard-Abfrage.sql`, `.pwd`, `.log` (Ersatz) | Server, z. B. `C:\Tools\SupportBoard\` | Administrator (einmalig) | Dienstkonto |
| `SupportBoard-Daten.csv` | Teamshare, z. B. `\\Server\Freigabe\Supportmanagement\SQL-Test\` | Dienstkonto vom Server aus | jeder Arbeitsplatz (Board) |
| `SupportBoard-Export.log` | Teamshare, gleicher Ordner | Dienstkonto | jeder, der nachsehen will |
| `SupportBoard-Team-SQLTest.json` | Teamshare, gleicher Ordner | jeder Arbeitsplatz (Board) | jeder Arbeitsplatz (Board) |
| `SupportBoard-SQLTest.html` | Teamshare, gleicher Ordner (später ggf. interner Webserver, siehe IT-Anleitung) | – | jeder Arbeitsplatz |

Warum nicht auf dem Server?

- Das Board läuft im Browser auf dem Arbeitsplatz und liest CSV und Team-Datei als Dateien. Beide müssen also als Freigabe von jedem Arbeitsplatz erreichbar sein. Auf dem Teamshare ist das heute schon so, mit den Rechten, die es bereits gibt.
- Die **Team-Datei wird ausschließlich vom Board geschrieben**, nie vom Skript. Der Server hat mit ihr nichts zu tun. Läge sie auf dem Server, bräuchte jeder Kollege dort Schreibrecht, und bei jedem Neustart oder jeder Wartung des Servers stünde das Team ohne Haken und Kommentare da.
- Für die CSV gilt dasselbe in abgeschwächter Form: Läge sie auf dem Server, müsste dort eine Freigabe mit Leserecht für alle eingerichtet werden, und der Anwendungsserver würde nebenbei zum Dateiserver. Auf dem Teamshare greift die normale Sicherung.
- Der Server braucht dadurch genau **ein** zusätzliches Recht: Schreibrecht des Dienstkontos auf den einen Ordner.

## Fallback: Server kommt nicht an den Teamshare

Dafür ist der **Ersatzpfad** eingebaut. Das Skript schreibt die CSV bei jedem Lauf **an beide Orte**: auf den Teamshare und in einen Ordner auf dem Server (Standard `C:\SupportBoard-Daten\`). Dieser Ordner wird per `-ErsatzEinrichten` als Freigabe `\\SERVER\SupportBoard` veröffentlicht, nur lesend für die eingetragene Gruppe. Das Log liegt in beiden Ordnern.

- Klappt der Teamshare, ist der Ersatzpfad einfach eine zweite, immer aktuelle Kopie. Niemand muss etwas tun.
- Klappt der Teamshare nicht (Rechte fehlen, Netzwerkzone, Share nicht erreichbar), meldet das Log `Nicht geschrieben – Teamshare …` als Warnung, der Lauf gilt aber als erfolgreich, weil der Ersatzpfad frisch ist. Dann im Board Verwaltung → **„Dashboard überwachen …“** → `\\SERVER\SupportBoard\SupportBoard-Daten.csv` wählen. Fertig, mehr ändert sich nicht.
- Die **Team-Datei bleibt in jedem Fall auf dem Teamshare.** Sie hat mit dem Server nichts zu tun.
- Erst wenn beide Ziele scheitern, meldet das Skript einen Fehler und die alte CSV bleibt stehen.

Braucht man den Ersatzpfad nicht, im Skript `$ZielpfadErsatz = ''` setzen.

**Steht von vornherein fest, dass der Server nicht auf den Teamshare schreiben darf**, wird der Server-Ordner zum Hauptziel. Dann gibt es keine Warnung bei jedem Lauf:

```powershell
$Zielpfad         = 'C:\SupportBoard-Daten\SupportBoard-Daten.csv'   # Hauptziel liegt auf dem Server
$ZielpfadErsatz   = ''                                               # kein zweites Ziel
$ErsatzFreigabe   = 'SupportBoard'                                   # -> \\SERVER\SupportBoard
$ErsatzLesegruppe = 'DEINEDOMAENE\Domänen-Benutzer'                  # darf lesen
```

`-ErsatzEinrichten` gibt in diesem Fall den Ordner aus `$Zielpfad` frei. Das Dienstkonto braucht dann kein Recht auf dem Teamshare mehr; bei SQL-Anmeldung (`$WindowsAuth = $false`) reicht sogar SYSTEM (`$Dienstkonto = ''`), weil das Konto nur noch lokal schreibt. Die Team-Datei bleibt auf dem Teamshare, das Board überwacht die CSV unter `\\SERVER\SupportBoard\SupportBoard-Daten.csv`.

## Was der Server braucht

Vorab mit der IT klären, das ist der einzige Teil, der nicht per Skript geht:

1. **Ein Dienstkonto**, z. B. `DOMAENE\svc-supportboard`. Ein gruppenverwaltetes Dienstkonto (gMSA) geht ebenfalls, dann entfällt das Passwort. SYSTEM geht zur Not auch, greift aber als Computerkonto (`DOMAENE\SERVERNAME$`) auf Share und Datenbank zu.
2. **Rechte des Dienstkontos**
   - Datenbank: lesend (bei Windows-Anmeldung ein Login für das Konto mit `db_datareader` auf der Reporting-Datenbank; bei SQL-Anmeldung wie bisher der Read-only-Benutzer).
   - Teamshare-Ordner: Ändern (schreiben, umbenennen, löschen), damit die CSV atomar ersetzt werden kann.
   - Skriptordner auf dem Server: Lesen.
3. **PowerShell 5.1** (auf jedem Windows Server vorhanden) und Netzwerkzugriff vom Server auf SQL-Server und Teamshare.

Empfehlung: **Windows-Anmeldung an der Datenbank** (`$WindowsAuth = $true`). Dann gibt es kein Passwort im Spiel, keine Passwortdatei, nichts, was abläuft.

## Einrichten (auf dem Server, PowerShell „als Administrator“)

**1. Dateien ablegen**
`SupportBoard-Export-Server.ps1` und `SupportBoard-Abfrage.sql` nach `C:\Tools\SupportBoard\`. Beide Dateien einmal freischalten, falls sie aus dem Internet oder per Download kamen:

```powershell
Unblock-File C:\Tools\SupportBoard\*
```

**2. Einstellungen eintragen** (Block `EINSTELLUNGEN` oben im Skript)

```powershell
$Server       = '…'                      # wie in der Arbeitsplatz-Fassung
$Datenbank    = '…'
$WindowsAuth  = $true                    # empfohlen; sonst $false + Schritt 3
$Benutzer     = '…'                      # nur bei $WindowsAuth = $false
$Zielpfad     = '\\Server\Freigabe\Supportmanagement\SQL-Test\SupportBoard-Daten.csv'
$Dienstkonto  = 'DOMAENE\svc-supportboard'   # '' = SYSTEM, 'DOMAENE\konto$' = gMSA
$IntervallMin = 10
$ZielpfadErsatz   = 'C:\SupportBoard-Daten\SupportBoard-Daten.csv'   # Fallback auf dem Server, '' = aus
$ErsatzFreigabe   = 'SupportBoard'                 # -> \\SERVER\SupportBoard
$ErsatzLesegruppe = 'DOMAENE\Domänen-Benutzer'    # darf die Freigabe lesen
```

**2b. Ersatzpfad einrichten** (Ordner, Rechte, Freigabe; einmalig)

```powershell
.\SupportBoard-Export-Server.ps1 -ErsatzEinrichten
```

Gibt am Ende den Pfad aus, den das Board im Fallback überwachen kann.

**3. Passwort hinterlegen** (nur bei `$WindowsAuth = $false`)

```powershell
.\SupportBoard-Export-Server.ps1 -SetPassword
```

Anders als auf dem Arbeitsplatz ist das Passwort an den **Server** gebunden, nicht an das Konto, das es eingibt. Der Administrator hinterlegt es, die Aufgabe liest es unter dem Dienstkonto. Damit es nicht jeder auf dem Server lesen kann, beschränkt das Skript die Datei auf Administratoren, SYSTEM und das Dienstkonto.

**4. Testlauf ohne Datei** (läuft noch unter dem Admin-Konto, prüft Abfrage und Datenbank)

```powershell
.\SupportBoard-Export-Server.ps1 -Preview
```

Erwartet: plausible Zeilenzahl und die bekannten Spaltennamen.

**5. Aufgabe anlegen**

```powershell
.\SupportBoard-Export-Server.ps1 -Install
```

Das Skript fragt einmal das Passwort des Dienstkontos ab (es geht nur an die Aufgabenplanung und wird nirgends gespeichert; bei gMSA und SYSTEM entfällt die Frage), legt die Aufgabe an (alle 10 Minuten, unabhängig von der Anmeldung, bei Fehlern bis zu drei Neustarts) und **startet sie sofort einmal als Probelauf unter dem Dienstkonto**. Am Ende stehen Ergebnis, die letzten Logzeilen und der Stand der CSV auf dem Bildschirm. Das ist der eigentliche Test: Erscheint hier `Fertig: … Zeilen`, kommt das Dienstkonto an Datenbank und Share.

Typische Fehler an dieser Stelle:

| Meldung | Ursache |
|---|---|
| Kein Log im Zielordner | Dienstkonto hat kein Schreibrecht auf den Teamshare-Ordner. |
| `Login failed for user …` | Dienstkonto hat kein Login auf dem SQL-Server (Windows-Anmeldung) oder Passwort falsch (SQL-Anmeldung). |
| `Zielordner nicht erreichbar` | Server kommt netzwerkseitig nicht an den Share, oder der Pfad ist falsch. |
| Ergebnis `267011` oder `2147943785` | Dienstkonto darf sich nicht als Stapelverarbeitungsauftrag anmelden (lokale Sicherheitsrichtlinie, „Anmelden als Stapelverarbeitungsauftrag“). |

**6. Arbeitsplatz-Aufgaben abschalten**
Auf dem Notebook (und bei allen, die die Aufgabe eingerichtet hatten):

```powershell
Disable-ScheduledTask -TaskName "Supportboard Datenexport"
```

Bleibt eine versehentlich aktiv, passiert nichts Schlimmes: Beide Fassungen prüfen das Alter der CSV und schreiben nur, wenn sie älter als die Schwelle ist. Im Log steht immer, welcher Rechner geschrieben hat.

**7. Kontrolle im Alltag**

```powershell
.\SupportBoard-Export-Server.ps1 -Status
```

zeigt Zustand der Aufgabe, letzten und nächsten Lauf, Alter und Zeilenzahl der CSV und die letzten zehn Logzeilen. Vom Arbeitsplatz aus reicht ein Blick in `SupportBoard-Export.log` im Teamshare-Ordner. Fehler landen zusätzlich im Ereignisprotokoll des Servers (Anwendung, Quelle `SupportBoard-Export`), damit die IT sie mit ihren Mitteln überwachen kann.

## Kein schwarzes Fenster

Auf dem Notebook blitzt alle 15 Minuten ein PowerShell-Fenster auf, weil die Aufgabe dort „nur ausführen, wenn der Benutzer angemeldet ist“ in der eigenen Sitzung läuft. Auf dem Server passiert das nicht: Die Aufgabe läuft unter dem Dienstkonto (oder SYSTEM) „unabhängig von der Benutzeranmeldung“ in einer unsichtbaren Sitzung, auch wenn gerade jemand per Remotedesktop angemeldet ist. Zusätzlich trägt `-Install` die Aufgabe mit `-WindowStyle Hidden` ein.

Prüfen, ob die Aufgabe wirklich unsichtbar läuft:

```powershell
(Get-ScheduledTask -TaskName "Supportboard Datenexport (Server)").Principal | Format-List UserId, LogonType
```

Erwartet: `LogonType : Password` (Dienstkonto oder gMSA) oder `ServiceAccount` (SYSTEM). Steht dort `Interactive`, wurde die Aufgabe von Hand auf „nur bei Anmeldung“ umgestellt; dann `-Install` erneut ausführen.

Erscheint trotzdem ein Fenster, die Aktion auf den lautlosen Starter umstellen (`SupportBoard-Export-Server-leise.vbs` liegt neben dem Skript):

```powershell
$a = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument '"C:\Tools\SupportBoard\SupportBoard-Export-Server-leise.vbs"'
Set-ScheduledTask -TaskName "Supportboard Datenexport (Server)" -Action $a
```

Zurück auf die direkte Aktion geht es jederzeit mit `-Install`.

## Zweite Abfrage: externe Reaktion (ab v1.41)

Die externe Reaktion kommt aus einer eigenen Datei `SupportBoard-Abfrage-Reaktion.sql` im Skriptordner (zwei Spalten: `Call`, `Externe Reaktion`). Das Skript führt sie in einer eigenen Verbindung aus (gleiche Absicherung: Prüfung, Rollback, keine Sperren) und hängt den Wert über die Call-Nummer an die Zeilen der Hauptabfrage an. Ergebnis bleibt eine CSV.

- Datei fehlt oder ist leer: nichts wird angehängt, kein Fehler.
- Abfrage scheitert (Tabelle abgestellt, Timeout): CSV wird trotzdem geschrieben, Spalte bleibt leer, Log zeigt `WARNUNG Reaktionsabfrage uebersprungen`.
- `-Preview` zeigt die Spaltenliste mit der angehängten Spalte und für wie viele Zeilen ein Wert gefunden wurde.

Am Skript sind dafür keine Einstellungen nötig; die Datei einfach neben die Hauptabfrage legen.

## Was sich für das Board ändert

Nichts. Es liest weiter `SupportBoard-Daten.csv` aus dem Ordner, den es überwacht. Weil der Server auch nachts und am Wochenende läuft, ist die CSV morgens bereits frisch. „Jetzt synchronisieren“ liest wie bisher die aktuelle Datei ein; ein Lauf des Skripts von Hand ist mit dem 10-Minuten-Takt praktisch nie nötig. Wer ihn trotzdem braucht, startet auf dem Server `.\SupportBoard-Export-Server.ps1 -Jetzt`.

## Umstellung auf den Produktivordner

Wenn die Testphase vorbei ist: im Skript nur `$Zielpfad` auf den Produktivordner ändern, dann `-Install` erneut ausführen (ersetzt die Aufgabe). Im Board Verwaltung → „Dashboard überwachen …“ → neue CSV wählen. Die Excel-Routine bleibt als Rückfallebene erhalten.

## Entfernen

```powershell
.\SupportBoard-Export-Server.ps1 -Uninstall
```

entfernt nur die Aufgabe. CSV, Log und Passwortdatei bleiben liegen und können von Hand gelöscht werden.
