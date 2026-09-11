# Supportmanagement-Board – Handbuch

Für alle, die im Dispatch und Supportmanagement mit dem Board arbeiten. Ziel: Auch ohne VKU ist jeder handlungsfähig – im Alltag und wenn etwas klemmt.

Reihenfolge zum Lesen: Kapitel 1 bis 4 einmal komplett, der Rest bei Bedarf. Kapitel 9 ist die Störungshilfe.

---

## Steckbrief (bitte einmal ausfüllen und aktuell halten)

| | |
|---|---|
| Board (HTML) | `………………………………` |
| Team-Datei (JSON) | `………………………………` |
| Daten-Datei (CSV) | `………………………………` |
| Log des Exports | im selben Ordner wie die CSV: `SupportBoard-Export.log` |
| Export-Server | `………………` , Skriptordner `………………` |
| Aufgabe auf dem Server | „Supportboard Datenexport (Server)“, läuft alle 10 Minuten |
| Zuständig | VKU · Vertretung: `………………` · IT-Ansprechpartner: `………………` |

---

## 1. Was das Board ist

Eine einzelne HTML-Datei. Kein Server, keine Installation, keine Anmeldung im Netz. Sie wird im Browser geöffnet und liest zwei Dateien:

- **die Daten-Datei (CSV)** – alle offenen Calls, wird automatisch erzeugt und ist die Grundlage aller Listen und Zahlen;
- **die Team-Datei (JSON)** – alles, was das Team selbst einträgt: Haken, Gründe, Kommentare, Vorlagen, Stammdaten, Spalten- und Filtereinstellungen.

Das Board ersetzt kein Ticketsystem. Es zeigt, **welche Calls heute Aufmerksamkeit brauchen**, und hilft, die immer gleichen Prüfungen und Mails zügig zu erledigen. Geändert wird ein Call weiterhin im Ticketsystem.

**Wichtig:** Das Board schreibt nie in die Datenbank oder ins Ticketsystem. Es kann dort nichts kaputt machen.

---

## 2. Woher die Daten kommen

```
Omnitracker-Schattendatenbank
        │  lesende SQL-Abfrage
        ▼
Export-Skript auf dem Server  ── alle 10 Minuten, unbeaufsichtigt
        │
        ▼
SupportBoard-Daten.csv  (auf der Freigabe)
        │  Board prüft alle 5 Minuten auf eine neue Fassung
        ▼
Board im Browser  ◄──►  SupportBoard-Team-…json  (Haken, Kommentare, Stammdaten)
```

Drei Punkte, die man kennen sollte:

1. **Der Export läuft auf dem Server**, nicht auf einem Arbeitsplatz. Er läuft auch nachts, am Wochenende und wenn niemand angemeldet ist. Morgens sind die Daten also frisch.
2. **Der Export liest nur.** Die Abfrage wird vor jedem Lauf geprüft, läuft in einer Transaktion, die immer zurückgerollt wird, und setzt keine Sperren.
3. **Geht etwas schief, bleibt die letzte gute CSV stehen.** Das Board arbeitet dann mit dem letzten Stand weiter und zeigt unten links an, dass die Daten alt sind. Es steht nie plötzlich leer da.

Seit v1.41 liefert der Export auch die **geschlossenen Calls der letzten zwei Jahre** und die **Region** des Kunden (USA, Asien, Europa). Geschlossene Calls stehen in keiner Tagesliste und keiner Mail; sie füttern die Tagesstatistik, die Abschlüsse der Top 10 („in der Vorwoche geschlossen“) und die Reaktionszeit. Ein Call, der nach Gelöst/Geschlossen wieder in Bearbeitung geht, trägt den Hinweis „wieder offen“ und zählt nicht als neuer Call. Die Region steht als Filter-Chip in jeder Liste (auch in der Reaktionszeit).

Der **Stand der Daten** ist immer unten links in der Seitenleiste zu sehen: zwei Punkte für Dashboard-Datei und Team-Speicher. Grün heißt in Ordnung, Gelb heißt Beispieldaten, Rot heißt: Datei zu lange unverändert oder nicht erreichbar.

---

## 3. Einmalige Einrichtung am eigenen Arbeitsplatz

Jeder macht das einmal auf seinem PC. Es dauert zwei Minuten.

1. **Board öffnen.** Die HTML-Datei im Ordner per Doppelklick starten (siehe Steckbrief). Nicht kopieren, immer die Datei im gemeinsamen Ordner öffnen – dann arbeiten alle mit derselben Fassung.
2. **Kürzel wählen.** Beim Start fragt das Board „Wer arbeitet gerade?“. Eigenes Kürzel anklicken. Es steht später an jedem Haken und jedem Kommentar, damit das Team sieht, wer was geprüft hat. Wechseln geht jederzeit unten links.
3. **Daten verknüpfen.** Verwaltung → **„Dashboard überwachen …“** → die `SupportBoard-Daten.csv` aus dem Steckbrief auswählen. Der Browser fragt einmal nach Erlaubnis: **„Bei jedem Besuch zulassen“** wählen, sonst kommt die Frage täglich wieder.
4. **Team-Speicher verbinden.** Verwaltung → **„Team-Speicher …“** → **„Vorhandene Team-Datei auswählen“** → die JSON aus dem Steckbrief. Auch hier „Bei jedem Besuch zulassen“.
5. **Fertig**, wenn unten links beide Punkte grün sind.

Ohne Schritt 4 arbeitet man allein: Die eigenen Haken und Kommentare bleiben auf dem eigenen PC und erreichen niemanden.

---

## 4. Der tägliche Ablauf

**Übersicht** öffnen. Dort stehen die Kennzahlen des Tages und für jede Tagesliste, wie viel offen ist. Von dort in die Listen springen.

Die Listen in der Seitenleiste arbeitet man von oben nach unten ab. Die Zahl hinter dem Namen ist das, was noch offen ist – abgehakte Calls zählen nicht mit.

### Die sechs Tageslisten

| Liste | Was drinsteht | Was zu tun ist |
|---|---|---|
| **Kritische Calls** | Score ab 6 | Prüfen, ob der Call auf dem richtigen Weg ist. Der Grund im Haken ist der Kommentar dazu. |
| **Überschrittene LTs** | Lösungstermin liegt in der Vergangenheit | Kundenkommunikation anstoßen und den LT anpassen lassen. |
| **Ohne Kd.-Komm.** | „In Bearbeitung“ und seit X Tagen keine Info an den Kunden | Bearbeiter bitten, dem Kunden einen Zwischenstand zu geben. |
| **Ohne Änderung** | Seit X Tagen nichts am Call passiert | Nach dem Stand fragen. |
| **LT ohne Kd.-Info** | LT gesetzt, aber der Haken „nicht werten für Kd.Komm.“ fehlt | Kunde informiert? Ja → Haken im Ticketsystem setzen. Nein → Bearbeiter informieren. |
| **Wartend o. Datum** | Status „Wartend“, aber „Wartend bis“ fehlt oder ist abgelaufen | Ein Datum in der Zukunft setzen lassen. |

Die Schwellen (7 Tage ohne Info, 14 Tage ohne Änderung) stehen in jeder Liste oben unter **„Filter“** und gelten fürs ganze Team.

### Der Score

Er kommt aus der Abfrage und fasst zusammen, wie sehr ein Call auffällt:

**Score = Prio-Faktor × Summe der Auffälligkeiten.** Prio-Faktor: Rot 3, Blau 2, Grün 1. Punkte gibt es für: älter als ein Jahr, hohe Dauer, langer Stillstand, viele Terminverschiebungen, „Wartend“ ohne gültiges Datum, überschrittener oder fehlender Lösungstermin.

Ab 6 gilt ein Call als kritisch und steht in der Liste „Kritische Calls“. Der Score bewertet nicht die Arbeit des Bearbeiters, er sortiert nur die Aufmerksamkeit.

### Haken (ACK) – das wichtigste Bedienelement

Der Haken in der ersten Spalte heißt: **„Ich habe mir das angesehen, hier ist alles geklärt.“** Der Call verschwindet aus der Zählung und rutscht ans Listenende.

- **Ohne Datum gilt der Haken dauerhaft**, bis ihn jemand wieder entfernt.
- **Mit „bis“-Datum** gilt er bis einschließlich dieses Tages. Danach taucht der Call automatisch wieder auf. Das ist der Normalfall bei „der Kunde meldet sich nächste Woche“.
- **Grund eintragen** lohnt sich immer. Er ist für alle sichtbar, auch in anderen Listen desselben Calls, und beantwortet die Frage „warum steht der noch offen?“ ohne Rückfrage.
- Ändert sich nach dem Haken genau das, worum es in der Liste ging, bleibt der Haken bestehen, aber ein rotes **„geändert!“** erscheint. Dann noch einmal draufschauen.
- Ein abgelaufener Haken zeigt weiter, wer wann mit welchem Grund abgehakt hatte. Beim erneuten Abhaken bleibt der Grund erhalten.

Haken und Kommentare gehen über die Team-Datei an alle. Man sieht also, was die Kollegen schon geprüft haben, und braucht es nicht doppelt zu tun.

### Nachrichten an Bearbeiter

Rechts in jeder Zeile stehen zwei Knöpfe:

- **Teams** – kopiert eine fertige Chat-Nachricht an den Bearbeiter.
- **WVL** – kopiert einen Wiedervorlage-Text für das Ticketsystem.

Beides landet in der Zwischenablage und wird im Zielprogramm eingefügt. Die Texte stehen unter **Vorlagen** und lassen sich ändern.

---

### Neu in den Listen (ab v1.41)

- **„neu“** am Call: steht heute zum ersten Mal in dieser Liste und hat noch kein ACK.
- **„wieder offen“** am Call: war geschlossen und ist wieder in Bearbeitung.
- **Teams EN / WVL EN**: englische Textbausteine für Kollegen in den USA und in Asien (Reiter „Vorlagen“).

## 5. Der Wochenrhythmus

| Wann | Reiter | Inhalt |
|---|---|---|
| täglich | **Unterstützungsdienste** | Ist jemand aus IMP, SAP-CC oder CONS eingeplant, bekommt er die offenen Calls seiner Gruppe. Empfänger im Reiter eintragen, Text und CC stehen in der Verwaltung. |
| montags | **Supportmanager Protokoll** | Vorbereitung des Montagsmeetings. Neue Wochenzeilen enthalten nur das Datum, die Inhalte entstehen im Meeting und werden geteilt. Rot markiert: Kunden ohne Supportmanager. |
| mittwochs | **Mittwochsmail** | Langläufer nach Dauer. Farbpunkte in der Termin- und Kommentarspalte färben die Zelle für die Mail (gelb, rot, ohne). Fehlende Termine werden nur automatisch gelb, wenn die letzte Weiterleitung über zwei Wochen zurückliegt. Die ACK-Spalte ganz rechts ist dein persönlicher Prüffortschritt (nur für dich sichtbar, steht in keiner Mail); „Alle ACK setzen/entfernen“ gibt es oben rechts. Die Prio steht in der Vorbereitung und in der OneNote-Tabelle, nicht in der Mail. |
| freitags | **Freitagsmail** | Alle Calls mit Lösungstermin bis zum kommenden Freitag, PD und SD getrennt. Grün = Kunde über den LT informiert, Gelb = mehr als sechs Terminänderungen. |
| Mails versenden | **ein Knopf** | Bei Mittwochsmail, Freitagsmail und Unterstützungsdiensten öffnet der blaue Knopf Outlook mit Empfängern, CC und Betreff und legt den Text in die Zwischenablage: einmal Strg+V in den Textbereich, prüfen, senden. „Entwurf als Datei (.eml)“ lädt die fertige Mail herunter; öffnet sie in Outlook (klassisch) als Entwurf, genügt „Senden“. Die Einzelschritte (Text, An, CC getrennt) stehen eingeklappt darunter. |

Für alle Mails gilt derselbe Ablauf: Reiter öffnen, Inhalte prüfen und kommentieren, dann **Mail kopieren** und in Outlook einfügen. Die Formatierung bleibt erhalten. Einleitungen und Fußtexte pflegt man unter **Vorlagen**.

---

## 6. Weitere Reiter

**Reaktionszeit** – Wie schnell reagiert der Support zum ersten Mal nach außen? Vorgabe: Rot innerhalb 30 Minuten, Blau 4 Stunden, Grün 48 Stunden. Gerechnet wird nur in der Geschäftszeit (Mo–Do 8:00–17:30, Fr 8:00–16:30), Feiertage bleiben unberücksichtigt. Es zählt ausschließlich die **erste** Reaktion. Stehen unter „Ohne erste externe Reaktion“ sehr viele Calls, sind das meist welche mit Status *Wartend* oder *Customer Care* – dort wartet nicht der Kunde auf uns. Diese Status lassen sich über die Filter-Chips ausblenden.

**Suche** (Feld oben links) – Call-Nummer, Kunde, Titel oder Bearbeiter eingeben. Das Ergebnis zeigt auch, in welchen Tageslisten der Call gerade steht und ob er dort schon abgehakt ist.

**Vorlagen** – alle Textbausteine für Teams, WVL und die Mails. Änderungen gelten sofort und für alle.

**Verwaltung** – Datenquelle, Personen, Anmelde-Kürzel, Verteiler, Filtergruppen, Schwellenwerte und die Sicherung.

---

## 7. Spalten, Filter und Sortierung

- **Spalten** je Liste über den Knopf **„Spalten …“** oben rechts: an- und abwählen, per Ziehen oder mit den Pfeilen umsortieren, „Standard wiederherstellen“ setzt zurück.
- **Sortieren** durch Klick auf die Spaltenüberschrift.
- **Spaltenfilter** über das Trichter-Symbol in der Überschrift – tippt man dort etwas ein, bleiben nur passende Zeilen.
- **Filter** oben in jeder Liste: Gruppen ein- und ausblenden, Schwellen einstellen, unter „Sonstiges“ auch interne Calls (Kunde MPDV) ausblenden.

Spaltenauswahl, Sortierung und Filter werden **teamweit** gespeichert. Wer etwas umstellt, stellt es für alle um. Das ist gewollt, sollte man aber wissen, bevor man aufräumt.

---

## 8. Sicherung

Das Board legt **jeden Tag eine lokale Sicherung** an, sieben Tage rollierend, nur auf dem eigenen PC. In der Verwaltung unten:

- **„Sicherung laden …“** stellt einen alten Stand wieder her.
- **„Fehlendes ergänzen“** spielt verschwundene Haken, Gründe und Kommentare zurück, ohne Aktuelles zu überschreiben, und teilt sie wieder mit dem Team. Das ist der richtige Knopf, wenn nach einer Störung Einträge fehlen.

---

## 9. Wenn etwas nicht stimmt

### Zuerst: Wo klemmt es?

Der Blick unten links in die Seitenleiste beantwortet das fast immer.

| Anzeige | Bedeutung | Was tun |
|---|---|---|
| beide Punkte grün | alles in Ordnung | – |
| Dashboard rot, „läuft der Export?“ | Die CSV ist seit Stunden unverändert | Abschnitt „Der Export läuft nicht“ |
| Dashboard rot, Datei nicht erreichbar | Freigabe weg oder Berechtigung erloschen | Verwaltung → „Dashboard überwachen …“ neu setzen; sonst IT |
| Team-Speicher rot | Team-Datei nicht erreichbar oder nur lesbar | Verwaltung → „Team-Speicher …“ neu verbinden |
| gelber Punkt „Beispieldaten“ | Es sind Demo-Daten geladen, keine echten | Verwaltung → „Dashboard überwachen …“ mit der echten CSV |
| Banner oben rot | Team-Sync gestört | Nichts erzwingen. Meldung lesen, im Zweifel VKU oder Vertretung |

### Häufige Fälle

**„Der Browser fragt jeden Tag nach Erlaubnis.“** Beim Dialog **„Bei jedem Besuch zulassen“** wählen. Bleibt es dabei, löscht der Browser beim Beenden die Websitedaten – das kann nur die IT per Richtlinie abstellen.

**„Meine Haken sind weg.“** Erst prüfen, ob der Team-Speicher verbunden ist (Punkt unten links). Dann Verwaltung → **„Fehlendes ergänzen“**. Das holt zurück, was noch in der lokalen Sicherung liegt.

**„Ein Call taucht wieder auf, obwohl er abgehakt war.“** Normal, wenn der Haken ein „bis“-Datum hatte und dieses abgelaufen ist. Steht daneben „geändert!“, hat sich der überwachte Teil verändert – dann ist erneutes Hinsehen richtig.

**„Die Zahlen stimmen nicht mit dem Ticketsystem überein.“** Die CSV ist maximal zehn Minuten alt, dazu kommt das Prüfintervall des Boards. Kurz warten oder unten links **„Jetzt synchronisieren“** klicken. Bleibt der Unterschied, in den nächsten Abschnitt.

### Der Export läuft nicht

Erste Anlaufstelle ist das **Log neben der CSV**: `SupportBoard-Export.log`. Es lässt sich mit jedem Editor öffnen und nennt jeden Lauf mit Zeitstempel, im Fehlerfall die Ursache im Klartext.

| Eintrag im Log | Bedeutung |
|---|---|
| `Fertig (Server): … Zeilen` | Alles gut, das ist der Normalfall. |
| `Uebersprungen: Datei ist erst … Minuten alt` | Kein Fehler. Ein anderer Lauf war schneller. |
| `Sicherheitsstopp: …` | Jemand hat die Abfrage verändert. Es wurde nichts ausgeführt. VKU oder IT. |
| `Login failed for user …` | Datenbank-Anmeldung abgelehnt, meist abgelaufenes Passwort. IT. |
| `Die Abfrage lieferte 0 Zeilen` | Schutzmechanismus, die alte CSV bleibt stehen. Wenn wiederholt: IT. |
| `Zielordner nicht erreichbar` | Der Server kommt nicht an den Ordner. IT. |
| gar kein neuer Eintrag seit Stunden | Die geplante Aufgabe läuft nicht. Nächster Abschnitt. |

**Auf dem Server nachsehen** (dafür braucht man Zugang zum Server und Administratorrechte):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
cd <Skriptordner aus dem Steckbrief>
.\SupportBoard-Export-Server.ps1 -Status
```

Das zeigt Zustand der Aufgabe, letzten und nächsten Lauf, Alter und Zeilenzahl der CSV sowie die letzten Logzeilen. Einen Lauf sofort auslösen:

```powershell
.\SupportBoard-Export-Server.ps1 -Jetzt
```

Fehler landen zusätzlich im Ereignisprotokoll des Servers unter Anwendung, Quelle `SupportBoard-Export`. Damit kann die IT auch ohne das Board nachsehen.

**Solange der Export steht**, arbeitet das Board mit dem letzten Stand weiter. Für ein, zwei Stunden ist das unkritisch. Dauert es länger, gilt die alte Excel-Routine als Rückfallebene.

---

## 10. Was man ändern darf und was nicht

**Ohne Rücksprache in Ordnung:** Haken setzen und entfernen, Gründe und Kommentare schreiben, Empfänger einer Mail eintragen, Spalten und Sortierung anpassen, Filter setzen, Personen und Kürzel in der Verwaltung pflegen, Textbausteine unter Vorlagen ändern.

**Bitte vorher abstimmen:** Schwellenwerte der Listen, Filtergruppen, Kundengruppen und der interne Kunde. Das verändert, was das ganze Team zu sehen bekommt.

**Nur VKU oder die IT:** die SQL-Abfrage, das Export-Skript und seine Einstellungen, die geplante Aufgabe auf dem Server, die Ordner und Freigaben. Der Knopf „Notfall: Team-Datei neu schreiben“ ist ebenfalls tabu, solange keine Rücksprache erfolgt ist – er überschreibt den Teamstand mit dem eigenen.

**Nie nötig:** Die HTML-Datei bearbeiten. Alles Einstellbare steht in der Verwaltung.

---

## 11. Kurzreferenz

| Ich will … | So geht es |
|---|---|
| einen Call finden | Suchfeld oben links |
| einen Call als geprüft markieren | Haken in der ersten Spalte, Grund eintragen |
| einen Call bis Datum ruhigstellen | Haken setzen, „bis“-Datum eintragen |
| den Bearbeiter anschreiben | Knopf **Teams** in der Zeile, dann in Teams einfügen |
| eine Wiedervorlage setzen | Knopf **WVL**, dann ins Ticketsystem einfügen |
| frische Daten sofort | unten links **„Jetzt synchronisieren“** |
| Spalten ändern | **„Spalten …“** oben rechts in der Liste |
| Schwellen ändern | **„Filter“** oben in der Liste |
| verlorene Einträge zurückholen | Verwaltung → **„Fehlendes ergänzen“** |
| sehen, ob die Daten frisch sind | zwei Punkte unten links in der Seitenleiste |
| wissen, ob der Export läuft | `SupportBoard-Export.log` neben der CSV |
