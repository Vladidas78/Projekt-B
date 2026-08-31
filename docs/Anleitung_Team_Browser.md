# Support-Board: Einrichtung für alle Supportmanager

Einmalig ca. 5 Minuten pro Person.

## Vorab: Warum der eine Klick pro Sitzung bleibt

Solange das Board als **Datei** geöffnet wird (Doppelklick auf die HTML), gibt der Browser die Datei-Freigabe grundsätzlich nur für die laufende Sitzung. Sind alle Board-Tabs geschlossen, ist sie weg – **das ist eine feste Regel von Chrome und Edge und lässt sich durch keine Einstellung ändern.** Auch „immer zulassen“ hilft hier nicht.

Das ist kein Fehler bei euch und nichts, was ihr falsch macht. Es bedeutet: **ein Klick pro Sitzung, mehr nicht.**

Dauerhaft weg ist der Klick nur, wenn die IT das Board unter einer festen internen **HTTPS-Adresse** bereitstellt (siehe separate IT-Anleitung). Bis dahin gilt: der Klick ist seit Version 1.14 **ungefährlich** – ohne bestätigte Verbindung kann niemand mehr Team-Daten überschreiben.

## 1. Einmalig: Auf die aktuelle Version wechseln

- Die aktuelle `SupportBoard.html` (Version steht unten links in der Seitenleiste) an **einen festen Ort** legen – am besten für alle derselbe Pfad.
- **Alle alten Kopien löschen** (Desktop, Downloads, lokale Ordner). Ältere Versionen haben die Schutzmechanismen nicht und können Team-Daten beschädigen.
- Eine **Verknüpfung** anlegen (Rechtsklick → Senden an → Desktop) und das Board immer nur darüber öffnen.

## 2. Einmalig: Quellen verbinden

1. Board öffnen, Kürzel wählen.
2. Verwaltung → **„Dashboard überwachen …“** → die Abfrage-Excel auf dem Share auswählen.
3. Verwaltung → **„Team-Speicher …“** → im Dialog **„Vorhandene Team-Datei auswählen“** → `SupportBoard-Team.json` auf dem Share wählen.
   - „Neue Team-Datei erstellen“ ist **nur** für die allererste Einrichtung im Team gedacht und fragt zusätzlich nach.
   - „Abbrechen“, Escape oder ein Klick daneben tun garantiert nichts.

## 3. Jeden Tag: So läuft es richtig

- Board öffnen → **einmal irgendwo klicken** (z. B. beim Kürzel-Login) → Freigabe-Dialog → **„Zulassen“**. Fertig.
- Unten links müssen **beide Punkte grün** sein: „Dashboard“ und „Team-Speicher“. Daneben steht „Stand von \<Kürzel\> \<Uhrzeit\>“ – so seht ihr, dass der Abgleich lebt.
- **Tipp:** Den Board-Tab einfach über den Tag offen lassen – dann fragt der Browser gar nicht erst erneut.

## 4. Warnungen ernst nehmen

- **Rotes Banner „Team-Speicher NICHT verbunden“**: Eure Änderungen bleiben nur lokal. → **„Jetzt verbinden“** klicken und die Freigabe bestätigen. Das Banner zählt mit, wie viele Änderungen warten; nach dem Verbinden werden sie sauber mit dem Team-Stand zusammengeführt – es geht nichts verloren und nichts wird überschrieben.
- **„Team-Abgleich gestört“**: Das Board pausiert absichtlich und überschreibt nichts. Einfach stehen lassen, es versucht es alle 15 Sekunden erneut. Bleibt es lange rot: an VKU melden.

## 5. Wenn etwas fehlt: Notfall-Sicherung

Das Board sichert euren Stand **jeden Tag automatisch lokal** (7 Tage rollierend).
Verwaltung → „Notfall-Sicherung“ → **„Fehlendes ergänzen“** holt verschwundene ACKs, Gründe und Kommentare zurück und teilt sie wieder mit dem Team, ohne aktuelle Arbeit zu überschreiben. Das kann jeder selbst, ohne IT.

## Was ihr NICHT einstellen müsst

Es gibt nichts zu installieren und keine Browser-Einstellung, die den Freigabe-Klick abschaltet. Nur falls euer Browser so eingestellt ist, dass er **Websitedaten beim Beenden löscht**, geht zusätzlich die Datei-*Auswahl* verloren (ihr müsstet die Dateien dann jedes Mal neu heraussuchen statt nur zu bestätigen) – in dem Fall bei der IT melden.
