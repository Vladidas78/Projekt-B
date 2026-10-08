# Chat-Handover – Supportmanagement Board

## Datenschutz-Regel (gilt ab sofort, in jedem Chat)
Im Quellcode, in der Doku und im Chat stehen **keine** realen Personennamen, Anmelde-Kürzel, Bearbeiter-Kürzel, Kundenkürzel, Call-Nummern, Rechnernamen oder Pfade des Unternehmens. Erlaubt sind nur Spaltennamen, SQL-Namen (Tabellen, Felder, Statuswerte, Bearbeitergruppen) sowie „MPDV“ und die Begriffe „MPDV intern“, „USA“, „Asien“, „Europa“, weil die Logik daran hängt. Alles andere sind Dummywerte: Anmelde-Kürzel `SM1`, `SM2`, `DP1`, `DP2`; Bearbeiter `PD1…`, `SD1…`, `PM1…`; Kunden `ALPHA`, `BRAVO`, …; Call-Nummern ab 900000 (offen) und 800000 (geschlossen). Nennt der Nutzer im Chat reale Werte, werden sie in Antworten, Code und Doku nicht wiederholt. Die echten Stammdaten (Team, Personen, Verteiler) pflegt das Team in der Verwaltung des Boards; sie liegen nur in der Team-JSON auf dem Teamshare.

## Kontext & Aufgabe
Der Nutzer ist Supportmanager bei MPDV und entwickelt das „Supportmanagement Board“ iterativ weiter: eine Single-File-HTML-Anwendung (kein Server, kein Framework, SheetJS eingebettet) für Dispatcher und Supportmanager. Datenquelle ist eine CSV, die ein PowerShell-Export per lesender SQL-Abfrage aus der Omnitracker-Schattendatenbank schreibt; der Export läuft auf einem Testserver in der Aufgabenplanung (alle 10 Minuten, Konto SYSTEM). Haken, Kommentare und Stammdaten liegen in einer Team-JSON auf dem Teamshare.

## Aktueller Stand
Version **v1.44**, alles committet und gepusht auf Branch `claude/trusting-franklin-1ecqoi` im Repo `vladidas78/projekt-b` (enthält den Stand von `claude/clever-ritchie-jfsm8k`). Artefakt (immer mit `url` republishen, nie neu anlegen): `https://claude.ai/code/artifact/025f646d-502f-42c3-9629-b7d9ecbe2a3a`.

Quelle ist `board.html`; `python3 build.py` erzeugt daraus **genau zwei** Ausgaben, `SupportBoard.html` (prod) und `SupportBoard_Test.html` (Kanal sqltest, Beschriftung „Testversion“), dazu `board-artifact.html` (Artefakt, in .gitignore). Regel des Nutzers (2026-10-08): Die Testversion wird immer zuerst erprobt, die Produktivversion zieht nach. Feste Dateinamen, nie abweichen: `SupportBoard-Abfrage.sql`, `SupportBoard-Abfrage-Reaktion.sql`, `SupportBoard-Abfrage-Weiterleitung.sql`, `SupportBoard-Export-Server.ps1`, `SupportBoard.html`, `SupportBoard_Test.html`. Der lokale Export (`SupportBoard-Export.ps1`) ist abgeschafft. SheetJS liegt in `package/dist/xlsx.full.min.js`.

v1.41 enthält:
- Export liefert offene **und geschlossene Calls** (zwei Jahre) sowie die Spalte `Kundenbetreuung` (Werte wie `MPDV_Europe`, `MPDV_USA`, `MPDV_Asia` → Region Europa/USA/Asien). `allRows()` = nur offene; `closedRows()`/`alleZeilen()` für Statistiken. Status „zu“ in der Verwaltung (`rules.closedStatus`, Vorgaben Gelöst, Geschlossen, Abgeschlossen, Reviewer, Closed, Resolved, Solved sind immer enthalten; Wortanfang zählt, z. B. „Reviewer (intern)“). Verwaltung zeigt alle Statuswerte mit Einstufung und alle Regionsrohwerte mit Zuordnung; `rules.regionAsien`/`rules.regionUsa` ordnen unbekannte Werte zu.
- Statusgedächtnis `state.callStatus` (je Eröffnungsmonat, teamweit): Wiedereröffnungen → Hinweis „wieder offen“, Zähler in der Tagesstatistik.
- Tagesstatistik aus Eröffnungs- und Abschlussdatum (Abschluss = Spalte `Geschlossen`, sonst `Letzte_Änderung`).
- Top 10 (Dauer, älteste) mit Umschalter **Kunden / MPDV intern** (je Gerät, `uiPref.topScope`; Kunden fürs Montagsmeeting, intern für die Donnerstagsrunde), wählbare Spalten (`state.cols.top_dauer/top_alt`), kopierbare Tabelle, darunter „in der Vorwoche (Mo–So) geschlossen“: nur Calls, die in der Vorwoche in der Liste standen; Felder Call, Kunde, Eröffnet bzw. Aufwand, geschlossen am; je Woche eingefroren (`state.topGeschl[KW][kind_scope]`).
- Reaktionszeit im **Vollmodus**: live aus dem Export inkl. geschlossener Calls (kein Einfrieren, `perAusExport()`), Filter nach Region. Grundgesamtheit = Calls mit Wert in „Externe Reaktion“ (`slaBewertet()`: leer = nicht bewertet, 0 = noch keine Reaktion). **Hinweis kurz vor Frist** ab `rules.slaWarn` Minuten Geschäftszeit (Vorgabe Rot 60 = nach der 30-Min-Frist, Blau 210, Grün 2850): Zähler am Reiter, Fenstertitel, Hinweiszeile, optional Desktop-Benachrichtigung (`uiPref.slaNotify`), je Call einmal pro Sitzung, Prüfung je Datenstand und jede Minute.
- Mittwochsmail: Prio in Vorbereitung und OneNote-Tabelle (nicht in der Mail); fehlender LT nur gelb bei Weiterleitung > 14 Tage; Prüfhaken je Benutzer (`ackKey` → `call|mi|KÜRZEL`, keine Historie); „Alle ACK setzen/entfernen“; „neu“-Flag.
- „neu“-Flag in den Tageslisten (`state.wfSeen`); Textvorlagen DE und EN (`templates.teamsEn/wvlEn`, Knöpfe „Teams EN“/„WVL EN“); Protokoll ohne USA/Asien (Calls > 10 h und Kundenliste, `protoRelevant`).
- Mails auf einen Knopf (Text kopieren + `mailto:` mit An, CC, Betreff) plus `.eml`-Entwurf mit `X-Unsent: 1`; Einzelschritte eingeklappt.
- Reiter „Auslastung“ sichtbar für Kürzel aus `rules.auslastungFuer` (Vorgabe `SM1`). **Einmalig nötig:** Der Tool-Verantwortliche trägt sein echtes Kürzel in Verwaltung → Grundregeln → „Auslastung sichtbar für“ ein, sonst fehlt ihm der Reiter.
- Vorgabewerte der Reaktionszeit (`SLA_VORGABEN`) tragen keine SupMan-Kürzel mehr; die Spalte SupMan bleibt bei diesen Wochen leer.

v1.44 enthält:
- Rückläufer aus der Bearbeitung im Reiter „Weiterleitungen“ (`wlAbgaben`, `wlRueckStat`, Karte `#wlRueck`, fünfte Kennzahl, `wlAlleRl`): Abgabe Dispatcher/Hotline → Bearbeitungsgruppe nach Abgabedatum im Zeitraum, Ergebnis zurück/weiter/offen, Quote über beendete Abgaben, Ø Zeit bis Rückgabe, Call-Liste jüngste zuerst, Kopiertabellen. Demo: 14 % der Wege mit Schleife Dispatcher → 2nd/3rd → Dispatcher.

v1.43 enthält:
- Weiterleitungs-Historie als Textspalte `Weiterleitungen` (Option 3): dritte Abfrage `SupportBoard-Abfrage-Weiterleitung.sql` (Vorlage mit `STRING_AGG`, Platzhalter für Tabelle/Felder; **die echte SQL liefert der Nutzer nach**), Server-Skript mit allgemeinem Zusatzabfragen-Block (`$Zusatz`, `Lade-Zusatz`, `$Anhang`), Board `parseWlText()` + `datumAusWert()`. Blockformat `Datum|vorherige Gruppe|vorheriger Bearbeiter|aktuelle Gruppe|aktueller Bearbeiter|Folgestatus|Ersteller`, Blöcke mit ` # `. Mehrfachzeilen-Form (v1.42) bleibt erkannt.
- Nur noch zwei HTML-Ausgaben; alte Test-Ausgaben und lokaler Export entfernt. Kanal `sqltest` heißt jetzt „Testversion“ (Badge „TEST“), Team-Datei `SupportBoard-Team-SQLTest.json` und Speicherschlüssel unverändert.

v1.42 enthält:
- Weiterleitungs-Historie aus dem Export: je Weiterleitung eine Zeile (neue Spalten `Datum Weiterleitung`, `vorherige Gruppe`, `vorheriger Bearbeiter`, `aktuelle Gruppe`, `aktueller Bearbeiter`, `Folgestatus`, `Ersteller Weiterleitung`, `Weiterleitung Nr`, `Gesamtanzahl Weiterleitungen`; `Weiterleitung` → `Letzte_Weiterleitung`). `buendleWeiterleitungen()` macht daraus einen Call je Zeile mit `r.Wl`; `WlLueckig`, wenn weniger Zeilen als Gesamtanzahl kommen.
- Reiter **„Weiterleitungen“** (`renderWl`, `wlCalls`, `wlAufenthalte`, `wlPingPong`, `wlVerteilung`, `wlMonatsStat`): Kennzahlen, Ping-Pong-Calls (Schwelle `wlMin`), Liegedauer je Monat (Ø/Median je Stapel und bis Bearbeitung), Verteilung Dispatcher und Hotline/1st Level, Zeitraum `wlZeitraum`, Zeitmaß `uiPref.wlGz`, Filter `state.filters.wl` (intern ab Werk aus), Kopiertabellen. Eingangsstapel `rules.wlHotline` / `rules.wlDispatcher` in der Verwaltung. Spalte `COLS.wl` („Weiterl.“). Beispieldaten mit Wegen (`demoWl`). Doku in `tools/Anleitung_SQL-Export.md` (Spaltenvertrag) und Handbuch.
- **Offen:** Die SQL-Abfrage für die Historie schreibt das Team (Tabelle/Join im Omnitracker unbekannt); im Repo liegt keine Fassung. Nach dem ersten Lauf Gruppennamen der Eingangsstapel in der Verwaltung prüfen.

Server-Export `tools/SupportBoard-Export-Server.ps1` (UTF-8 mit BOM, CRLF, keine Gedankenstriche): optionale Zusatzabfragen `SupportBoard-Abfrage-Reaktion.sql` und `SupportBoard-Abfrage-Weiterleitung.sql` (je Spalte 1 Call, Spalte 2 Wert, weitere ignoriert) in eigener Verbindung, Wert wird über die Call-Nummer angehängt; Ausfall = WARNUNG, CSV kommt trotzdem. `-Preview` zeigt Spalten und „Reaktionswert fuer N von M Zeilen gefunden“. Der Lauf auf dem Server hat funktioniert (rund 10.000 Zeilen, 22 Spalten). Die Reaktionsabfrage legt die Grundgesamtheit fest und darf nicht auf `erste_ext_aktion_kalender > 0`, `e_bestaetigung_kalender > 0` oder eine Region filtern. Die Hauptabfrage im Repo (`tools/SupportBoard-Abfrage.sql`) enthält den `UNION ALL` auf `closed_calls` (dort fehlen `zugeordneter_supman`, `letzte_Weiterleitung`, `Anzahl_LT_Verschiebungen`, `nicht_auswerten_fuer_kd_kommunikation` → Leerwerte). Die Fassung auf dem Server enthält die realen internen Firmenkürzel in der Ausschlussliste; im Repo steht nur `'MPDV'` plus Kommentar.

## Wichtige Entscheidungen & Constraints
- Single-File-HTML bleibt. Kein Server, kein Framework, kein Build außer `build.py`.
- Skript darf nur lesen (Schlüsselwortprüfung, Rollback, ReadUncommitted). Bei Fehler bleibt die alte CSV stehen. Team-JSON fasst das Skript nie an.
- Keine Controlling-Begriffe („Haken gesetzt“) in Texten an Bearbeiter. ACK-Spalte der Mittwochsmail rein intern. MPDV = interner Kunde, Ausnahme überall. Keine Warnhinweise/Belehrungen im Tool.
- Keine Claude-/Modell-Spuren im Produkt; Commits tragen nur den vorgegebenen Trailer.
- Dokumente für Kollegen als Word/PDF liefern, nicht als Artefakt. Handbuch liegt nur als Markdown vor (docx/pdf wurden wegen enthaltener Namen entfernt; bei Bedarf aus `docs/Handbuch_SupportBoard.md` neu erzeugen).
- Reaktionszeit: Geschäftszeit Mo–Do 08:00–17:30, Fr 08:00–16:30, Feiertage unberücksichtigt. Start `Eröffnet`, Ende = Eröffnet + `Externe Reaktion` (Kalendertage, 4 Nachkommastellen ≈ 9 s Auflösung). Fristen Rot 30 Min., Blau 4 h, Grün 48 h. Vorgabewerte gewinnen für ihren Zeitraum. **Offen:** Die Zeiten weichen von der Excel-Liste des Teams ab; Verdacht: Excel rechnet Kalenderzeit, Board Geschäftszeit, dazu andere Grundgesamtheit. Klärung braucht einen Beispiel-Call (nur im Gespräch, nicht in Code/Doku) und die Info, ob `call_statistics` ein Feld in Geschäftszeit hat.
- Mail-Tabellen: `bgcolor` + Inline-Style + `<font color>`, Kopfzeile hell; Markierungen als Tabellen.
- Dateien immer unter ihrem Zielnamen liefern (`SupportBoard-Export-Server.ps1`, `SupportBoard-Abfrage.sql`, `SupportBoard-Abfrage-Reaktion.sql`, die drei HTML), ohne Versionszusatz.
- Sackgassen: PS1 ohne BOM → Parserfehler-Kaskade in Windows PowerShell 5.1. `Get-Content -Raw` liefert CRLF ins DPAPI-Passwort. Sandbox: LibreOffice defekt, `pdftoppm` fehlt; Playwright-core 1.63 mit Chromium `/opt/pw-browsers/chromium-1194/chrome-linux/chrome`, `--no-sandbox`, `file://`-URL. Geschäftszeit-Tests brauchen `now = () => new Date(2026, 9, 7, 12, 0)` (Werktag) im Seitenkontext.

## Artefakte / Code / Daten
Repo: `board.html` (Quelle), `build.py`, `package/dist/xlsx.full.min.js`, zwei HTML-Ausgaben, `docs/Status_Supportmanagement_Board.md` (Versionshistorie + feste Regeln, immer fortschreiben), `docs/Handover_Chat.md`, `docs/Handbuch_SupportBoard.md`, `docs/Anleitung_Serverbetrieb.md`, `docs/Anleitung_Parallelbetrieb_SQL-Test.md`, `docs/Anleitung_IT_SupportBoard.md`, `docs/Anleitung_Team_Browser.md`, `docs/IT-Ticket_Datenbereitstellung.md`, `tools/SupportBoard-Abfrage.sql`, `tools/SupportBoard-Abfrage-Reaktion.sql`, `tools/SupportBoard-Export.ps1`, `tools/SupportBoard-Export-Server.ps1`, `tools/*.vbs`, `tools/Anleitung_SQL-Export.md`.

Änderungen: in `board.html` per Python-Textersetzung (`assert s.count(old)==1`), dann `python3 build.py`, Smoke-Test (Demo laden, alle Reiter klicken, keine Konsolenfehler), `VERSION` bumpen. Artefakt: `board-artifact.html` mit `url` republishen.

Test-Muster: `loadDemo()` im Seitenkontext, Login `#loginList button:nth-child(1)` (SM1), Reiter `#tabs button`, Kanal-Badge `#kanalBadge`, Versionszeile `#verInfo`, Filterleiste `<details class="fpanel" data-fkey="…">`, ACK `[data-ack="<Call>"]`, Tabellen `tbody[data-wfbody="<wf>"] tr`. PS1-Prüfung ohne PowerShell: Klammerbalance per Python (Kommentare/Strings ausblenden).

Zentrale Bezeichner: `COLS` (mit `txt` fürs Kopieren), `COL_ORDER`, `WF_DEFAULT_COLS_BY` (inkl. `top_dauer/top_alt`), `wfCols()`, `normalizeState()`, `rowsSplit()/allRows()/closedRows()/alleZeilen()`, `istGeschlossen()`, `regionNorm()`, `kundenGruppen()/kundeInGruppe()/istUsaAsien()`, `recordCallStatus()`, `recordWfSeen()`, `topRows(kind, scope)`, `topGeschlWoche()`, `slaBewertet()`, `slaVollmodus()`, `ohneReaktionRows()` (mit `stufe`), `pruefeSlaMeldungen()`, `tabErlaubt()`, `mailButtons()/bindMailButtons()/emlDatei()`, `SHARED_MAPS`, `SHARED_CFG`, `KANAL`, `KANAL_INFO`, `LS_STATE`.

Score (SQL): Prio-Faktor (Rot 3, Blau 2, Grün 1) × Summe aus: Alter > 365 Tage +1; Dauer ≥ 20 +2, 10–19 +1; Stillstand ≥ 30 Tage +2, 14–29 +1; ≥ 6 LT-Verschiebungen +1; Wartend ohne gültiges WAKI-Datum +1; In Bearbeitung ohne LT und Weiterleitung > 7 Tage +1, LT 1–7 Tage überschritten +1, ≥ 8 Tage +2; LT überschritten mit Kd.-Komm.-Haken oder ohne LT +1. Kritisch ab 6.

Commit-Trailer (Pflicht, sonst nichts; Session-URL der jeweils aktuellen Session):
```
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: <URL der aktuellen Session>
```

## Offene Punkte / nächste Schritte
0. Wenn der Nutzer die fertige `SupportBoard-Abfrage-Weiterleitung.sql` durchgibt: gegen den Spaltenvertrag prüfen (zwei Spalten `Call`, `Weiterleitungen`, Blockformat, nur lesend, beginnt mit SELECT/WITH) und unter genau diesem Namen zurückliefern; nach dem ersten Export Reiter „Weiterleitungen“ und Verwaltung → Grundregeln (Gruppen der Eingangsstapel) prüfen.
1. Abweichung der Reaktionszeiten zur Excel-Liste klären (Beispiel-Call nachrechnen, Kalender- vs. Geschäftszeit, Feld in Geschäftszeit in `call_statistics`?). Danach entscheiden, ob die rote Frist 30 Minuten bleibt oder 1 h wird.
2. Regionsrohwerte prüfen (Verwaltung → Grundregeln → „Region: Werte der Abfrage“): gelbe Werte zuordnen oder fest in `regionNorm()` aufnehmen.
3. Tool-Verantwortlicher trägt sein Kürzel bei „Auslastung sichtbar für“ ein.
4. Handbuch bei Bedarf als Word/PDF aus dem Markdown neu erzeugen (Steckbrief ausfüllen).
5. Git-Historie enthält noch die alten Stände mit realen Namen; eine Bereinigung der Historie wurde nicht durchgeführt (nur auf ausdrücklichen Wunsch).
6. Aus der Status-Doku: OneNote-Link im PD-Fußtext (Platzhalter), Gelb-Schwelle Terminänderungen Freitagsmail (unbestätigt), Auslastung Dispatcher sobald die Abfrage Daten liefert.

## Bevorzugte Arbeitsweise des Nutzers
Deutsch, direkt, kurze Rückfragen nur wenn nötig. Selbstständig umsetzen, testen (Playwright), alle drei HTML-Dateien als Datei liefern (SendUserFile), Artefakt republishen, Ursachen erklären, Grenzen ehrlich benennen („ehrlich gesagt“ wird geschätzt). Bei Server-/PowerShell-Themen: fertige Befehlsfolgen in Reihenfolge, Platzhalter klar markiert, Fehlermeldungen wörtlich deuten; der Nutzer hat Zugriff auf den Server (Ordner und PowerShell als Administrator). Bei Skriptänderungen: sagen, welche Zeilen anzupassen sind, statt reflexartig neue Dateien zu schicken; die Einstellungen stehen oben im Block EINSTELLUNGEN. Bei Fragen nach Optionen: Optionen mit Empfehlung, dann auf Freigabe warten. Keine Rückfragen-Schleifen.

## Erste Aktion im neuen Chat
Repo-Stand prüfen (`git log --oneline | head -3` auf Branch `claude/trusting-franklin-1ecqoi`), Datenschutz-Regel oben beachten, dann die nächste Anforderung des Nutzers als v1.45 umsetzen (Version in `board.html` bumpen, drei Ausgaben bauen, Status-Doku fortschreiben, Dateien liefern, Artefakt republishen).
