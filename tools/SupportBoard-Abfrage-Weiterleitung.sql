/* =========================================================================
   Supportmanagement-Board - Weiterleitungs-Historie je Call (ab v1.43)
   NUR LESEND. Diese Datei enthaelt ausschliesslich ein SELECT.
   Das Exportskript prueft das zusaetzlich und rollt jede Transaktion zurueck.

   Liefert je Weiterleitung eine Zeile (Rohform): Call, Datum, vorherige
   Gruppe, vorheriger Bearbeiter, aktuelle Gruppe, aktueller Bearbeiter,
   Folgestatus, Ersteller - in genau dieser Reihenfolge. Das Exportskript
   (SupportBoard-Export-Server.ps1, ab v1.45) buendelt die Zeilen je Call zu
   EINEM Text und haengt ihn als Spalte "Weiterleitungen" ueber die
   Call-Nummer an die Hauptabfrage an. Es bleibt eine Zeile je Call.
   Fehlt die Datei oder schlaegt sie fehl, bleibt die Spalte leer (WARNUNG
   im Log), die CSV kommt trotzdem.

   Ergebnis in der CSV je Weiterleitung ein Block, Bloecke mit " # " getrennt,
   aelteste zuerst (das Skript sortiert nach Datum):
     Datum|vorherige Gruppe|vorheriger Bearbeiter|aktuelle Gruppe|aktueller Bearbeiter|Folgestatus|Ersteller
   Die Zeichen | und # ersetzt das Skript in den Werten.

   Die WHERE-Klausel laesst die Hotline-/1st-Level-Gruppen USA und Asien
   aussen vor (Stand des Teams). Hinweis: Ohne diese Einschraenkung wuerde
   das Board die Calls ueber den Regionsfilter (Chips USA/Asien) ausblenden;
   mit ihr fehlen bei betroffenen Calls einzelne Schritte des Weges.
   ========================================================================= */
SELECT
    callnr          AS Call,
    datum           AS Datum,
    predecessor_grp AS [vorherige Gruppe],
    predecessor_usr AS [vorheriger Bearbeiter],
    current_grp     AS [aktuelle Gruppe],
    current_usr     AS [aktueller Bearbeiter],
    folgestatus     AS Folgestatus,
    ersteller       AS Ersteller
FROM forwardings
WHERE current_grp     NOT IN ('Hotline_USA', '1st_Level_Asia', 'Hotline_Asia', '1st_Level_USA')
  AND predecessor_grp NOT IN ('Hotline_USA', '1st_Level_Asia', 'Hotline_Asia', '1st_Level_USA')
ORDER BY callnr, datum;

/* --- Alternative: Buendelung schon in SQL (SQL Server ab 2017, STRING_AGG). Liefert zwei Spalten
   Call und Weiterleitungen; das Skript haengt den Text dann unveraendert an. Bei Bedarf statt des
   SELECT oben verwenden:
SELECT
    w.callnr AS Call,
    STRING_AGG(
        CAST(CONCAT(
            CONVERT(varchar(19), w.datum, 126), '|',
            REPLACE(REPLACE(ISNULL(w.predecessor_grp, ''), '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(ISNULL(w.predecessor_usr, ''), '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(ISNULL(w.current_grp, ''),     '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(ISNULL(w.current_usr, ''),     '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(ISNULL(w.folgestatus, ''),     '|', '/'), '#', ' '), '|',
            REPLACE(REPLACE(ISNULL(w.ersteller, ''),       '|', '/'), '#', ' ')
        ) AS nvarchar(max)), ' # ') WITHIN GROUP (ORDER BY w.datum) AS Weiterleitungen
FROM forwardings AS w
WHERE w.current_grp     NOT IN ('Hotline_USA', '1st_Level_Asia', 'Hotline_Asia', '1st_Level_USA')
  AND w.predecessor_grp NOT IN ('Hotline_USA', '1st_Level_Asia', 'Hotline_Asia', '1st_Level_USA')
GROUP BY w.callnr;
*/
