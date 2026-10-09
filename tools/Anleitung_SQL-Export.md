# Automatischer Datenexport für das Supportmanagement-Board

Ersetzt das manuelle Öffnen, Aktualisieren und Speichern der Excel-Liste.

**Stand v1.43:** Der Export läuft ausschließlich auf dem Server (`SupportBoard-Export-Server.ps1`, Anleitung: `docs/Anleitung_Serverbetrieb.md`). Die frühere Arbeitsplatz-Fassung `SupportBoard-Export.ps1` ist abgeschafft; die Abschnitte unten zum Einrichten am Arbeitsplatz gelten nur noch als Hintergrund. Die Spaltenverträge der Abfragen (weiter unten) gelten unverändert.

| Datei | Zweck |
|---|---|
| `SupportBoard-Export-Server.ps1` | Das Skript (Server-Fassung). Hier oben die Einstellungen eintragen. |
| `SupportBoard-Abfrage.sql` | Hauptabfrage: eine Zeile je Call (offen + zwei Jahre geschlossen). Änderungen wirken sofort beim nächsten Lauf. |
| `SupportBoard-Abfrage-Reaktion.sql` | Optional (ab v1.41): zweite Abfrage mit den Spalten `Call` und `Externe Reaktion` (Geschäftszeit in Tagen); ab v1.47 wird eine optionale Spalte `Prioritaet_initial` mit durchgereicht. Das Skript hängt den Wert über die Call-Nummer an – es bleibt **eine** CSV. Fehlt die Datei oder scheitert die Abfrage, wird die CSV trotzdem geschrieben (Spalte leer, WARNUNG im Log). |
| `SupportBoard-Abfrage-Weiterleitung.sql` | Optional (ab v1.43): dritte Abfrage für die Weiterleitungs-Historie. Entweder in der Rohform (je Weiterleitung eine Zeile: Call, Datum, vorherige Gruppe, vorheriger Bearbeiter, aktuelle Gruppe, aktueller Bearbeiter, Folgestatus, Ersteller; das Skript bündelt je Call, ab v1.45) oder schon gebündelt als zwei Spalten `Call` und `Weiterleitungen`. Die Datei im Repo ist die Abfrage des Teams (Rohform). |
| `SupportBoard-Export.log` | Entsteht automatisch, protokolliert jeden Lauf. |
| `SupportBoard-Export-Server-leise.vbs` | Optionaler Starter für die Aufgabenplanung, damit kein Fenster aufblitzt. |

## Sicherheit: Es kann nichts kaputtgehen

Drei unabhängige Schutzschichten:

1. **Prüfung vor dem Start.** Die Abfrage muss mit `SELECT` oder `WITH` beginnen und darf kein schreibendes Schlüsselwort enthalten (INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, MERGE, EXEC …). Sonst bricht das Skript ab, **bevor** die Datenbank überhaupt kontaktiert wird. Text in Anführungszeichen (z. B. die Tätigkeit `'update delivery'`) wird dabei korrekt als Text erkannt und nicht als Befehl.
2. **Transaktion mit garantiertem Rollback.** Alles läuft in einer Transaktion, die am Ende **immer** zurückgerollt wird – auch bei einem Fehler. Selbst wenn etwas schreiben wollte, bliebe davon nichts übrig.
3. **Keine Sperren.** Isolationsstufe `ReadUncommitted`: Das Skript blockiert niemanden, der gerade in Omnitracker arbeitet.

Zusätzlich: Liefert die Abfrage 0 Zeilen oder tritt ein Fehler auf, bleibt die **bisherige CSV unverändert** stehen. Das Board arbeitet dann mit dem letzten guten Stand weiter, statt plötzlich leer zu sein.

## Einrichten (einmalig, ca. 15 Minuten)

**1. Ordner anlegen**
Die drei Dateien in einen Ordner legen, z. B. `C:\Tools\SupportBoard\`.

**2. Einstellungen im Skript eintragen**
`SupportBoard-Export.ps1` mit einem Texteditor öffnen, den Block `EINSTELLUNGEN` ausfüllen:

```powershell
$Server      = 'BeispielServer-01'      # aus dem Excel-Verbindungsstring: Data Source
$Datenbank   = 'MPDV-Reporting'         # aus dem Excel-Verbindungsstring: Initial Catalog
$WindowsAuth = $false                   # $true = eigenes Windows-Konto, $false = Benutzer/Passwort
$Benutzer    = 'Beispiel-readonly'      # aus dem Excel-Verbindungsstring: User ID
$Zielpfad    = '\\Server\Freigabe\Supportmanagement\SQL-Test\SupportBoard-Daten.csv'
```

**3. Passwort hinterlegen** (entfällt bei `$WindowsAuth = $true`)
PowerShell im Ordner öffnen und einmalig ausführen:

```powershell
.\SupportBoard-Export.ps1 -SetPassword
```

Das Passwort wird verschlüsselt in `SupportBoard-Export.pwd` abgelegt – lesbar **nur** mit deinem Windows-Konto auf diesem PC. Im Skript selbst steht kein Klartext-Passwort.

**4. Testlauf ohne Datei zu schreiben**

```powershell
.\SupportBoard-Export.ps1 -Preview
```

Zeigt die gefundene Zeilen- und Spaltenzahl an und schreibt nichts. Wenn hier eine plausible Zeilenzahl erscheint, passt alles.

**5. Echten Lauf starten**

```powershell
.\SupportBoard-Export.ps1
```

Danach liegt `SupportBoard-Daten.csv` im Zielordner.

**6. Aufgabenplanung einrichten**
Am zuverlässigsten per PowerShell (alle Zeilen zusammen einfügen, Pfad anpassen). Die Aufgabe läuft alle 15 Minuten unter dem eigenen Konto, nur solange man angemeldet ist, ohne gespeichertes Kennwort, auch im Akkubetrieb:

```powershell
$aktion   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Tools\SupportBoard\SupportBoard-Export.ps1"'
$trigger  = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 3650)
$optionen = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
Register-ScheduledTask -TaskName "Supportboard Datenexport" -Action $aktion -Trigger $trigger -Settings $optionen -Force
```

Prüfen: `schtasks /Run /TN "Supportboard Datenexport"`, kurz warten, dann muss im Log eine neue Zeile stehen.

Blitzt bei jedem Lauf kurz ein schwarzes Fenster auf, hilft der Starter `SupportBoard-Export-leise.vbs` (liegt im selben Ordner wie das Skript; er sucht dort `SupportBoard-Export.ps1`, bei anderem Dateinamen die Zeile im Starter anpassen). Dann nur die Aktion der Aufgabe tauschen:

```powershell
$aktion = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument '"C:\Tools\SupportBoard\SupportBoard-Export-leise.vbs"'
Set-ScheduledTask -TaskName "Supportboard Datenexport" -Action $aktion
``` Entfernen: `Unregister-ScheduledTask -TaskName "Supportboard Datenexport" -Confirm:$false`.

Nicht `schtasks /Create` aus PowerShell heraus mit `\"`-Anführungszeichen verwenden: PowerShell zerlegt die Zeile anders, der Pfad kommt verstümmelt an, und die Aufgabe läuft nie, obwohl „erfolgreich erstellt“ gemeldet wird. Wer die Oberfläche bevorzugt: *Aufgabe erstellen* → Allgemein „Nur ausführen, wenn der Benutzer angemeldet ist“ → Trigger täglich, alle 15 Minuten wiederholen → Aktion `powershell.exe` mit den Argumenten aus der Zeile oben → Bedingungen: beide Haken bei „Energie“ entfernen (Notebook).

**7. Board umstellen**
Im Board: Verwaltung → **„Dashboard überwachen …“** → die neue `SupportBoard-Daten.csv` auswählen. Fertig – ab jetzt kommen die Daten automatisch. In der Erprobungsphase ist das die Testversion `SupportBoard-SQLTest.html`, die Produktivversion bleibt bei der Excel-Liste.

## Was neu dazukommt

### Ab v1.41: geschlossene Calls, Region, zweite Abfrage

Die Hauptabfrage liefert jetzt auch die **geschlossenen Calls der letzten zwei Jahre** und die **Region** des Kunden. Das Board erwartet dafür diese Spaltennamen (`AS …`):

| Spalte | Inhalt |
|---|---|
| `Status` | Echter Status, auch `Gelöst` / `Geschlossen`. Welche Werte als „zu“ gelten, steht im Board unter Verwaltung → Grundregeln (ab Werk: Gelöst; Geschlossen; Closed; Resolved; Solved). |
| `Region` | `USA`, `Asien` oder `Europa` (auch `Asia`, `Europe`, `US` werden erkannt). Ersetzt die Kürzellisten USA/Asien in der Verwaltung; neuer Filter-Chip „Europa“. |
| `Geschlossen` | Optional: Abschlussdatum. Fehlt die Spalte, gilt bei geschlossenen Calls die letzte Änderung als Abschluss. |
| `Externe Reaktion` | Kommt aus der zweiten Datei `SupportBoard-Abfrage-Reaktion.sql` (Spalte 1 Call, Spalte `Externe Reaktion` als Wert – sonst Spalte 2; weitere Spalten werden ignoriert, außer `Prioritaet_initial`). Der Wert ist **Geschäftszeit** in Tagen (`erste_ext_aktion_kalender / 86400`, Omnitracker-Kalender, dieselbe Größe wie „erste ext. Aktion Kalender“ der Excel-Statistik); das Board rechnet ihn nicht erneut um (v1.47). Diese Abfrage legt die Grundgesamtheit der Reaktionszeit fest: Calls ohne Zeile werden nicht bewertet, Wert 0 heißt „noch keine Reaktion“. Deshalb ohne Filter auf `erste_ext_aktion_kalender > 0`, `e_bestaetigung_kalender > 0` und ohne Regionsfilter (die Region filtert das Board). |
| `Prioritaet_initial` | Optional (ab v1.47), aus derselben Datei (`cs.prioritaet_initial`): Priorität bei Eröffnung. Das Board bewertet die Reaktionszeit gegen sie (Frist, Statistik, Brüche, Liste „ohne Reaktion“, Prio-Filter des Reiters); wird ein Call später umpriorisiert, bleibt die Reaktion bei der ursprünglichen Frist. Fehlt die Spalte, gilt die aktuelle Prio. |

### Ab v1.43: Weiterleitungs-Historie (dritte Abfrage)

Für den Reiter „Weiterleitungen“ (Ping-Pong zwischen Hotline/1st Level und Dispatcher, Liegedauer je Monat, Verteilung der Dispatcher-Weiterleitungen) liefert die Datei `SupportBoard-Abfrage-Weiterleitung.sql` die Historie je Call. Die Hauptabfrage bleibt unverändert, eine Zeile je Call. In der Hauptabfrage heißt die bisherige Spalte `Weiterleitung` jetzt `Letzte_Weiterleitung` (beide Namen werden erkannt).

Die dritte Abfrage liefert entweder die **Rohform** (Stand des Teams, Datei im Repo) oder **zwei Spalten**.

**Rohform** (ab v1.45 vom Skript gebündelt): je Weiterleitung eine Zeile mit genau dieser Spaltenreihenfolge: `Call`, `Datum`, `vorherige Gruppe`, `vorheriger Bearbeiter`, `aktuelle Gruppe`, `aktueller Bearbeiter`, `Folgestatus`, `Ersteller`. Die Spaltennamen sind frei, die Reihenfolge nicht: Spalte 1 ist der Schlüssel, Spalte 2 das Datum (nach ihm wird sortiert), die übrigen Spalten werden in dieser Reihenfolge mit `|` zusammengesetzt. Das Skript ersetzt `|` und `#` in den Werten, sortiert je Call nach Datum und schreibt den Text in die Spalte `Weiterleitungen`. Im Log steht „Rohform mit 8 Spalten, N Zeilen zu M Calls gebuendelt“.

**Gebündelte Form** (zwei Spalten, zum Beispiel per `STRING_AGG`, Fassung als Kommentar in der Datei):

| Spalte | Inhalt |
|---|---|
| `Call` | Call-Nummer, Schlüssel für das Anhängen. |
| `Weiterleitungen` | Ein Text je Call: je Weiterleitung ein Block `Datum\|vorherige Gruppe\|vorheriger Bearbeiter\|aktuelle Gruppe\|aktueller Bearbeiter\|Folgestatus\|Ersteller`, Blöcke mit ` # ` getrennt, älteste zuerst. Datum als `JJJJ-MM-TTThh:mm:ss`. Leeres Feld = kein Wert; `\|` und `#` dürfen in den Werten nicht vorkommen (die Vorlage ersetzt sie). |

Beispiel für einen Call mit zwei Weiterleitungen:

```
2026-09-01T10:30:00|Hotline|HO1|Dispatcher||Neu|HO1 # 2026-09-02T10:05:00|Dispatcher|DP1|2nd_CAQ|CQ1|In Bearbeitung|DP1
```

Das Server-Skript führt die Abfrage in einer eigenen Verbindung aus und hängt den Text über die Call-Nummer als Spalte `Weiterleitungen` an jede Zeile der Hauptabfrage an, genau wie die externe Reaktion. Calls ohne Weiterleitung bekommen eine leere Spalte. Fehlt die Datei oder scheitert die Abfrage, bleibt die Spalte leer (WARNUNG im Log), die CSV kommt trotzdem. `-Preview` meldet „Weiterleitungsabfrage: Wert 'Weiterleitungen' fuer N von M Zeilen gefunden“.

Die Datei im Repo ist die Abfrage des Teams in der Rohform (Tabelle `forwardings`, zwei Jahre, ohne die Hotline-/1st-Level-Gruppen USA und Asien); eine `STRING_AGG`-Fassung (SQL Server ab 2017) steht als Kommentar darin. Die Gruppennamen in den Blöcken müssen zu den Eingangsstapeln in der Verwaltung passen (Vorgabe: `Hotline; 1st_Level` und `Dispatcher`); die Verwaltung listet alle Gruppen, die in der Historie vorkommen.

Alternativ erkennt das Board weiterhin die Form aus v1.42 (je Weiterleitung eine Zeile in der Haupt-CSV mit den Spalten `Datum Weiterleitung`, `vorherige Gruppe`, `vorheriger Bearbeiter`, `aktuelle Gruppe`, `aktueller Bearbeiter`, `Folgestatus`, `Ersteller Weiterleitung`, `Weiterleitung Nr`, `Gesamtanzahl Weiterleitungen`). Sie ist nicht empfohlen: Die Call-Spalten müssten in allen Zeilen eines Calls identisch sein, die Datei wird mehrfach so groß, und jeder Verbraucher muss je Call entdoppeln.

Geschlossene Calls stehen in keiner Tagesliste und keiner Mail. Sie zählen in der Tagesstatistik (neu/geschlossen/wieder geöffnet), bei den Top 10 („in der Vorwoche Mo–So geschlossen“) und in der Reaktionszeit – dort auch Calls, die zwischen zwei Exporten aufgingen, beantwortet und geschlossen wurden.

Die Abfrage enthält eine zusätzliche Spalte **„Letzte externe Reaktion“** (mit Uhrzeit). Damit wird die Ansicht *„Keine ext. Reaktion“* im Board scharf geschaltet: Rot ab 30 Minuten, Blau ab 4 Stunden, Grün ab 48 Stunden.

Grundlage ist dieselbe Logik wie bei „Letzte Info an Kd.“ – die letzte Aktivität mit Außenwirkung. Gab es noch keine, zählt die Weiterleitung an die Gruppe, ersatzweise die Call-Eröffnung. So fällt auch ein frischer Call auf, bei dem sich noch niemand gemeldet hat.

**Bitte beim ersten Blick prüfen:** Wenn dort sehr viele Calls stehen, liegt das meist an Calls mit Status *Wartend* oder *Customer Care* – da wartet nicht der Kunde auf uns, sondern wir auf ihn. Diese Status lassen sich in der Ansicht direkt über die Filter-Chips ausblenden; die Einstellung bleibt gespeichert.

## Nicht warten wollen: „Jetzt synchronisieren“

Der Zeitplan (z. B. alle 15 Minuten) reicht für den Alltag. Wer einen frischen Stand **sofort** braucht:

1. **Skript von Hand starten** – am einfachsten über eine Desktop-Verknüpfung mit dem Ziel:

   ```
   powershell.exe -ExecutionPolicy Bypass -File "PFAD\SupportBoard-Export-Server.ps1" -Jetzt
   ```

   Der Schalter `-Jetzt` überspringt die „Datei ist noch frisch“-Prüfung, damit der Ad-hoc-Lauf nicht wegen einer wenige Minuten alten Datei aussteigt. Alle Schutzmechanismen (nur lesen, Rollback, alte Datei bleibt bei Fehlern stehen) gelten unverändert.

2. Danach im Board unten links auf **„Jetzt synchronisieren“** klicken (ab v1.22) – das Board liest die Dashboard-Datei und den Team-Speicher sofort neu ein, ohne auf das Prüfintervall zu warten.

Der Knopf im Board kann das Skript nicht selbst starten – eine im Browser geöffnete Datei darf keine Programme auf dem PC ausführen. Deshalb dieser Zweischritt; im Alltag genügt meist Schritt 2, weil der Zeitplan die CSV ohnehin frisch hält.

## Wenn niemand da ist: auf mehreren Rechnern einrichten

Das Skript läuft nur, während der PC an und der Benutzer angemeldet ist. Ist niemand da, bleibt die CSV liegen – das Board arbeitet mit dem letzten Stand weiter und zeigt unten links an, dass die Daten alt sind. Es geht nichts kaputt.

Damit die Daten trotzdem aktuell bleiben, richten am besten **zwei bis drei Kolleginnen und Kollegen dieselbe Aufgabe ein**. Wer gerade am Rechner sitzt, hält die Datei frisch – ganz ohne Absprache.

Damit sich die Instanzen nicht in die Quere kommen, prüft jede vor der Abfrage das Alter der vorhandenen Datei:

```powershell
$NurWennAelterAlsMin = 12    # 0 = Prüfung aus
```

Ist die Datei jünger, beendet sich das Skript sofort und fragt die Datenbank gar nicht erst. Es arbeitet also immer nur diejenige Instanz, bei der tatsächlich etwas zu tun ist – die Last auf der Datenbank bleibt dieselbe wie bei einer Einzelinstallation. Im Log steht jeweils, welcher Rechner geschrieben hat.

**Wichtig bei der Einrichtung auf weiteren Rechnern:** Das hinterlegte Passwort ist an das jeweilige Windows-Konto und den jeweiligen PC gebunden – jeder führt `-SetPassword` einmal selbst aus. Bei Windows-Authentifizierung (`$WindowsAuth = $true`) entfällt das ganz.

## Wenn etwas nicht läuft

Erste Anlaufstelle ist `SupportBoard-Export.log` im selben Ordner – dort steht jeder Lauf mit Zeitstempel und im Fehlerfall die Ursache im Klartext.

| Meldung | Bedeutung |
|---|---|
| `Sicherheitsstopp: …` | Die Abfrage enthält etwas Schreibendes. Es wurde nichts ausgeführt. |
| `Kein Passwort hinterlegt` | Schritt 3 nachholen. |
| `Zielordner nicht erreichbar` | Netzlaufwerk nicht verbunden. |
| `Die Abfrage lieferte 0 Zeilen` | Schutzmechanismus – die alte Datei bleibt erhalten. |
| `Die Eingabezeichenfolge hat das falsche Format` (ConvertTo-SecureString) | Passwortdatei aus einer älteren Skriptversion oder von Hand angelegt. `SupportBoard-Export.pwd` löschen und `-SetPassword` erneut ausführen. |
| `Eine Datei kann nicht erstellt werden, wenn sie bereits vorhanden ist` / `Cannot create a file when that file already exists` beim Schreiben | Die alte CSV ist von einem anderen Programm geöffnet (Excel oder Editor auf dem Server, ein Kollege über die Freigabe). Programm schließen; Zugriffe über die Freigabe zeigt `Get-SmbOpenFile \| Where-Object Path -like '*SupportBoard-Daten*'`. Ab 2026-10-08 versucht das Skript es mehrfach (`Ersetze-Datei`) und nennt sonst die echte Ursache. |
| `Möchten Sie diese Datei ausführen? [N] [M] [H]` bei jedem Start | Die Datei trägt die Download-Markierung von Windows. Einmalig `Unblock-File .\SupportBoard-Export-Server.ps1` ausführen, dann fragt PowerShell nicht mehr. |

Die alte Excel-Routine funktioniert unverändert weiter und kann jederzeit als Rückfallebene dienen.
