# Chat-Handover

## Kontext & Aufgabe
VKU (Vladimir Kulakow, Supportmanager MPDV) entwickelt das „Supportmanagement Board“ iterativ weiter: eine Single-File-HTML-Anwendung (kein Server, kein Framework, SheetJS eingebettet) für Dispatcher und Supportmanager. Datenquelle ist eine CSV, die ein PowerShell-Export per lesender SQL-Abfrage aus der Omnitracker-Schattendatenbank schreibt. Haken/Kommentare/Stammdaten liegen in einer Team-JSON auf dem Teamshare. Der Export läuft seit dieser Sitzung auf dem OT-Testserver statt auf dem Notebook von VKU.

## Aktueller Stand
Version **v1.40**, alles committet und gepusht auf Branch `claude/letzte-info-spalte-b48dqp` (baut auf `claude/support-board-handover-jbau3c` = v1.39 auf) im Repo `vladidas78/projekt-b`. Artefakt-URL (immer mit `url` republishen, nie neu anlegen; Wake-Abo ist in diesen Sessions nicht möglich, egal): `https://claude.ai/code/artifact/025f646d-502f-42c3-9629-b7d9ecbe2a3a`, dort steht v1.40 (sqltest-Build).

In dieser Sitzung gebaut:
- **v1.40** Spalte „Letzte Info an Kd.“ (`letzteinfo`, Datum aus Export-Feld `LetzteInfo`) im Spalten-Register `COLS`, in `COL_ORDER` vor `info`; Standard in `WF_DEFAULT_COLS_BY.kdkomm` vor „o. Info“; einmalige Ergänzung bereits gespeicherter Auswahlen in `normalizeState()` per Flag `state.cols.v40`; Demo-Daten liefern `LetzteInfo` passend zu `TageOhneInfo`. In allen HTML-Ausgaben.
- **`SupportBoard-Testserver.html`**: dritte Ausgabe. Technisch identisch mit `SupportBoard-SQLTest.html` (`KANAL = "sqltest"` bleibt → gleicher Browser-Speicher, nimmt die kopierte `SupportBoard-Team-SQLTest.json` an). Nur Beschriftung: `<title>` „Supportmanagement Board – Testserver-Version“, `KANAL_INFO.sqltest.name` „Testserver-Version“, `badge` „TEST · TESTSERVER“, `kanalName()` → „Testserver-Version“, Parallelbetrieb-Text. VKU legt sie im Zielordner als `SupportBoard.html` ab; die JSON wurde dorthin kopiert.
- **Server-Export `tools/SupportBoard-Export-Server.ps1`** (UTF-8 **mit BOM**, CRLF, keine Gedankenstriche): Schalter `-ErsatzEinrichten` (Ordner, NTFS-Rechte, SMB-Freigabe nur lesend), `-SetPassword` (DPAPI LocalMachine, Base64, ACL auf Admins/SYSTEM/Dienstkonto), `-Preview`, `-Install` (Aufgabe alle `$IntervallMin`, `-WindowStyle Hidden`, Dienstkonto/gMSA/SYSTEM, Probelauf mit Log-Ausgabe), `-Status`, `-Jetzt`, `-Uninstall`. Schreibt CSV lokal in Temp, dann atomar an `$Zielpfad` und optional `$ZielpfadErsatz`; scheitert nur ein Ziel → WARNUNG, keins → FEHLER. Bei leerem `$ZielpfadErsatz` gibt `-ErsatzEinrichten` den Ordner von `$Zielpfad` frei. Einstellungsprüfung am Anfang nennt fehlende Variablen. Log in beiden Zielordnern, Fehler ins Ereignisprotokoll (Quelle `SupportBoard-Export`). Reserve-Starter `tools/SupportBoard-Export-Server-leise.vbs`.
- **Doku**: `docs/Anleitung_Serverbetrieb.md` (Ablage-Empfehlung, Fallback, Einrichtung, Fehlerbilder, „Kein schwarzes Fenster“), `docs/Handbuch_SupportBoard.md` + `.docx` + `.pdf` (für Kollegen bei Abwesenheit von VKU; Steckbrief am Anfang ist noch auszufüllen; Word-Inhaltsverzeichnis erst nach Strg+A, F9 gefüllt), Status-Doku und `tools/Anleitung_SQL-Export.md` fortgeschrieben.

**Realer Serverstand (von VKU gemeldet):** Skriptordner `E:\SupMan` auf dem OT-Testserver, SQL-Anmeldung (`$WindowsAuth = $false`, `-SetPassword` gemacht), **kein Schreibrecht auf den Teamshare** → CSV liegt auf dem Server, `$Zielpfad = '<lokaler Pfad>\SupportBoard-Daten.csv'`, `$ZielpfadErsatz = ''`, `$Dienstkonto = ''` (SYSTEM), Freigabe per `-ErsatzEinrichten` (`\\SERVER\SupportBoard`). `-ErsatzEinrichten`, `-SetPassword`, `-Preview` liefen; `-Install` „scheint jetzt erstmal zu laufen“. Teamshare-Ordner (Board + JSON): `Y:\MyOrg\SupportServices\Supportmanagement\SupportManagementTool` (Laufwerksbuchstabe nur am Arbeitsplatz; UNC dahinter per `Get-PSDrive Y | Select DisplayRoot`). Vor jedem Skriptaufruf auf dem Server nötig: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`.

## Wichtige Entscheidungen & Constraints
- Single-File-HTML bleibt. Kein Server, kein Framework, kein Build außer `build.py`.
- Skript darf nur lesen. „Es darf nichts kaputt machen.“ Dreifach abgesichert (Schlüsselwortprüfung, Rollback, ReadUncommitted); bei Fehler bleibt die alte CSV stehen.
- Team-JSON bleibt immer auf dem Teamshare; das Skript fasst sie nie an.
- Keine Controlling-Begriffe („Haken gesetzt“ o. ä.) in Texten an Bearbeiter. Nie wieder einbauen.
- ACK-Spalte der Mittwochsmail ist rein intern. Reiter „Auslastung“ nur für VKU. MPDV = interner Kunde, Ausnahme überall.
- Keine Claude-/Modell-Spuren im Produkt (Code, Doku, Commit-Text); Commits tragen nur den vorgegebenen Trailer.
- Dokumente für Kollegen als Word/PDF liefern, **nicht** als Artefakt (VKU ausdrücklich).
- Reaktionszeit: nur erste Reaktion, Geschäftszeit Mo–Do 08:00–17:30, Fr 08:00–16:30, Feiertage unberücksichtigt (akzeptiert). Vorgabewerte gewinnen für ihren Zeitraum.
- Mail-Tabellen: `bgcolor` + Inline-Style + `<font color>`, Kopfzeile hell. Markierungen als Tabellen, weil Outlook Text-Hintergründe verwirft.
- Warnhinweise/Belehrungen im Tool sind unerwünscht.
- Sackgassen: PS1 **ohne BOM** → Windows PowerShell 5.1 liest ANSI, „–“ zerfällt und ein Teilzeichen gilt als Anführungszeichen → Parserfehler-Kaskade. `schtasks /TR` mit `\"` aus PowerShell zerlegt den Pfad. `Get-Content -Raw` liefert CRLF ins DPAPI-Passwort. In der Sandbox: LibreOffice defekt (kann nicht mal .txt konvertieren), `pdftoppm` fehlt → docx nur per XML-Rücklesen prüfbar, PDF per Chromium-Druck aus HTML. Google Fonts im Sandbox-Chromium blockiert (Fallback greift).

## Artefakte / Code / Daten
Repo `/home/user/Projekt-B`: `SupportBoard.html` (prod), `SupportBoard-SQLTest.html`, `SupportBoard-Testserver.html`, `docs/Status_Supportmanagement_Board.md` (Versionshistorie + feste Regeln, immer fortschreiben), `docs/Handover_Chat.md`, `docs/Handbuch_SupportBoard.{md,docx,pdf}`, `docs/Anleitung_Serverbetrieb.md`, `docs/Anleitung_Parallelbetrieb_SQL-Test.md`, `docs/Anleitung_IT_SupportBoard.md`, `docs/Anleitung_Team_Browser.md`, `docs/IT-Ticket_Datenbereitstellung.md`, `tools/SupportBoard-Abfrage.sql`, `tools/SupportBoard-Export.ps1` (Arbeitsplatz), `tools/SupportBoard-Export-Server.ps1`, `tools/SupportBoard-Export-leise.vbs`, `tools/SupportBoard-Export-Server-leise.vbs`, `tools/Anleitung_SQL-Export.md`.

**Build in dieser Sitzung ohne `board.html`-Quelle:** Änderungen per Python-Textersetzung (`assert s.count(old)==1; s=s.replace(old,new)`) in allen drei HTML-Dateien parallel; `VERSION` in jeder bumpen. Artefakt-Datei: Body von `SupportBoard-SQLTest.html` zwischen `<body>\n` und `\n</body>`, davor `<title>Supportmanagement Board</title>\n`, `�` → `\\ufffd`. Testserver-Ausgabe aus SQLTest durch die fünf Ersetzungen oben. Wer sauber weiterbauen will: `board.html` aus `SupportBoard.html` rekonstruieren (Body ohne Hülle, SheetJS durch `/*__SHEETJS__*/`, `const KANAL = "prod"; /*__KANAL__*/`) und `build.py` um die Testserver-Ausgabe ergänzen:
```python
content = open('board.html', encoding='utf-8').read()
sheetjs = open('package/dist/xlsx.full.min.js', encoding='utf-8').read()
def wrap(body_src, title):
    body = body_src.replace('/*__SHEETJS__*/', sheetjs).replace('<title>Supportmanagement Board</title>\n', '', 1)
    return ('<!doctype html>\n<html lang="de">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n'
            f'<title>{title}</title>\n</head>\n<body>\n' + body + '\n</body>\n</html>\n')
test_src = content.replace('const KANAL = "prod"; /*__KANAL__*/', 'const KANAL = "sqltest";')
open('SupportBoard.html', 'w', encoding='utf-8').write(wrap(content, 'Supportmanagement Board'))
open('SupportBoard-SQLTest.html', 'w', encoding='utf-8').write(wrap(test_src, 'Supportmanagement Board – Testversion SQL'))
art = test_src.replace('/*__SHEETJS__*/', sheetjs.replace('�', '\\ufffd'))
open('board-artifact.html', 'w', encoding='utf-8').write(art)
```
SheetJS: aus `SupportBoard.html` extrahieren (erster `<script>`-Block, beginnt mit `/*! xlsx.js`).

Test-Muster (Playwright-core im Scratchpad per `npm i playwright-core`, Chromium `/opt/pw-browsers/chromium-1194/chrome-linux/chrome`, `--no-sandbox`, `file://`-URL): `loadDemo()` im Page-Kontext, Liste per `[...document.querySelectorAll('button')].find(e => /Kd\.-Komm/.test(e.textContent)).click()`, Tabellenkopf `thead th`, Zeilen `tbody[data-wfbody="kdkomm"] tr`, Login VKU `#loginList button:nth-child(4)`, CSV `#fileAll`; Filterleiste `<details class="fpanel" data-fkey="…">` vor Klicks `.open = true`; ACK `[data-ack="<Call>"]`, Details `[data-atgl="<Call>"]`, Grund `[data-acknote="<Call>"]`; Reiter `#tabs button`; Kanal-Badge `#kanalBadge`, Versionszeile `#verInfo`. PS1-Prüfung ohne PowerShell: Klammer-/String-Balance per Python-Skript (Kommentare/Strings ausblenden, `()`/`{}`/`[]` zählen).

Zentrale Bezeichner: `COLS`, `COL_ORDER`, `WF_DEFAULT_COLS`, `WF_DEFAULT_COLS_BY`, `wfCols()`, `normalizeState()`, `state.cols`, `WF` (Tageslisten krit/lt/kdkomm/aender/haken/wartend), `TABS`, `KANAL`, `KANAL_INFO`, `kanalName()`, `kanalPasst()`, `LS_STATE = "smbState_v1" + suffix`, `state.reakt`, `state.reaktAgg`, `SLA_VORGABEN`, `GESCHAEFTSZEIT`, `applyTableUI()`, `openAcks`, `frischAcks`, `saveState()`, `loadDemo()`, `tageOhneInfo(r)`, `daysSince()`.

Score (SQL): Prio-Faktor (Rot 3, Blau 2, Grün 1) × Summe aus: Alter > 365 Tage +1; Dauer ≥ 20 +2, 10–19 +1; Stillstand ≥ 30 Tage +2, 14–29 +1; ≥ 6 LT-Verschiebungen +1; Wartend ohne gültiges WAKI-Datum +1; In Bearbeitung ohne LT und Weiterleitung > 7 Tage +1, LT 1–7 Tage überschritten +1, ≥ 8 Tage +2; LT überschritten mit Kd.-Komm.-Haken oder ohne LT +1. Kritisch ab 6.

Commit-Trailer (Pflicht, sonst nichts; Session-URL der jeweils aktuellen Session verwenden):
```
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01KNTqyNPYAiwmUDotPThWWg
```

## Offene Punkte / nächste Schritte
1. VKU bringt neue Verbesserungen und Änderungen mit (Inhalt noch unbekannt) → als v1.41 in alle drei HTML-Ausgaben, Status-Doku fortschreiben, drei Dateien liefern, Artefakt republishen.
2. Server: Ausgabe von `-Status` nach den ersten Läufen zurückmelden lassen; lokale Aufgabe „Supportboard Datenexport“ auf dem Notebook deaktivieren (`Disable-ScheduledTask`); prüfen, ob `\\SERVER\SupportBoard` vom Arbeitsplatz erreichbar ist (sonst Port 445 / IT).
3. Umstellung der Kollegen auf die Testserver-Version (Dashboard überwachen → Server-Freigabe, Team-Speicher → JSON im Teamshare-Ordner); Handbuch-Steckbrief ausfüllen und Handbuch im Teamordner ablegen.
4. Auslastung Dispatcher, sobald die Abfrage Daten dafür liefert.
5. Verwaltung: Kürzel der SaaS-/USA-/Asien-Kunden eintragen (ab Werk leer).
6. Offen aus Status-Doku: OneNote-Link im PD-Fußtext (Platzhalter), Gelb-Schwelle Terminänderungen Freitagsmail (unbestätigt).

## Bevorzugte Arbeitsweise des Users
Deutsch, direkt, kurze Rückfragen nur wenn nötig. Selbstständig umsetzen, testen (Playwright), **alle drei HTML-Dateien** als Datei liefern (SendUserFile), Artefakt republishen, Ursachen erklären, Grenzen ehrlich benennen („ehrlich gesagt“ wird geschätzt). Bei Server-/PowerShell-Themen: fertige Befehlsfolgen in Reihenfolge, Platzhalter klar markiert, Fehlermeldungen des Users wörtlich deuten. Bei Fragen nach Optionen: Optionen mit Empfehlung, dann auf Freigabe warten. Keine Rückfragen-Schleifen. Bei Skriptänderungen nach einer Fehlermeldung: sagen, welche Zeilen anzupassen sind, statt reflexartig neue Dateien zu schicken (VKU hat seine Einträge dann jedes Mal neu zu übernehmen).

## Erste Aktion im neuen Chat
Repo-Stand prüfen (`git log --oneline | head -3` auf Branch `claude/letzte-info-spalte-b48dqp`, HEAD = v1.40 + Handover), dann auf die Liste der Verbesserungen und Änderungen von VKU warten und sie als v1.41 umsetzen. Nächste Version ist v1.41.
