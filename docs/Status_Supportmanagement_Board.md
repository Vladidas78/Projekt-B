# Status: Supportmanagement Board

**Stand:** v1.10 · funktional komplett · 2026-08-28

## Was ist das?

Eine eigenständige Single-File-HTML-Anwendung (`SupportBoard.html`) für das SupMan-Controlling bei MPDV. Kein Server, keine Systemanbindung, keine Installation — die Datei wird lokal im Browser geöffnet und liest die Excel-Exporte (PD-Dashboard.xlsx, SD-Dashboard.xlsx) direkt ein.

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

## Feste Regeln

- Mittwochsmail: Bearbeiter HX-MP-UPDATE sowie Status Customer Care/Update/Pre-Update ausgeschlossen (Default-Filter)
- Haken-Liste: LT gesetzt & Haken fehlt & Kunde nicht MPDV; MPDV auch aus Kd.-Komm.-Liste raus
- ACK entfernt sich nicht automatisch bei Ticket-Änderungen — nur Verweis „geändert!“; gilt heute bzw. bis zum „bis“-Datum
- Productmanagement wird in Mails als „ProdM“ abgekürzt

## Bedienungsroutine (Quell-Dateien)

Die Dashboards sind Omnitracker-Abfragetabellen mit „Daten vor dem Speichern entfernen“. Routine: Checkbox deaktivieren, Datei öffnen, Strg+S. Bleibt die Änderungszeit der Datei unverändert, gilt der Inhalt als unverändert (Stale-Warnung nach eingestellter Minutenzahl).

## Offene Punkte

1. OneNote-Link im PD-Fußtext ersetzen (Platzhalter-URL `https://LINK-ZUM-ONENOTE-HIER-EINFUEGEN`)
2. Team-Rollout: gemeinsame JSON auf dem Share einrichten, Kollegen verknüpfen
3. Optional: Gelb-Schwelle Terminänderungen in der Freitagsmail evtl. ≥5 statt >6 (unbestätigt)
