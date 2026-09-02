# Status: Supportmanagement Board

**Stand:** v1.27 · funktional komplett · Parallelbetrieb SQL-Test vorbereitet · 2026-09-02

## Was ist das?

Eine eigenständige Single-File-HTML-Anwendung (`SupportBoard.html`) für das SupMan-Controlling bei MPDV. Kein Server, keine Systemanbindung, keine Installation — die Datei wird lokal im Browser geöffnet und liest die Abfrageliste (Excel oder die CSV des SQL-Exports) direkt ein.

Seit v1.27 entstehen aus einem Quellcode zwei Ausgaben: `SupportBoard.html` (Produktivversion) und `SupportBoard-SQLTest.html` (Testversion mit eigenem Speicher, siehe `docs/Anleitung_Parallelbetrieb_SQL-Test.md`).

## Kernfunktionen

- **5 Tageslisten:** Überschrittene LTs, Ohne Kd.-Kommunikation, Ohne Änderung, LT ohne Kd.-Info (Haken), Wartend ohne Datum
- **Mittwochsmail-Generator:** Langläufer >10h, getrennt als Mail 1 (PD/ProdM) und Mail 2 (SD), mit Outlook-festen Farben
- **Freitagsmail-Generator** mit Wochenauswertung
- **OneNote-Tabelle** (mit leerer Verbleib-Spalte zum Ausfüllen)
- **Team-Sharing ohne Server:** gemeinsame JSON auf dem Share, Merge nach Newest-wins
- **ACK-Workflow:** Bestätigungen mit Grund, Zeitstempel und „geändert!“-Verweis, wenn sich der überwachte Teil eines Tickets danach ändert
- **Kommentare** mit Zeitstempel und Autor, lange Kommentare zuklappbar
- **Spaltenauswahl je Liste** (teamweit gespeichert), eigene sortier-/filterbare Prio-Spalte
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

## Feste Regeln

- Mittwochsmail: Bearbeiter HX-MP-UPDATE sowie Status Customer Care/Update/Pre-Update ausgeschlossen (Default-Filter)
- Haken-Liste: LT gesetzt & Haken fehlt & Kunde nicht MPDV; MPDV auch aus Kd.-Komm.-Liste raus
- ACK entfernt sich nicht automatisch bei Ticket-Änderungen — nur Verweis „geändert!“; ohne „bis“-Datum dauerhaft, mit Datum bis einschließlich
- Lösungstermine auf Samstag/Sonntag werden rot umrahmt und in den Mails rot hinterlegt; interne MPDV-Tasks sind ausgenommen
- Die ACK-Spalte der Mittwochsmail-Vorbereitung ist rein intern und erscheint weder in der Mail noch in der OneNote-Tabelle
- Team-Datei: Ein Handle wird nur übernommen, wenn es nachweislich dieselbe Datei ist; geschrieben wird ausschließlich nach erfolgreichem Lesen (readOk-Gate). Lässt der Browser keine Berechtigungsanfrage zu, kommt das Schreibrecht über den Speichern-Dialog (Modus „save“, pro Gerät gemerkt, heilt sich selbst)
- Productmanagement wird in Mails als „ProdM“ abgekürzt
- Kanal-Trennung (ab v1.27): Produktiv- und Testversion nutzen getrennte Speicherschlüssel (`smbState_v1` vs. `smbState_v1_sqltest`, IndexedDB `smbHandles` vs. `smbHandles_sqltest`). Die Team-Datei trägt `kanal`; Dateien ohne Kennung gelten als Produktivdateien. Eine Datei des anderen Kanals wird weder gemischt noch geschrieben
- Das Export-Skript liest ausschließlich (Prüfung vor dem Start, Transaktion mit Rollback, ReadUncommitted). Es darf nichts kaputt machen

## Bedienungsroutine (Quell-Dateien)

Die Dashboards sind Omnitracker-Abfragetabellen mit „Daten vor dem Speichern entfernen“. Routine: Checkbox deaktivieren, Datei öffnen, Strg+S. Bleibt die Änderungszeit der Datei unverändert, gilt der Inhalt als unverändert (Stale-Warnung nach eingestellter Minutenzahl).

## Offene Punkte

0. Parallelbetrieb SQL-Test: erster echter Lauf mit `-Preview` (Feldnamen gegen das echte Schema), dann Vergleich Test vs. Produktiv nach Checkliste; anschließend Skript auf den (Test-)Server. Danach entscheiden: Ansicht „Keine ext. Reaktion“ ohne *Wartend*/*Customer Care* als Standard?
1. OneNote-Link im PD-Fußtext ersetzen (Platzhalter-URL `https://LINK-ZUM-ONENOTE-HIER-EINFUEGEN`)
2. Team-Rollout: gemeinsame JSON auf dem Share einrichten, Kollegen verknüpfen
3. Optional: Gelb-Schwelle Terminänderungen in der Freitagsmail evtl. ≥5 statt >6 (unbestätigt)
