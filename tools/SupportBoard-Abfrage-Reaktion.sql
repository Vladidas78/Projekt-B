/* =========================================================================
   Supportmanagement-Board – Zweite Abfrage: erste externe Reaktion je Call
   NUR LESEND. Optional: Fehlt die Datei oder schlaegt die Abfrage fehl,
   schreibt das Exportskript die CSV trotzdem; die Spalte bleibt dann leer.

   Das Skript nimmt Spalte 1 als Call-Nummer und Spalte 2 als Wert und haengt
   ihn ueber die Call-Nummer an die Zeilen der Hauptabfrage an. Weitere
   Spalten (erstellt, status) stoeren nicht, landen aber nicht in der CSV.

   Diese Abfrage legt die GRUNDGESAMTHEIT der Reaktionszeit fest (Kunden,
   Kategorien, SLA-Vertrag): Calls ohne Zeile hier werden im Board nicht
   bewertet. Deshalb gilt, anders als in der Excel-Statistik:
     - KEIN Filter auf erste_ext_aktion_kalender > 0: Calls ohne Reaktion
       muessen mit Wert 0 kommen, sonst sieht das Board sie nicht als
       "noch ohne Reaktion" (Liste und Fristen).
     - KEIN Filter auf e_bestaetigung_kalender > 0: aus demselben Grund.
     - KEIN Filter auf primaere_kundenbetreuung: Das Board filtert selbst
       nach Region (Europa, USA, Asien), ab Werk ohne USA und Asien.
   ========================================================================= */
SELECT
    cs.callnr                                           AS Call,
    ISNULL(cs.erste_ext_aktion_kalender, 0) / 86400.0   AS [Externe Reaktion],
    cs.erstellt,
    cs.status
FROM call_statistics AS cs
JOIN open_calls AS o ON o.callnr = cs.callnr
WHERE cs.erstellt >= DATEADD(YEAR, -2, GETDATE())
  AND cs.meldende_firma_kurzz NOT IN ('MPDV', 'MPAS', 'MPCN', 'MPUS', 'MPMY', 'MPFE')
  AND (kategorie1 NOT IN ('sonstiges', 'HARDWARE', 'Betriebssystem', 'Datenbank') OR kategorie1 IS NULL)
  AND (kategorie2 NOT IN ('Servercheck', 'sonstiges', 'Datenbank') OR kategorie2 IS NULL)
  AND o.SLA_vertrag_titel != ''
UNION
SELECT
    cs.callnr                                           AS Call,
    ISNULL(cs.erste_ext_aktion_kalender, 0) / 86400.0   AS [Externe Reaktion],
    cs.erstellt,
    cs.status
FROM call_statistics AS cs
JOIN closed_calls AS cc ON cc.callnr = cs.callnr
WHERE cs.erstellt >= DATEADD(YEAR, -2, GETDATE())
  AND cs.meldende_firma_kurzz NOT IN ('MPDV', 'MPAS', 'MPCN', 'MPUS', 'MPMY', 'MPFE')
  AND (kategorie1 NOT IN ('sonstiges', 'HARDWARE', 'Betriebssystem', 'Datenbank') OR kategorie1 IS NULL)
  AND (kategorie2 NOT IN ('Servercheck', 'sonstiges', 'Datenbank') OR kategorie2 IS NULL)
  AND cc.SLA_vertrag_titel != ''
