# Support-Board: Browser richtig einstellen (für alle Supportmanager)

Diese Anleitung sorgt dafür, dass das Board mit dem gemeinsamen Team-Speicher sauber läuft. Dauer: einmalig ca. 5 Minuten pro Person.

## 1. Einmalig: Auf die aktuelle Version wechseln

- Die aktuelle `SupportBoard.html` (v1.14 oder neuer, steht unten links in der Seitenleiste) an **einen festen Ort** legen – am besten für alle derselbe Pfad auf dem Share.
- **Alle alten Kopien löschen** (Desktop, Downloads, lokale Ordner). Ältere Versionen haben die Schutzmechanismen nicht und können Team-Daten beschädigen.
- Eine **Verknüpfung** auf die Datei anlegen (Rechtsklick → Senden an → Desktop) und das Board **immer nur darüber öffnen**. Der Browser merkt sich die Freigaben pro Pfad – wer mal so, mal so öffnet, fängt jedes Mal von vorn an.

## 2. Einmalig: Browser-Einstellungen prüfen (Chrome oder Edge)

- Einstellungen → Datenschutz → **„Browserdaten beim Schließen löschen“ / „Cookies und Websitedaten beim Beenden löschen“ muss AUS sein.**
  Ist das an (oder von der IT vorgegeben), vergisst der Browser die Datei-Verknüpfungen komplett – dann müssen Dashboard und Team-Datei jedes Mal neu ausgewählt werden. Falls ihr das nicht selbst ändern könnt: bei der IT melden.
- Es gibt sonst **nichts zu installieren** und keine weiteren Einstellungen.

## 3. Einmalig: Quellen verbinden

1. Board öffnen, Kürzel wählen.
2. Verwaltung → **„Dashboard überwachen …“** → die Abfrage-Excel auf dem Share auswählen.
3. Verwaltung → **„Team-Speicher …“** → **„OK = vorhandene Datei auswählen“** → die bestehende `SupportBoard-Team.json` auf dem Share wählen.
   ⚠ Niemals „neue Datei anlegen“ wählen, wenn es die Team-Datei schon gibt!
4. Falls der Browser einen Freigabe-Dialog mit der Option **„Bei jedem Besuch zulassen“** zeigt: diese wählen. (Zeigt er nur „Zulassen“, ist das okay – dann bleibt es bei einem Klick pro Sitzung.)

## 4. Jeden Tag: So sieht richtig aus

- Board öffnen → **einmal irgendwo klicken** (z. B. beim Kürzel-Login) → der Browser fragt ggf. einmal nach der Freigabe → **„Zulassen“**. Fertig.
- Unten links müssen **beide Punkte grün** sein: „Dashboard“ und „Team-Speicher“. Dort steht auch „Stand von \<Kürzel\> \<Uhrzeit\>“ – so seht ihr, dass der Abgleich lebt.

## 5. Warnungen ernst nehmen (neu ab v1.14)

- **Rotes Banner „Team-Speicher NICHT verbunden“** oben: Eure Änderungen bleiben nur lokal! → auf **„Jetzt verbinden“** klicken und die Freigabe bestätigen. Das Banner zählt mit, wie viele Änderungen warten – nach dem Verbinden werden sie automatisch sauber mit dem Team-Stand zusammengeführt (es geht nichts verloren, es wird nichts überschrieben).
- **„Team-Abgleich gestört“**: Das Board pausiert absichtlich und überschreibt nichts – einfach stehen lassen, es versucht es alle 15 Sekunden erneut. Bleibt es lange rot: an VKU melden.
- Tipp: Den Board-Tab einfach **offen lassen** – solange er offen ist, fragt der Browser gar nicht erst neu.

## 6. Wenn etwas fehlt: Notfall-Sicherung

Das Board sichert euren Stand **jeden Tag automatisch lokal** (7 Tage rollierend).
Verwaltung → „Notfall-Sicherung“ → **„Fehlendes ergänzen“** holt verschwundene ACKs, Gründe und Kommentare zurück und teilt sie wieder mit dem Team – ohne aktuelle Arbeit zu überschreiben. Das kann jeder selbst, ohne IT.

---
*Hintergrund: Der eine Freigabe-Klick pro Sitzung ist eine Sicherheitsregel des Browsers, solange das Board als Datei (Doppelklick) geöffnet wird – keine Einstellung kann ihn wegkonfigurieren. Er ist seit v1.14 aber ungefährlich: Ohne bestätigte Verbindung wird garantiert nichts am Team-Stand verändert.*
