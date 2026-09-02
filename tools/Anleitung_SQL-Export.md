# Automatischer Datenexport für das Supportmanagement-Board

Ersetzt das manuelle Öffnen, Aktualisieren und Speichern der Excel-Liste.
Drei Dateien, ein einmaliges Einrichten, danach läuft es von selbst.

Für die Erprobung neben dem laufenden Betrieb (eigener Testordner, Testversion des Boards) siehe `docs/Anleitung_Parallelbetrieb_SQL-Test.md`.

| Datei | Zweck |
|---|---|
| `SupportBoard-Export.ps1` | Das Skript. Hier oben die Einstellungen eintragen. |
| `SupportBoard-Abfrage.sql` | Deine Abfrage. Änderungen wirken sofort beim nächsten Lauf. |
| `SupportBoard-Export.log` | Entsteht automatisch, protokolliert jeden Lauf. |

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
Windows-Aufgabenplanung → *Aufgabe erstellen*:
- **Allgemein:** Name „Supportboard Datenexport“, Option **„Nur ausführen, wenn der Benutzer angemeldet ist“** (dann wird kein Kennwort gespeichert).
- **Trigger:** Täglich, Wiederholung **alle 15 Minuten** für die Dauer von 1 Tag.
- **Aktion:** Programm starten
  - Programm: `powershell.exe`
  - Argumente: `-NoProfile -ExecutionPolicy Bypass -File "C:\Tools\SupportBoard\SupportBoard-Export.ps1"`

**7. Board umstellen**
Im Board: Verwaltung → **„Dashboard überwachen …“** → die neue `SupportBoard-Daten.csv` auswählen. Fertig – ab jetzt kommen die Daten automatisch. In der Erprobungsphase ist das die Testversion `SupportBoard-SQLTest.html`, die Produktivversion bleibt bei der Excel-Liste.

## Was neu dazukommt

Die Abfrage enthält eine zusätzliche Spalte **„Letzte externe Reaktion“** (mit Uhrzeit). Damit wird die Ansicht *„Keine ext. Reaktion“* im Board scharf geschaltet: Rot ab 30 Minuten, Blau ab 4 Stunden, Grün ab 48 Stunden.

Grundlage ist dieselbe Logik wie bei „Letzte Info an Kd.“ – die letzte Aktivität mit Außenwirkung. Gab es noch keine, zählt die Weiterleitung an die Gruppe, ersatzweise die Call-Eröffnung. So fällt auch ein frischer Call auf, bei dem sich noch niemand gemeldet hat.

**Bitte beim ersten Blick prüfen:** Wenn dort sehr viele Calls stehen, liegt das meist an Calls mit Status *Wartend* oder *Customer Care* – da wartet nicht der Kunde auf uns, sondern wir auf ihn. Diese Status lassen sich in der Ansicht direkt über die Filter-Chips ausblenden; die Einstellung bleibt gespeichert.

## Nicht warten wollen: „Jetzt synchronisieren“

Der Zeitplan (z. B. alle 15 Minuten) reicht für den Alltag. Wer einen frischen Stand **sofort** braucht:

1. **Skript von Hand starten** – am einfachsten über eine Desktop-Verknüpfung mit dem Ziel:

   ```
   powershell.exe -ExecutionPolicy Bypass -File "PFAD\SupportBoard-Export.ps1" -Jetzt
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

Die alte Excel-Routine funktioniert unverändert weiter und kann jederzeit als Rückfallebene dienen.
