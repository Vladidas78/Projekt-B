/* =========================================================================
   Supportmanagement-Board - Weiterleitungs-Historie je Call (ab v1.43)
   NUR LESEND. Diese Datei enthaelt ausschliesslich ein SELECT.
   Das Exportskript prueft das zusaetzlich und rollt jede Transaktion zurueck.

   Liefert ZWEI Spalten: Call und Weiterleitungen. Das Exportskript
   (SupportBoard-Export-Server.ps1) haengt den Wert ueber die Call-Nummer an
   die Zeilen der Hauptabfrage an - es bleibt EINE Zeile je Call. Fehlt die
   Datei oder schlaegt sie fehl, bleibt die Spalte leer (WARNUNG im Log),
   die CSV kommt trotzdem.

   Aufbau der Spalte "Weiterleitungen": je Weiterleitung ein Block, Bloecke
   mit " # " getrennt, in zeitlicher Reihenfolge (aelteste zuerst):
     Datum|vorherige Gruppe|vorheriger Bearbeiter|aktuelle Gruppe|aktueller Bearbeiter|Folgestatus|Ersteller
   Leeres Feld = kein Wert. Die Zeichen | und # duerfen in den Werten nicht
   vorkommen (werden unten ersetzt). Datum im Format JJJJ-MM-TTThh:mm:ss.

   VORLAGE: Tabelle "weiterleitungen" (Alias w) und ihre Feldnamen sind
   PLATZHALTER und muessen an die Schattendatenbank angepasst werden
   (Tabelle der Weiterleitungs-Historie, Verknuepfung ueber die Call-Nummer).
   Die Spaltennamen Call und Weiterleitungen (AS ...) muessen bleiben.
   STRING_AGG braucht SQL Server 2017 oder neuer; fuer aeltere Versionen
   steht unten eine Fassung mit FOR XML PATH.
   ========================================================================= */
SELECT
    w.callnr                                                AS Call,
    STRING_AGG(
        CAST(CONCAT(
            CONVERT(varchar(19), w.erstellt, 126), '|',
            REPLACE(REPLACE(ISNULL(w.vorherige_gruppe, ''),            '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(UPPER(ISNULL(w.vorheriger_benutzer, '')),  '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(ISNULL(w.aktuelle_gruppe, ''),             '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(UPPER(ISNULL(w.aktueller_benutzer, '')),   '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(ISNULL(w.folgestatus, ''),                 '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(UPPER(ISNULL(w.ersteller, '')),            '|', '/'), '#', ' ')
        ) AS nvarchar(max)), ' # ')
        WITHIN GROUP (ORDER BY w.erstellt, w.id)             AS Weiterleitungen
FROM weiterleitungen AS w                                   -- PLATZHALTER: Tabelle der Weiterleitungs-Historie
/* Optional eingrenzen, damit nur Calls der Hauptabfrage (offen + zwei Jahre geschlossen) gerechnet werden:
   WHERE w.erstellt >= DATEADD(YEAR, -2, GETDATE())
   oder WHERE w.callnr IN (SELECT o.callnr FROM open_calls AS o UNION ALL SELECT cc.callnr FROM closed_calls AS cc) */
GROUP BY w.callnr;

/* --- Fassung fuer SQL Server vor 2017 (ohne STRING_AGG) - bei Bedarf statt des SELECT oben verwenden: ---
SELECT
    c.callnr AS Call,
    STUFF((
        SELECT ' # ' + CONVERT(varchar(19), w.erstellt, 126) + '|'
             + REPLACE(REPLACE(ISNULL(w.vorherige_gruppe, ''), '|', '/'), '#', ' ') + '|'
             + REPLACE(REPLACE(UPPER(ISNULL(w.vorheriger_benutzer, '')), '|', '/'), '#', ' ') + '|'
             + REPLACE(REPLACE(ISNULL(w.aktuelle_gruppe, ''), '|', '/'), '#', ' ') + '|'
             + REPLACE(REPLACE(UPPER(ISNULL(w.aktueller_benutzer, '')), '|', '/'), '#', ' ') + '|'
             + REPLACE(REPLACE(ISNULL(w.folgestatus, ''), '|', '/'), '#', ' ') + '|'
             + REPLACE(REPLACE(UPPER(ISNULL(w.ersteller, '')), '|', '/'), '#', ' ')
        FROM weiterleitungen AS w
        WHERE w.callnr = c.callnr
        ORDER BY w.erstellt, w.id
        FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 3, '') AS Weiterleitungen
FROM (SELECT DISTINCT callnr FROM weiterleitungen) AS c;
*/
