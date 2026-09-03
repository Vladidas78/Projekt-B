# Status: Supportmanagement Board

**Stand:** v1.32 · funktional komplett · Parallelbetrieb SQL-Test läuft (Skript per Aufgabenplanung alle 15 Min.) · 2026-09-02

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
- **Spaltenauswahl und -reihenfolge je Liste** (teamweit gespeichert), Sortierung teamweit, eigene sortier-/filterbare Prio-Spalte; bestätigte (ACK) Zeilen stehen am Listenende
- **Filter-Chips:** Status, Bearbeitergruppe, Prio, „MPDV-Calls ausblenden“
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

## Feste Regeln

- Mittwochsmail: Bearbeiter HX-MP-UPDATE sowie Status Customer Care/Update/Pre-Update ausgeschlossen (Default-Filter)
- Haken-Liste: LT gesetzt & Haken fehlt & Kunde nicht MPDV; MPDV auch aus Kd.-Komm.-Liste raus
- ACK entfernt sich nicht automatisch bei Ticket-Änderungen — nur Verweis „geändert!“; ohne „bis“-Datum dauerhaft, mit Datum bis einschließlich
- Lösungstermine auf Samstag/Sonntag werden rot umrahmt und in den Mails rot hinterlegt; interne MPDV-Tasks sind ausgenommen
- Die ACK-Spalte der Mittwochsmail-Vorbereitung ist rein intern und erscheint weder in der Mail noch in der OneNote-Tabelle
- Team-Datei: Ein Handle wird nur übernommen, wenn es nachweislich dieselbe Datei ist; geschrieben wird ausschließlich nach erfolgreichem Lesen (readOk-Gate). Lässt der Browser keine Berechtigungsanfrage zu, kommt das Schreibrecht über den Speichern-Dialog (Modus „save“, pro Gerät gemerkt, heilt sich selbst)
- Productmanagement wird in Mails als „ProdM“ abgekürzt
- Mail-Tabellen: Kopfzeile hell (#d9e2f3) mit schwarzer Schrift – schwarz/weiß war die einzige Kombination, die unlesbar wird, wenn Outlook die Schriftfarbe verwirft oder im Dunkelmodus umfärbt. Markierte Zellen tragen Hintergrund (bgcolor + Style) UND fette Schrift mit fester Farbe (Style + font-Tag). Markierungen in Fließtext ([gelb]/[rot] in Einleitung und Fußtext) werden zu einzeiligen Tabellen mit bgcolor, weil Outlook Hintergrundfarben auf Text verwirft; sie wirken deshalb zeilenweise
- Reaktionszeit: Der Export enthält nur offene Calls. Das Board merkt sich deshalb jeden gesehenen Call mit Eröffnung, erster Reaktion, Prio, Kunde, Gruppe, Bearbeiter (`state.reakt`, Schlüssel je Monat, 13 Monate). Calls, die geschlossen wurden, bevor eine Reaktion gesehen wurde, zählen als „ohne Aufzeichnung“ und nicht in den Durchschnitt. Offene Calls ohne Reaktion nach Fristablauf zählen als Bruch. Beispieldaten schreiben keine Historie
- Unterstützungsdienste: Gruppen der Dienste müssen in der WHERE-Liste der Abfrage enthalten sein, sonst bleibt die Liste leer (Hinweis im Reiter)
- Kanal-Trennung (ab v1.27): Produktiv- und Testversion nutzen getrennte Speicherschlüssel (`smbState_v1` vs. `smbState_v1_sqltest`, IndexedDB `smbHandles` vs. `smbHandles_sqltest`). Die Team-Datei trägt `kanal`; Dateien ohne Kennung gelten als Produktivdateien. Eine Datei des anderen Kanals wird weder gemischt noch geschrieben
- „Geschlossen“ in der Tagesstatistik ist abgeleitet: Der Export enthält nur offene Calls, gezählt wird, was im Vortags-Schnappschuss stand und heute fehlt (auch Calls, die den Auswertungsbereich verlassen haben). „Neu“ = Eröffnungsdatum am Tag, als Menge über den Tag gesammelt. Beispieldaten schreiben keinen Schnappschuss
- Die Liste „Kritische Calls“ ist eine Sammelliste und löst kein ⚠ „steht auch in …“ in anderen Listen aus
- Das Export-Skript liest ausschließlich (Prüfung vor dem Start, Transaktion mit Rollback, ReadUncommitted). Es darf nichts kaputt machen

## Bedienungsroutine (Quell-Dateien)

Die Dashboards sind Omnitracker-Abfragetabellen mit „Daten vor dem Speichern entfernen“. Routine: Checkbox deaktivieren, Datei öffnen, Strg+S. Bleibt die Änderungszeit der Datei unverändert, gilt der Inhalt als unverändert (Stale-Warnung nach eingestellter Minutenzahl).

## Offene Punkte

0. Parallelbetrieb SQL-Test läuft (Abfrage passt zum Schema, Aufgabenplanung lokal auf VKUs Notebook). Nächster Schritt: Skript auf den (Test-)Server; danach Vergleich Test vs. Produktiv nach Checkliste. Auslastung Dispatcher folgt, sobald die Abfrage Daten dafür liefert. Danach entscheiden: Ansicht „Keine ext. Reaktion“ ohne *Wartend*/*Customer Care* als Standard?
1. OneNote-Link im PD-Fußtext ersetzen (Platzhalter-URL `https://LINK-ZUM-ONENOTE-HIER-EINFUEGEN`)
2. Team-Rollout: gemeinsame JSON auf dem Share einrichten, Kollegen verknüpfen
3. Optional: Gelb-Schwelle Terminänderungen in der Freitagsmail evtl. ≥5 statt >6 (unbestätigt)
