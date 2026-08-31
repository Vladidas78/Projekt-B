# Support-Board: Einrichtung ohne Berechtigungs-Klick (für die IT)

Kurze Anleitung, damit das Support-Board ohne den täglichen Berechtigungs-Klick läuft. Dauert insgesamt vielleicht eine Stunde.

## 1. Board auf einen internen Webserver legen (mit HTTPS)

- Die Datei `SupportBoard.html` auf einen internen Webserver legen – IIS oder nginx, ein statisches Verzeichnis reicht völlig. Kein Backend, keine Datenbank.
- Wichtig: **HTTPS**, nicht nur http – sonst funktioniert der Dateizugriff im Browser nicht (die File-System-Access-API läuft nur in „Secure Contexts“).
- Selbst-signiertes Zertifikat geht nur, wenn es zentral als vertrauenswürdig auf alle PCs verteilt wird. Sonst lieber ein richtiges internes Zertifikat.
- Die neue URL ans Team geben und die **alten Datei-Kopien vom Board löschen** – die sollen nicht mehr benutzt werden.

## 2. Browser-Policies prüfen (Edge/Chrome)

Bitte sicherstellen, dass Websitedaten beim Beenden **nicht** gelöscht werden:

- `ClearBrowsingDataOnExit` = deaktiviert
- `ClearBrowsingDataOnExitList` = leer / nicht gesetzt
- `DefaultCookiesSetting` = nicht 4 („nur Sitzung“)

Wenn hier etwas löscht, ist die gespeicherte Berechtigung nach jedem Neustart weg – dann klickt das Team wieder jeden Tag.

## 3. Optional: Berechtigungs-Fragen für die Board-URL explizit erlauben

- Policies `FileSystemReadAskForUrls` und `FileSystemWriteAskForUrls` auf die Board-URL setzen.
- Damit ist sicher, dass der Browser die Frage stellen darf und nichts blockiert.

## 4. Einmalige Aktion fürs Team

- Board über die **neue URL** öffnen.
- Beim Freigabe-Dialog **„Bei jedem Besuch zulassen“** wählen (Chrome/Edge ab Version 122).
- Optional, aber empfohlen: über das Browser-Menü **„Als App installieren“** – dann läuft es am stabilsten.

**Ergebnis:** Kein Berechtigungs-Klick mehr, für niemanden.

**Hinweis:** Am Netzwerk-Share ändert sich nichts – Excel-Ablage und Team-JSON bleiben genau, wo sie sind. Es geht nur darum, von wo die HTML-Datei geöffnet wird.

*Hintergrund: Wird das Board per `file://` (Doppelklick auf die HTML) geöffnet, erlischt die Datei-Berechtigung technisch bedingt, sobald alle Tabs geschlossen sind – daran ändert auch „immer zulassen“ nichts. Nur über eine feste HTTPS-Adresse kann der Browser die Freigabe dauerhaft speichern. (Stand: 31.08.2026)*
