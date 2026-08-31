# IT-Ticket: Automatische Bereitstellung der Call-Daten für das Supportmanagement-Board

**Ersteller:** Vladimir Kulakow (Supportmanagement)
**Art:** Optimierung eines bestehenden, laufenden Arbeitsablaufs
**Priorität:** normal

## Ausgangslage

Das Supportmanagement nutzt seit einiger Zeit eine kleine Auswertungsseite (eine einzelne HTML-Datei, lokal im Browser geöffnet, keine Installation), die unsere wöchentlichen Controlling-Aufgaben unterstützt: Tageslisten, Mittwochs- und Freitagsmail, Meeting-Protokoll.

**Das läuft bereits produktiv und funktioniert.** Die Daten kommen heute aus einer Excel-Abfrageliste, die wir manuell öffnen, aktualisieren und speichern.

## Anliegen

Wir möchten nur diesen einen manuellen Schritt einsparen: Statt die Excel-Liste von Hand zu aktualisieren, soll die Abfrage automatisch im Hintergrund laufen und das Ergebnis als Datei ablegen.

**Konkret:** Ein kleines PowerShell-Skript per Windows-Aufgabenplanung, das im definierten Intervall (z. B. alle 15 Minuten) eine **lesende** Abfrage ausführt und das Ergebnis als CSV auf unserem bestehenden Team-Verzeichnis ablegt. Die Auswertungsseite liest diese Datei anschließend genauso, wie sie heute die Excel-Datei liest.

## Was dafür benötigt wird

**Freigabe, ein PowerShell-Skript über die Windows-Aufgabenplanung auf meinem Arbeitsplatz ausführen zu dürfen.**

Zusätzliche Datenbankrechte sind nicht erforderlich: Das Skript nutzt dieselbe Abfrage und dieselben Zugriffsrechte, mit denen unsere Excel-Liste heute schon arbeitet (Windows-Authentifizierung, nur lesend). Die Aufgabe läuft ausschließlich, während ich angemeldet bin – es wird kein Kennwort hinterlegt.

Die Ergebnisdatei landet in unserem bereits vorhandenen Team-Verzeichnis. Die Abfrage entspricht inhaltlich der Excel-Abfrage von heute – es kommen keine neuen Datenfelder hinzu, die wir nicht ohnehin schon sehen.

## Rahmenbedingungen

- **Nur lesend.** Es werden keine Daten in die Datenbank geschrieben oder verändert.
- **Keine neue Software**, keine Installation auf den Arbeitsplätzen, keine Cloud, kein externer Dienst.
- **Keine Datenweitergabe.** Alle Daten bleiben im Firmennetz, genau wie heute.
- Der Kreis der Nutzer bleibt unverändert: die 8 Kolleginnen und Kollegen im Supportmanagement, die diese Daten bereits heute im Rahmen ihrer Aufgaben einsehen.
- Der Umfang ist identisch mit dem heutigen Excel-Export – es geht ausschließlich um den Weg, nicht um zusätzliche Inhalte.

## Nutzen

- Kein manuelles Öffnen und Speichern der Excel-Liste mehr (mehrfach täglich, alle 8 Kollegen).
- Immer aktueller Stand, dadurch weniger Rückfragen und Fehlerquellen im Controlling.

## Bitte um Rückmeldung

Falls dafür etwas Bestimmtes benötigt wird (Formular, Freigabe einer Führungskraft, bevorzugter Ausführungsort für die Aufgabe), gebt mir gerne kurz Bescheid – ich richte mich nach eurem Standardvorgehen.

Für Rückfragen stehe ich jederzeit zur Verfügung; das Skript und die Abfrage kann ich vorab zur Prüfung zur Verfügung stellen.
