# Chat-Handover

## Kontext & Aufgabe
VKU (Vladimir Kulakow, Supportmanager MPDV) entwickelt das „Supportmanagement Board“ iterativ weiter: eine Single-File-HTML-Anwendung (kein Server, kein Framework, SheetJS eingebettet) für Dispatcher und Supportmanager. Datenquelle ist ein CSV-Export aus der Omnitracker-Schattendatenbank (PowerShell-Skript, nur lesend, alle 15 Min. per Aufgabenplanung). Team-Sync über eine gemeinsame JSON auf dem Share (File System Access API). Produktiv- und Testversion („Testversion SQL“) laufen parallel mit getrennten Speicherschlüsseln.

## Aktueller Stand
Version **v1.40**, alles committet und gepusht auf Branch `claude/letzte-info-spalte-b48dqp` (baut auf `claude/support-board-handover-jbau3c` = v1.39 auf) im Repo `vladidas78/projekt-b`. Artefakt-URL (immer mit `url` republishen, nie neu anlegen): `https://claude.ai/code/artifact/025f646d-502f-42c3-9629-b7d9ecbe2a3a`.

Seit v1.26 in dieser Sitzung gebaut:
- v1.27 Kanaltrennung prod/sqltest (`KANAL`, Suffix `_sqltest` an allen Speicherschlüsseln, Team-Datei trägt `kanal`)
- v1.28 Spalten verschieben, teamweite Sortierung, mehr Gruppen filterbar, Filterleiste zuklappbar, Startseiten-Trends (Auslastung 2nd Level je MA, Tagesstatistik neu/geschlossen, Top 10 Dauer, Top 10 Eröffnung), ACK-Zeilen ans Listenende, Reiter „Kritische Calls“ mit ACK/Kommentar
- v1.29 Top 10: „in 7 Tagen geschlossen“, Tabelle kopieren; Mail-Kopfzeile hell (#d9e2f3); Clipboard `unsanitized`
- v1.30 Markierungen [gelb]/[rot] als Ein-Zellen-Tabellen mit `bgcolor` (Outlook); Tagesaufgabe „Mail an Unterstützungsdienste“ (IMP, SAP-CC, CONS), Empfänger manuell, CC in Verwaltung, Texte unter „Vorlagen“
- v1.31 Warnung im Vorlagen-Editor entfernt; Mailvorlagen nach „Vorlagen“
- v1.32–v1.35 Reiter „Reaktionszeit“: erste externe Reaktion, %SLA (Rot 30 Min., Blau 4 h, Grün 48 h), Wochen-/Monats-/Jahresstatistik wie Montagsmeeting-Excel, Bruchliste mit Prio/Call/Kommentar, SupMan-Spalte nur in der Kopie, Vorgabewerte `SLA_VORGABEN` aus dem Screenshot, Filter (MPDV/Kunden-Ausschluss), nach Wochenende nur Summen behalten (`state.reaktAgg`)
- v1.36 SaaS-Kunden als Chip unter „Sonstiges“, Kürzel in Verwaltung
- v1.37 Reaktionszeit nur in Geschäftszeit (Mo–Do 08:00–17:30, Fr 08:00–16:30); Kundengruppen USA/Asien wie SaaS, in Reaktionszeit ab Werk ausgeblendet
- v1.38 Reiter „Keine ext. Reaktion“ entfernt (nur erste Reaktion zählt, danach Controlling-Listen)
- v1.39 frisch bestätigte ACK-Zeilen bleiben oben, bis ACK-Details zugeklappt werden oder der Reiter wechselt (`frischAcks`, nur Sitzung)
- v1.40 Spalte „Letzte Info an Kd.“ (`letzteinfo`, Datum aus dem Export) in den Tageslisten; Standard in „Ohne Kd.-Komm.“ vor „o. Info“, einmalige Ergänzung gespeicherter Auswahlen per `state.cols.v40` in `normalizeState()`

Skript-Betrieb (`tools/SupportBoard-Export.ps1`): Passwort per DPAPI-Datei (`-SetPassword`), `-Preview` zum Testen, Aufgabenplanung per `Register-ScheduledTask` (Batteriebetrieb erlaubt), stiller Start über `tools/SupportBoard-Export-leise.vbs`. Skript liest ausschließlich (ein SELECT, Schlüsselwortprüfung, ReadUncommitted, Rollback, Leserecht-Konto) – es kann nichts in die Schattendatenbank schreiben.

## Wichtige Entscheidungen & Constraints
- Single-File-HTML bleibt. Kein Server, kein Framework, kein Build außer `build.py`.
- Skript darf nur lesen. „Es darf nichts kaputt machen.“
- Keine Controlling-Begriffe („Haken gesetzt“ o. ä.) in Texten an Bearbeiter. Nie wieder einbauen.
- ACK-Spalte der Mittwochsmail ist rein intern. Reiter „Auslastung“ nur für VKU. MPDV = interner Kunde, Ausnahme überall.
- Keine Claude-/Modell-Spuren im Produkt (Code, Doku, Commit-Text); Commits tragen nur den vorgegebenen Trailer.
- Vergangenheit der Reaktionszeit ist uninteressant: nach Wochenende bleiben nur Durchschnitte, Call-Details fallen weg. Vorgabewerte (ohne Fallzahlen) gewinnen für ihren Zeitraum.
- Feiertage werden bei der Geschäftszeit nicht berücksichtigt (bekannt, akzeptiert).
- Mail-Tabellen: `bgcolor` + Inline-Style + `<font color>`, Kopfzeile hell. Text-Hintergründe verwirft Outlook, deshalb Markierungen als Tabellen.
- Warnhinweise/Belehrungen im Tool sind unerwünscht („Das hat im Tool nichts verloren“).
- Sackgassen: `schtasks /TR` mit `\"` aus PowerShell zerlegt den Pfad; `-WindowStyle Hidden` blitzt trotzdem; `Get-Content -Raw` liefert CRLF ins DPAPI-Passwort.

## Artefakte / Code / Daten
Repo `/home/user/Projekt-B`: `SupportBoard.html`, `SupportBoard-SQLTest.html`, `docs/Status_Supportmanagement_Board.md` (Versionshistorie + feste Regeln, immer fortschreiben), `docs/Anleitung_Parallelbetrieb_SQL-Test.md`, `docs/Anleitung_IT_SupportBoard.md`, `docs/Anleitung_Team_Browser.md`, `docs/IT-Ticket_Datenbereitstellung.md`, `tools/SupportBoard-Abfrage.sql`, `tools/SupportBoard-Export.ps1`, `tools/SupportBoard-Export-leise.vbs`, `tools/Anleitung_SQL-Export.md`.

Quelle und Werkzeuge liegen im Scratchpad (nach Sitzungsende weg, dann aus `SupportBoard.html` rekonstruieren: Quelle = Body ohne `<!doctype>`/`<html>`/`<head>`-Hülle, SheetJS durch `/*__SHEETJS__*/` ersetzen, `const KANAL = "prod"; /*__KANAL__*/`): `board.html` (Quelle, `const VERSION = "1.40"`), `build.py`, `package/dist/xlsx.full.min.js`, Tests `test-kanal-v127.js`, `test-v128.js`, `test-v129.js`, `test-v130.js`, `test-v132.js`, `test-v136.js`, `test-v139.js` (Playwright-core, Chromium `/opt/pw-browsers/chromium`, `--no-sandbox`), `Testdaten_SQL-Export.csv`.

`build.py`:
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
print('gebaut: SupportBoard.html, SupportBoard-SQLTest.html, board-artifact.html')
```

Test-Muster: Login VKU `#loginList button:nth-child(4)`, Beispieldaten `#btnDemo`, CSV `#fileAll`; Filterleiste `<details class="fpanel" data-fkey="…">` vor Klicks mit `.open = true` öffnen; Kundengruppen-Chips `[data-fkg="lt|saas"]`, Verwaltungsfelder `[data-cfg="saasKunden"]`/`usaKunden`/`asiaKunden`; ACK `[data-ack="<Call>"]`, Details `[data-atgl="<Call>"]`, Grund `[data-acknote="<Call>"]`; Reiter `#tabs button`.

Zentrale Bezeichner im Code: `state.reakt["YYYY-MM"][call] = {e,r,p,k,g,b}`, `state.reaktAgg["W<Montag>"|"M<YYYY-MM>"|"J<Jahr>"] = {rot,blau,grün,ges:{n,sum,ok,brk,unb}, liste?, fix?, sm?}`, `state.slaNote`, `SLA_VORGABEN`, `EXT_LIMITS`, `GESCHAEFTSZEIT = {1..4:[8,17.5], 5:[8,16.5]}`, `geschaeftszeit(a,b)`, `KUNDENGRUPPEN`, `kundenListe(feld)`, `isKundeIn(r,feld)`, `filters.sla.{intern,hxmp,usa,asia,kunden,v37}`, `recordReakt()`, `freezeReakt()`, `slaStat()`, `slaGebrochen()`, `slaPerioden()`, `applyTableUI()`, `openAcks`, `frischAcks`, `SHARED_MAPS`/`SHARED_CFG`, `state.touch`, `saveState()`.

SQL-Feld: `cs.erste_ext_aktion_kalender / 86400.0 AS [Externe Reaktion]` (Kalendertage ab Eröffnung, 0 = noch keine Reaktion). Export enthält nur offene Calls.

Commit-Trailer (Pflicht, sonst nichts):
```
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01P7W6v3csZhLqctX666nyvt
```

## Offene Punkte / nächste Schritte
1. Nächste Woche: Export-Skript vom Notebook auf den (Test-)Server verlagern (Aufgabenplanung dort neu anlegen, DPAPI-Passwortdatei muss auf dem Server unter dem Dienstkonto neu erzeugt werden). Anleitung: `docs/Anleitung_Parallelbetrieb_SQL-Test.md`.
2. Vergleich Test vs. Produktiv nach Checkliste, dann Umstellung der Kollegen auf die SQL-Version.
3. Auslastung Dispatcher, sobald die Abfrage Daten dafür liefert.
4. Verwaltung: Kürzel der SaaS-/USA-/Asien-Kunden eintragen (Listen sind ab Werk leer, Chips wirken erst dann).
5. Offen aus Status-Doku: OneNote-Link im PD-Fußtext (Platzhalter), Gelb-Schwelle Terminänderungen Freitagsmail (unbestätigt).

## Bevorzugte Arbeitsweise des Users
Deutsch, direkt, kurze Rückfragen nur wenn nötig. Selbstständig umsetzen, testen (Playwright), beide HTML-Dateien als Datei liefern, Artefakt republishen, Ursachen erklären, Grenzen ehrlich benennen. Bei Fragen nach Optionen: Optionen mit Empfehlung, dann auf Freigabe warten. Keine Rückfragen-Schleifen.

## Erste Aktion im neuen Chat
Repo-Stand prüfen (`git log --oneline | head -3` auf Branch `claude/letzte-info-spalte-b48dqp`, HEAD = v1.40), `board.html` aus `SupportBoard.html` rekonstruieren, falls das Scratchpad leer ist, und dann auf den nächsten Wunsch von VKU warten. Nächste Version ist v1.41.
