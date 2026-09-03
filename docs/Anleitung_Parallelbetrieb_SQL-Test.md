# Parallelbetrieb: Testversion mit SQL-Export

Ziel: Die neue Datenversorgung (SQL-Abfrage per Skript statt Excel-Routine) **neben** dem laufenden Betrieb testen – ohne die Produktivversion, ihre Excel-Quelle oder ihre Team-Datei anzufassen.

## Aufbau

Zwei Orte, klar getrennt:

| Ort | Inhalt |
|---|---|
| **Lokal auf dem PC**, z. B. `C:\Tools\SupportBoard\` | `SupportBoard-Export.ps1`, `SupportBoard-Abfrage.sql`, danach automatisch `.pwd` (Passwort, verschlüsselt) und `.log` |
| **Testordner auf dem Share**, z. B. `\\Server\Freigabe\Supportmanagement\SQL-Test\` | `SupportBoard-SQLTest.html` (das Test-Board), `SupportBoard-Daten.csv` (schreibt das Skript), `SupportBoard-Team-SQLTest.json` (entsteht beim ersten Verbinden) |

Der bisherige Produktivordner mit `SupportBoard.html`, `SupportBoard-Team.json` und der Excel-Liste bleibt unverändert. Die Kollegen arbeiten dort weiter wie bisher.

## Was die Testversion anders macht

Die Datei `SupportBoard-SQLTest.html` ist dasselbe Board wie die Produktivversion, aber als eigener **Kanal** gebaut:

- **Eigener Browser-Speicher.** Haken, Kommentare, Einstellungen, Daten-Cache und die gemerkten Dateiverknüpfungen liegen unter eigenen Schlüsseln. Beide Boards können im selben Browser gleichzeitig offen sein und kommen sich nicht in die Quere.
- **Sichtbar markiert.** Gelbes Feld „TEST · SQL-Daten“ oben in der Seitenleiste, Fenstertitel „Testversion SQL“, Versionszeile „v1.27 · Testversion SQL“. Eine Verwechslung fällt sofort auf.
- **Einmalige Übernahme beim ersten Start.** Öffnet man die Testversion im selben Browser, in dem die Produktivversion läuft, übernimmt sie beim allerersten Start Personen, Vorlagen, Regeln, Haken, Kommentare und das angemeldete Kürzel. Danach laufen beide Stände getrennt weiter. Der Daten-Cache und die Dateiverknüpfungen werden **nicht** übernommen – die Testversion bekommt ihre eigene Quelle.
- **Eigene Team-Datei mit Kennung.** Die Testversion schlägt `SupportBoard-Team-SQLTest.json` vor und schreibt eine Kanal-Kennung hinein. Eine Team-Datei der Produktivversion nimmt sie nicht an: Wird versehentlich `SupportBoard-Team.json` gewählt, meldet sie das, merkt sich die Datei nicht und schreibt nichts. Umgekehrt lehnt die Produktivversion (ab v1.27) die Test-Team-Datei ab.
- **Auf den Export abgestimmt.** Prüfintervall der Dashboard-Datei standardmäßig alle 5 Minuten; bleibt die CSV länger als die eingestellte Schwelle unverändert, lautet der Hinweis „läuft der Export?“ statt der Excel-Frage.

## Schritt für Schritt (lokal, nur VKU)

**1. Ordner anlegen und Dateien ablegen**
`C:\Tools\SupportBoard\` mit Skript und Abfrage; Testordner auf dem Share mit `SupportBoard-SQLTest.html`.

**2. Skript-Einstellungen eintragen** (`SupportBoard-Export.ps1`, Block `EINSTELLUNGEN`)

```powershell
$Server      = '…'   # Data Source aus dem Excel-Verbindungsstring
$Datenbank   = '…'   # Initial Catalog
$WindowsAuth = $false   # oder $true, wenn das eigene Windows-Konto lesen darf
$Benutzer    = '…'   # User ID (nur bei $WindowsAuth = $false)
$Zielpfad    = '\\Server\Freigabe\Supportmanagement\SQL-Test\SupportBoard-Daten.csv'
```

**3. Passwort hinterlegen** (entfällt bei Windows-Authentifizierung)

```powershell
.\SupportBoard-Export.ps1 -SetPassword
```

**4. Testlauf ohne Datei**

```powershell
.\SupportBoard-Export.ps1 -Preview
```

Erwartet: eine plausible Zeilenzahl und **20 Spalten** mit genau diesen Namen: Prio, Call, Eröffnet, Gruppe, Bearbeiter, Kunde, Titel, SupMan, Status, Dauer, Weiterleitung, Letzte_Änderung, Wartend_bis, Lösung_bis, Terminänderungen, nicht werten für Kd.Komm., Letzte Info an Kd., Tage ohne Info an Kd., Letzte externe Reaktion, Score.

Kommt stattdessen ein Fehler wie „Invalid column name“ oder „Invalid object name“: Die Feldnamen in `SupportBoard-Abfrage.sql` stammen aus der Excel-Abfrage, nicht aus einer geprüften Schema-Doku. Dann den genannten Namen in der SQL an das echte Schema anpassen – die `AS`-Namen (der Vertrag zum Board) bleiben unverändert.

**5. Echter Lauf**

```powershell
.\SupportBoard-Export.ps1 -Jetzt
```

Danach liegt `SupportBoard-Daten.csv` im Testordner. Kurz im Editor öffnen: Kopfzeile wie oben, Umlaute lesbar, Datumsangaben im Format `2026-09-02T09:30:00`.

**6. Aufgabenplanung** (alle 15 Minuten, nur solange angemeldet, auch im Akkubetrieb) mit dem PowerShell-Block aus `tools/Anleitung_SQL-Export.md`, Schritt 6. Danach mit `schtasks /Run` einmal von Hand auslösen und im Log nachsehen.

**7. Test-Board einrichten**
`SupportBoard-SQLTest.html` aus dem Testordner per Doppelklick öffnen – im **selben Browser** wie die Produktivversion, dann ist der Stand sofort übernommen (Hinweis unten erscheint kurz).
- Verwaltung → **„Dashboard überwachen …“** → `SupportBoard-Daten.csv` im Testordner wählen.
- Verwaltung → **„Team-Speicher …“** → **„Neue Team-Datei erstellen“** → `SupportBoard-Team-SQLTest.json` im Testordner speichern. Das macht nur VKU einmal; Kollegen wählen später „Vorhandene Team-Datei auswählen“.
- Unten links beide Punkte grün, oben das gelbe Test-Feld: fertig.

**8. Vergleichen – die Checkliste**

Beide Boards nebeneinander (zwei Tabs). Abweichungen sind erwartbar, wenn der Excel-Stand und die CSV zu unterschiedlichen Zeiten gezogen wurden – sie müssen aber erklärbar sein.

- Übersicht: Anzahl Calls je Bereich (PD / SD / 2nd / 1st) gleich oder plausibel?
- Die fünf Tageslisten: dieselben Calls in derselben Reihenfolge? Zähler in der Seitenleiste vergleichen.
- Stichproben: bei 5 Calls Prio, Status, Dauer, LT, Terminänderungen, Haken, „Tage ohne Info“ und Score gegen die Excel-Liste prüfen.
- Datumsfelder mit Uhrzeit (Eröffnet, Letzte Änderung) – stimmt die Uhrzeit, keine Verschiebung um Stunden?
- Titel mit Sonderzeichen (Semikolon, Anführungszeichen, Umlaute) unversehrt?
- Reiter **„Reaktionszeit“**: erstmals mit echten Daten. Stehen in „Offen ohne erste Reaktion“ sehr viele Calls, meist Status *Wartend* / *Customer Care* per Filter-Chips ausblenden.
- Mittwochsmail-Vorschau: gleiche Langläufer wie in der Produktivversion?
- Nach 15–30 Minuten: aktualisiert sich der Dashboard-Punkt unten links von selbst („gepr. hh:mm“)? Ändert sich der Stand, wenn das Skript gelaufen ist?

**9. Kollegen dazuholen** (wenn Schritt 8 sauber ist)
Datei aus dem Testordner öffnen, Verwaltung → Dashboard überwachen (CSV) und Team-Speicher → „Vorhandene Team-Datei auswählen“ → `SupportBoard-Team-SQLTest.json`. Die Produktivversion läuft daneben unverändert weiter.

## Beide Versionen nebeneinander im Alltag

- Haken und Kommentare aus der Testversion landen **nur** in der Test-Team-Datei. Verbindliche Arbeit weiterhin in der Produktivversion.
- Beide Tabs dürfen offen bleiben; „Bei jedem Besuch zulassen“ gilt je Datei, also für jedes Board getrennt.
- Wird der Test beendet: Testordner löschen, fertig. Wird die Testversion zur neuen Produktivbasis, ist das eine eigene Entscheidung – dann wird der Kanal umgestellt und die Test-Team-Datei nicht weiterverwendet.

## Nächster Schritt: Skript auf den Server (bzw. Testserver)

Was gleich bleibt: Skript und Abfrage unverändert. Das Board merkt nichts davon – es liest weiterhin dieselbe CSV im Testordner.

Was sich ändert:

- **Ausführungskonto.** Die Aufgabe läuft auf dem Server unter einem technischen Konto, „unabhängig von der Benutzeranmeldung“. Dieses Konto braucht: lesenden Datenbankzugriff, Schreibrecht auf den Testordner, Leserecht auf den Skriptordner.
- **Passwort neu hinterlegen.** Die verschlüsselte `.pwd` ist an Konto **und** Rechner gebunden – sie lässt sich nicht mitnehmen. Auf dem Server einmal **als das Ausführungskonto** `-SetPassword` ausführen. Mit Windows-Authentifizierung (`$WindowsAuth = $true`) entfällt das komplett – auf einem Server die sauberere Variante.
- **Log erreichbar machen.** Das Log liegt neben dem Skript. Damit man es vom Arbeitsplatz aus lesen kann, `$LogDatei` in den Testordner legen, z. B. `'\\Server\Freigabe\Supportmanagement\SQL-Test\SupportBoard-Export.log'`.
- **Doppelt läuft nichts kaputt.** Bleibt die lokale Aufgabe versehentlich aktiv, sorgt `$NurWennAelterAlsMin` dafür, dass nur eine Instanz tatsächlich schreibt. Sauberer ist es, die lokale Aufgabe zu deaktivieren, sobald der Server läuft.
- **Aufruf** in der Aufgabenplanung wie gehabt: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "PFAD\SupportBoard-Export.ps1"`. Sprache und Zeitzone des Servers spielen keine Rolle, die CSV wird kulturunabhängig geschrieben.

## Was nicht garantiert werden kann

- Die Feldnamen in der SQL sind aus der Excel-Abfrage abgeleitet. Ob sie am echten Schema stimmen, zeigt erst der erste `-Preview`.
- Die Übernahme des Produktivstands beim ersten Start klappt nur im selben Browser und Browser-Profil. Sonst startet die Testversion leer – dann Verwaltung → „Sicherung laden …“ mit einer Sicherung aus der Produktivversion.
- Boards vor v1.27 kennen die Kanal-Kennung nicht. Würde jemand mit v1.26 die Test-Team-Datei als Team-Speicher wählen, würde sie gemischt. Schutz dagegen: eigener Name und eigener Ordner – und die Kollegen erst in Schritt 9 dazuholen.
