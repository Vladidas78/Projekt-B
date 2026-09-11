# Status: Supportmanagement Board

**Stand:** v1.41 · funktional komplett · Export läuft auf dem OT-Testserver (Aufgabenplanung, SYSTEM) · 2026-09-11

## Was ist das?

Eine eigenständige Single-File-HTML-Anwendung (`SupportBoard.html`) für das SupMan-Controlling bei MPDV. Kein Server, keine Systemanbindung, keine Installation — die Datei wird lokal im Browser geöffnet und liest die Abfrageliste (Excel oder die CSV des SQL-Exports) direkt ein.

Seit v1.27 entstehen aus einem Quellcode zwei Ausgaben: `SupportBoard.html` (Produktivversion) und `SupportBoard-SQLTest.html` (Testversion mit eigenem Speicher, siehe `docs/Anleitung_Parallelbetrieb_SQL-Test.md`).

## Kernfunktionen

- **6 Tageslisten:** Kritische Calls, Überschrittene LTs, Ohne Kd.-Kommunikation, Ohne Änderung, LT ohne Kd.-Info (Haken), Wartend ohne Datum
- **Startseite:** Kennzahlen mit Vortagstrend, Tagesstatistik (neu/geschlossen/offen über 14 Tage), Auslastung 2nd Level je Bearbeiter, Top 10 nach Dauer, Top 10 am längsten offen
- **Mittwochsmail-Generator:** Langläufer >10h, getrennt als Mail 1 (PD/ProdM) und Mail 2 (SD), mit Outlook-festen Farben
- **Freitagsmail-Generator** mit Wochenauswertung
- **OneNote-Tabelle** (mit leerer Verbleib-Spalte zum Ausfüllen)
- **Reaktionszeit (SLA):** erste externe Reaktion gegen Rot 30 Min. / Blau 4 Std. / Grün 48 Std., Wochen- und Monatsdurchschnitte, Brüche mit Kommentar, Kopieren fürs Protokoll
- **Mail an Unterstützungsdienste** (Tagesaufgabe Dispatcher): je Dienst die offenen Calls seiner Gruppe als fertige Mail, Empfänger manuell, CC aus der Verwaltung
- **Team-Sharing ohne Server:** gemeinsame JSON auf dem Share, Merge nach Newest-wins
- **ACK-Workflow:** Bestätigungen mit Grund, Zeitstempel und „geändert!“-Verweis, wenn sich der überwachte Teil eines Tickets danach ändert
- **Kommentare** mit Zeitstempel und Autor, lange Kommentare zuklappbar
- **Spaltenauswahl und -reihenfolge je Liste** (teamweit gespeichert), Sortierung teamweit, eigene sortier-/filterbare Prio-Spalte; bestätigte (ACK) Zeilen stehen am Listenende (frisch bestätigte erst nach dem Zuklappen der Details)
- **Filter-Chips:** Status, Bearbeitergruppe, Prio, „MPDV-Calls ausblenden“, „SaaS“/„USA“/„Asien“ (Kundenlisten aus der Verwaltung)
- **Quellen-Status** (PD/SD/Team) mit Ampel und Prüfzeit in der Sidebar, große Ansicht in der Verwaltung
- **Auto-Resume:** erster Klick nach dem Öffnen setzt Datei-Überwachung und Team-Speicher fort

## Versionshistorie (Auszug)

| Version | Inhalt |
|---|---|
| v1.8 | Formatierte Mailtexte ([gelb]/[rot]/[fett]…), editierbare Fußtexte, kompakter Quellen-Status |
| v1.9 | Outlook-feste Mailfarben, Fußtexte PD/SD getrennt, Spalten-Registry + Spaltenauswahl, Prio-Spalte, OK→ACK, MPDV-Filter-Chip, SupMan-Badge, Auto-Resume |
| v1.9.1 | ACK-Zeitstempel, zuklappbare ACK-Details |
| v1.10 | Neue Tagesliste „Wartend o. Datum“, PD-LTs nicht auf Freitag gelb markiert |
| v1.11 | Eine gemeinsame Dashboard-Quelle für alle Gruppen, Filtergruppen-Editor, ACK-/Kommentar-Historie, Ansicht „Keine ext. Reaktion“ |
| v1.12 | Reiter „Supportmanager Protokoll“ fürs Montagsmeeting |
| v1.13 | Globale Suche, Mehrfach-Kennzeichnung, callübergreifende ACK-Kommentare |
| v1.14 | Team-Sync gehärtet: nie schreiben ohne erfolgreiches Lesen, Sync-Banner, Notfall-Override |
| v1.15–v1.17 | Verbinden-Dialog entschärft, Protokoll ohne MPDV, Kundenschwelle einstellbar |
| v1.18–v1.20 | Interne Textbausteine neutralisiert, einheitliche Tabellen-Ausrichtung, Reiter „Auslastung“ (nur VKU) |
| v1.21 | ACK ohne „bis“-Datum bleibt dauerhaft bestehen |
| v1.22 | Button „Jetzt synchronisieren“; Export-Skript mit Schalter `-Jetzt` |
| v1.23 | Mittwochsmail-Vorbereitung: Markier-Punkte in der Zelle (kein Modus, kein Scrollsprung), ACK-Spalte, Fokus-Filter; Wochenendtermine rot umrahmt |
| v1.24 | Team-Datei verbinden: Fehler werden gemeldet statt verschluckt, Schreibrecht sofort nach Auswahl, Lesemodus ohne Schreibrecht |
| v1.25 | Ausweg bei „Not allowed to request permissions in this context“: Schreibrecht über den Speichern-Dialog (Inhalt bleibt erhalten) |
| v1.26 | Team-Datei verbinden (Teamprüfung): Speichern-Modus je Gerät mit Selbstheilung, Board-Dialog „Freigabe erteilen“ statt Alert, Identitätsprüfung der Datei (isSameEntry + Fingerabdruck), „Diese Datei vergessen“, Excel nach Speichern-Dialog nicht in derselben Geste, Köderdatei löschbar |
| v1.27 | Parallelbetrieb: Kanal „prod“/„sqltest“ aus einem Quellcode; Testversion mit eigenem Browser-Speicher, eigener Team-Datei (`SupportBoard-Team-SQLTest.json`) und sichtbarer Markierung; Kanal-Kennung in der Team-Datei mit gegenseitiger Ablehnung; einmalige Übernahme des Produktivstands beim ersten Start; Prüfintervall 5 Min. und Export-Hinweis in der Testversion. Produktivversion funktional unverändert |
| v1.28 | Teamwünsche: Reiter „Kritische Calls“ als Tagesliste mit ACK/Grund (Score ≥ 6, eigene Vorlagen mit {Score}); Spaltenreihenfolge per Ziehen/▲▼ (teamweit); Sortierung der Tabellen teamweit (`state.sort`); ACK-Zeilen rutschen ans Listenende; Filterleiste merkt sich Auf/Zu je Gerät (Ursache des „zufälligen“ Zuklappens behoben); Startseite mit Tagesstatistik (neu/geschlossen/offen, 14 Tage, aus teamweiten Tages-Schnappschüssen `state.tagesstat`), Auslastung 2nd Level je Bearbeiter mit Vortagstrend, Top 10 nach Dauer und Top 10 am längsten offen; unbekannte Bearbeitergruppen erscheinen als Bereich „Sonst.“ |
| v1.29 | Top 10: Zähler „in 7 Tagen geschlossen“ je Liste (aus den Tages-Schnappschüssen, Top-10-Mitgliedschaft wird mitgespeichert) und „Tabelle kopieren“ fürs Supportmanager-Protokoll; Mail-Tabellen: Kopfzeile hell mit schwarzer Schrift statt schwarz/weiß, gelb/rot markierte Zellen zusätzlich fett mit fester Schriftfarbe, Zwischenablage als vollständiges HTML-Dokument und ungefiltert (`unsanitized`) |
| v1.30 | Tagesaufgabe „Mail an Unterstützungsdienste“ (IMP, SAP-CC, CONS): offene Calls der Dienst-Gruppe nach Status gruppiert und nach letzter Aktion zum Kunden sortiert, Zeilenfarbe = Priorität, Einleitung/Fußtext je Dienst und CC in der Verwaltung, Empfänger je Gerät gemerkt, „heute erledigt“ teamweit; Fußzeilen-Markierungen [gelb]/[rot] als Tabellenzellen mit bgcolor, weil Outlook Text-Hintergründe verwirft |
| v1.31 | Warnhinweis „interner Begriff“ im Vorlagen-Editor entfernt (auf Wunsch des Teams); Vorlagen „Kritische Calls“ ohne Controlling-Begriff (alte Texte werden beim Laden bereinigt), {Score} nicht mehr als Platzhalter-Chip; Einleitung/Fußtext der Unterstützungsdienste im Reiter „Vorlagen“ statt in der Verwaltung; Chip „Kritische Calls“ im Vorlagen-Reiter beschriftet |
| v1.32 | Reiter „Reaktionszeit“ (Spalte „Erste externe Reaktion“): offene Calls ohne erste Reaktion mit Frist/Überfälligkeit, Durchschnittstabelle je Prio (Jahr bisher, Monate, letzte 8 KW) mit SLA-Quote, SLA-Brüche je Woche mit teamweitem Kommentar; beide Tabellen kopierbar mit leerer SupMan-Spalte fürs Protokoll; Startseiten-Karte; teamweite Call-Historie `state.reakt` (je Monat, 13 Monate), damit auch geschlossene Calls in die Durchschnitte eingehen; Abfrage um `[Erste externe Reaktion]` (firstAT) ergänzt |
| v1.33 | Reaktionszeit: Nach Ablauf der Eröffnungswoche werden entschiedene Calls (Reaktion gesehen oder geschlossen) in Wochen- und Monatssummen (`state.reaktAgg`) eingefroren und als Einzelfall vergessen; Brüche bleiben 8 Wochen als Liste an der Woche; Vergangenheit wird nicht nachgetragen (Calls mit Reaktion aus vergangenen Wochen werden nicht neu aufgenommen, das verhindert Doppelzählung); Abfrage-Änderung zurückgenommen, die Spalte kommt vom Team |
| v1.34 | Spalte „Externe Reaktion“ der Team-Abfrage (Kalendertage bis zur ersten externen Aktion, 0 = keine) wird als erste externe Reaktion übernommen (Zeitpunkt = Eröffnung + Tage); Zeitstempel-Spalte „Erste externe Reaktion“ bleibt alternativ möglich; Abfrage im Repo auf den Team-Stand gebracht (alle Gruppen, call_statistics) |
| v1.35 | Reaktionszeit: teamweiter Filter (Status, Gruppe, Prio, interner Kunde, Kunden-Ausschluss als Text) wirkt auf Aufzeichnung, Statistik und Listen; MPDV ab Werk ausgeschlossen; Vorgabewerte der bisherigen Excel-Statistik (2023–2025, Jan–Aug 2026, KW 30–35 mit SupMan) als `fix` in `state.reaktAgg` eingespielt, gelten für ihre Zeiträume endgültig; Jahreswert = Mittel der Monatswerte, solange Vorgaben enthalten sind; SupMan in der Kopie für abgeschlossene Wochen gefüllt, laufende Woche leer |
| v1.36 | SaaS-Kunden: Kürzelliste in der Verwaltung („Grundregeln“, `state.saasKunden`, teamweit), Chip „SaaS“ unter „Sonstiges“ in jeder Filterleiste blendet diese Kunden je Liste aus (auch in der Reaktionszeit-Aufzeichnung) |
| v1.37 | Reaktionszeit nur in Geschäftszeit (Mo–Do 08:00–17:30, Fr 08:00–16:30; `GESCHAEFTSZEIT`, `geschaeftszeit()`): Dauer bis zur ersten Reaktion, Fristen, „offen seit“ und Alter offener Calls; Kundengruppen USA und Asien wie SaaS (`KUNDENGRUPPEN`, `state.usaKunden`/`state.asiaKunden`, Chips in jeder Filterleiste), im Reaktionszeit-Filter ab Werk ausgeblendet |
| v1.38 | Reiter „Keine ext. Reaktion“ entfernt (Liste nach letzter externer Reaktion; die erste Reaktion ist das, was zählt, danach greifen die Controlling-Listen). Reiter „Reaktionszeit“ bleibt samt Tabelle der offenen Calls ohne erste Reaktion |
| v1.39 | Frisch bestätigte (ACK) Zeilen bleiben an ihrer Stelle, solange die ACK-Details aufgeklappt sind (`frischAcks`, nur Sitzung); Zuklappen (▾) oder Reiterwechsel lässt sie ans Listenende sinken. Aufklappen einer alten Bestätigung verschiebt nichts |
| v1.40 | Spalte „Letzte Info an Kd.“ (Datum der letzten Kundeninfo) in den Tageslisten, sortierbar; Standard in „Ohne Kd.-Komm.“ links neben „o. Info“, in bereits gespeicherte Spaltenauswahlen dieser Liste einmalig ergänzt (`state.cols.v40`); Beispieldaten mit passendem Datum |
| tools | Server-Fassung des Exports `SupportBoard-Export-Server.ps1` (-Install/-Status/-Uninstall, Dienstkonto, rechnergebundenes Passwort, Log im Zielordner, Fehler ins Ereignisprotokoll) + `docs/Anleitung_Serverbetrieb.md` |
| v1.40 (Testserver) | `SupportBoard-Testserver.html`: Ausgabe der Testversion mit Beschriftung „Testserver-Version“ / „TEST · TESTSERVER“, technisch derselbe Kanal `sqltest` |
| v1.41 | Geschlossene Calls im Export (zwei Jahre): `allRows()` = nur offene, `closedRows()`/`alleZeilen()` für Statistiken; Status „zu“ in der Verwaltung (`state.rules.closedStatus`); Statusgedächtnis `state.callStatus` (je Eröffnungsmonat, teamweit) erkennt Wiedereröffnungen („wieder offen“-Hinweis am Call, Zähler in der Tagesstatistik); Tagesstatistik aus Eröffnungs- und Abschlussdatum statt Vortagsvergleich; Top 10 mit wählbaren Spalten (`state.cols.top_dauer/top_alt`, COLS mit `txt` fürs Kopieren) und Liste „in der Vorwoche (Mo–So) geschlossen“, je Woche eingefroren (`state.topGeschl`), kopierbar; Reaktionszeit im Vollmodus live aus dem Export inkl. geschlossener Calls (kein Einfrieren, `perAusExport()`), Filter nach Region; Spalte `Region` (USA/Asien/Europa) ersetzt die Kürzellisten USA/Asien, Chip „Europa“ neu, Protokoll-Calls > 10 h ohne USA/Asien; Mittwochsmail: Prio in Vorbereitung und OneNote-Tabelle (nicht in der Mail), fehlender LT nur gelb bei Weiterleitung > 14 Tage, Prüfhaken je Benutzer (`ackKey` → `call|mi|KÜRZEL`, keine Historie), „Alle ACK setzen/entfernen“, „neu“-Flag (kein Vorwochen-Archiv); „neu“-Flag in den Tageslisten (`state.wfSeen`, heute erstmals in der Liste und ohne ACK); Textvorlagen DE und EN (`templates.teamsEn/wvlEn`, Knöpfe „Teams EN“/„WVL EN“); Mails auf einen Knopf (Text kopieren + `mailto:` mit An, CC, Betreff) plus Entwurf als `.eml` mit `X-Unsent: 1`; Einzelschritte eingeklappt |
| tools | Server-Export: optionale zweite Abfrage `SupportBoard-Abfrage-Reaktion.sql` (Call + Wert), eigene Verbindung, Verknüpfung über Call-Nummer, Ausfall = WARNUNG statt Fehler; Reaktion aus `SupportBoard-Abfrage.sql` herausgelöst; `build.py` + `board.html` als Quelle wiederhergestellt (drei Ausgaben aus einer Datei) |

## Feste Regeln

- Mittwochsmail: Bearbeiter HX-MP-UPDATE sowie Status Customer Care/Update/Pre-Update ausgeschlossen (Default-Filter)
- Haken-Liste: LT gesetzt & Haken fehlt & Kunde nicht MPDV; MPDV auch aus Kd.-Komm.-Liste raus
- ACK entfernt sich nicht automatisch bei Ticket-Änderungen — nur Verweis „geändert!“; ohne „bis“-Datum dauerhaft, mit Datum bis einschließlich
- Lösungstermine auf Samstag/Sonntag werden rot umrahmt und in den Mails rot hinterlegt; interne MPDV-Tasks sind ausgenommen
- Die ACK-Spalte der Mittwochsmail-Vorbereitung ist rein intern und erscheint weder in der Mail noch in der OneNote-Tabelle
- Team-Datei: Ein Handle wird nur übernommen, wenn es nachweislich dieselbe Datei ist; geschrieben wird ausschließlich nach erfolgreichem Lesen (readOk-Gate). Lässt der Browser keine Berechtigungsanfrage zu, kommt das Schreibrecht über den Speichern-Dialog (Modus „save“, pro Gerät gemerkt, heilt sich selbst)
- Productmanagement wird in Mails als „ProdM“ abgekürzt
- Mail-Tabellen: Kopfzeile hell (#d9e2f3) mit schwarzer Schrift – schwarz/weiß war die einzige Kombination, die unlesbar wird, wenn Outlook die Schriftfarbe verwirft oder im Dunkelmodus umfärbt. Markierte Zellen tragen Hintergrund (bgcolor + Style) UND fette Schrift mit fester Farbe (Style + font-Tag). Markierungen in Fließtext ([gelb]/[rot] in Einleitung und Fußtext) werden zu einzeiligen Tabellen mit bgcolor, weil Outlook Hintergrundfarben auf Text verwirft; sie wirken deshalb zeilenweise
- Reaktionszeit-Filter (`state.filters.sla`) gilt für Aufzeichnung und Auswertung; ausgefilterte Calls werden nicht aufgezeichnet bzw. beim nächsten Lauf entfernt. Vorgabewerte (`SLA_VORGABEN`, im Code) sind Durchschnitte ohne Fallzahlen und gewinnen für ihren Zeitraum; Zählungen zeigen sich nur in Zeiträumen ohne Vorgabe
- Reaktionszeit: Quelle ist „Externe Reaktion“ (Tage ab Eröffnung, 0 = noch keine Reaktion; Reaktionen unter 4 Sekunden fallen durch die Rundung auf 4 Nachkommastellen ebenfalls auf 0). Der Export enthält nur offene Calls. Das Board merkt sich deshalb jeden gesehenen Call mit Eröffnung, erster Reaktion, Prio, Kunde, Gruppe, Bearbeiter (`state.reakt`, Schlüssel je Monat) nur solange nötig: Ist die Eröffnungswoche vorbei und der Call entschieden, bleiben allein die Summen je Woche und Monat (`state.reaktAgg`: n, Summe, ok, gebrochen, ohne Aufzeichnung je Prio); Brüche bleiben 8 Wochen als kleine Liste. Calls, die geschlossen wurden, bevor eine Reaktion gesehen wurde, zählen als „ohne Aufzeichnung“ und nicht in den Durchschnitt. Calls aus vergangenen Wochen, die bereits eine Reaktion haben und noch nicht als Einzelfall bekannt sind, werden nicht aufgenommen (keine Nachträge, keine Doppelzählung). Offene Calls ohne Reaktion nach Fristablauf zählen als Bruch. Beispieldaten schreiben keine Historie
- Reaktionszeit wird in Geschäftszeit gemessen (Mo–Do 08:00–17:30, Fr 08:00–16:30, Sa/So nichts; Feiertage nicht berücksichtigt). Ein Call von Mittwoch 17:30 hat Donnerstag 08:00 null Minuten. Die Fristen (Rot 30 Min., Blau 4 h, Grün 48 h) laufen ebenfalls in Geschäftszeit. Kundengruppen SaaS/USA/Asien: Kürzellisten in der Verwaltung („Grundregeln“), teamweit; Chips unter „Sonstiges“ je Liste, in der Reaktionszeit sind USA und Asien ab Werk ausgeblendet (einmalige Umstellung `filters.sla.v37`)
- Unterstützungsdienste: Gruppen der Dienste müssen in der WHERE-Liste der Abfrage enthalten sein, sonst bleibt die Liste leer (Hinweis im Reiter)
- Kanal-Trennung (ab v1.27): Produktiv- und Testversion nutzen getrennte Speicherschlüssel (`smbState_v1` vs. `smbState_v1_sqltest`, IndexedDB `smbHandles` vs. `smbHandles_sqltest`). Die Team-Datei trägt `kanal`; Dateien ohne Kennung gelten als Produktivdateien. Eine Datei des anderen Kanals wird weder gemischt noch geschrieben
- „Geschlossen“ in der Tagesstatistik ist abgeleitet: Der Export enthält nur offene Calls, gezählt wird, was im Vortags-Schnappschuss stand und heute fehlt (auch Calls, die den Auswertungsbereich verlassen haben). „Neu“ = Eröffnungsdatum am Tag, als Menge über den Tag gesammelt. Beispieldaten schreiben keinen Schnappschuss — gilt nur noch ohne geschlossene Calls im Export. Ab v1.41 (Export mit geschlossenen Calls): „geschlossen“ = Abschlussdatum (Spalte `Geschlossen`, sonst `Letzte_Änderung`) bei Status „zu“; „neu“ = Eröffnungsdatum über alle Calls; „wieder geöffnet“ aus dem Statusgedächtnis (zählt nicht als neu). Ein Wechsel zu→offen→zu ohne Laden dazwischen bleibt unsichtbar
- Reaktionszeit-Grundgesamtheit (v1.41): Die Reaktionsabfrage legt fest, welche Calls bewertet werden (Kunden, Kategorien, SLA-Vertrag). Leere Spalte „Externe Reaktion“ = nicht bewertet, 0 = noch keine Reaktion (`slaBewertet()`). Die Abfrage darf deshalb weder auf `erste_ext_aktion_kalender > 0` noch auf `e_bestaetigung_kalender > 0` noch auf eine Region filtern; Region filtert das Board. Werte `MPDV_Europe/USA/Asia` werden zu Europa/USA/Asien
- Geschlossene Calls stehen in keiner Tagesliste und keiner Mail. Sie zählen in Tagesstatistik, Top-10-Abschlüssen (Vorwoche Mo–So, je Woche eingefroren) und Reaktionszeit (Vollmodus: live aus dem Export, eingefrorene Summen nur für Zeiträume vor dem Export-Fenster; Vorgabewerte gelten weiter)
- Prüfhaken der Mittwochsmail sind persönlich (je Benutzer) und stehen nicht in der Team-Historie; alte teamweite Haken wurden mit v1.41 einmalig verworfen (`state.v41`)
- Mittwochsmail: fehlender Lösungstermin wird nur automatisch gelb, wenn die letzte Weiterleitung mehr als 14 Tage zurückliegt (Wartend nie). Prio steht in der Vorbereitung und in der OneNote-Tabelle, nie in der Mail
- Region (USA/Asien/Europa) kommt aus der Abfrage (Spalte `Region`); nur ohne diese Spalte gelten die Kürzellisten USA/Asien der Verwaltung. Protokoll-Calls > 10 h schließen USA und Asien aus
- Der Cache der geladenen Calls fällt bei Platznot im Browser auf die offenen Calls zurück; die geschlossenen kommen mit dem nächsten Lesen der Datei wieder
- Die Liste „Kritische Calls“ ist eine Sammelliste und löst kein ⚠ „steht auch in …“ in anderen Listen aus
- Das Export-Skript liest ausschließlich (Prüfung vor dem Start, Transaktion mit Rollback, ReadUncommitted). Es darf nichts kaputt machen
- Lieferregel (VKU, 2026-09-11): Das Server-Skript wird immer unter genau dem Dateinamen geliefert, unter dem es auf dem Server liegt: `SupportBoard-Export-Server.ps1` (Ordner `E:\SupMan`). Kein Umbenennen, keine Versionszusätze im Dateinamen. Gleiches gilt für `SupportBoard-Abfrage.sql`, `SupportBoard-Abfrage-Reaktion.sql` und die drei HTML-Dateien

## Bedienungsroutine (Quell-Dateien)

Die Dashboards sind Omnitracker-Abfragetabellen mit „Daten vor dem Speichern entfernen“. Routine: Checkbox deaktivieren, Datei öffnen, Strg+S. Bleibt die Änderungszeit der Datei unverändert, gilt der Inhalt als unverändert (Stale-Warnung nach eingestellter Minutenzahl).

## Offene Punkte

0. Export läuft auf dem OT-Testserver. Offen: neue SQL von VKU (geschlossene Calls, Region) mit den erwarteten Spaltennamen abgleichen (`Region`, optional `Geschlossen`; Status-„zu“-Werte in der Verwaltung prüfen), `SupportBoard-Abfrage-Reaktion.sql` auf dem Server ablegen, `-Preview` und `-Status` prüfen; Kollegen auf die Testserver-Version umstellen; Handbuch (docx/pdf) auf v1.41 nachziehen. Auslastung Dispatcher folgt, sobald die Abfrage Daten dafür liefert.
1. OneNote-Link im PD-Fußtext ersetzen (Platzhalter-URL `https://LINK-ZUM-ONENOTE-HIER-EINFUEGEN`)
2. Team-Rollout: gemeinsame JSON auf dem Share einrichten, Kollegen verknüpfen
3. Optional: Gelb-Schwelle Terminänderungen in der Freitagsmail evtl. ≥5 statt >6 (unbestätigt)
