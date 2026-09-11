/* =========================================================================
   Supportmanagement-Board – Datenabfrage
   NUR LESEND. Diese Datei enthaelt ausschliesslich ein SELECT.
   Das Exportskript prueft das zusaetzlich und rollt jede Transaktion zurueck.

   Aenderungen hier wirken sofort beim naechsten Lauf – das Board muss
   dafuer nicht angepasst werden, solange die Spaltennamen (AS ...) bleiben.
   ========================================================================= */
SELECT
    o.prioritaet                                        AS Prio,
    o.callnr                                            AS Call,
    o.erstellt                                          AS [Eröffnet],
    o.verantwortliche_gruppe                            AS Gruppe,
    UPPER(o.verantwortlicher_benutzer)                  AS Bearbeiter,
    o.meldende_firma_kurzz                              AS Kunde,
    o.titel                                             AS Titel,
    o.zugeordneter_supman                               AS SupMan,
    o.status                                            AS Status,
    o.dauer                                             AS Dauer,
    o.letzte_Weiterleitung                              AS Weiterleitung,
    o.letzte_aenderung                                  AS [Letzte_Änderung],
    o.WAKI_bis                                          AS Wartend_bis,
    o.loesung_bis                                       AS [Lösung_bis],
    o.Anzahl_LT_Verschiebungen                          AS [Terminänderungen],
    o.primaere_kundenbetreuung                          AS Kundenbetreuung,  -- MPDV_Europe / MPDV_USA / MPDV_Asia -> Region im Board
    /* "Externe Reaktion" (Kalendertage bis zur ersten externen Aktion) kommt seit v1.41 aus der
       getrennten Datei SupportBoard-Abfrage-Reaktion.sql; das Exportskript haengt den Wert ueber
       die Call-Nummer an. So laesst sich diese Abfrage abstellen oder in einem anderen Takt fahren,
       ohne den Rest zu verlieren. */
    CASE WHEN o.nicht_auswerten_fuer_kd_kommunikation = 1 THEN 'Ja' ELSE 'Nein' END
                                                        AS [nicht werten für Kd.Komm.],
    lastAT.AT_Datum                                     AS [Letzte Info an Kd.],
    CASE
        WHEN lastAT.AT_Datum IS NULL THEN NULL
        ELSE DATEDIFF(DAY, CAST(lastAT.AT_Datum AS DATE), CAST(GETDATE() AS DATE)) - 1
    END                                                 AS [Tage ohne Info an Kd.],

    /* NEU fuer die Ansicht "Keine externe Reaktion":
       Zeitpunkt der letzten Reaktion nach aussen – mit vollem Zeitstempel,
       damit auch die 30-Minuten-Schwelle bei roter Prio ausgewertet werden kann.
       Gibt es noch keine Reaktion, zaehlt die Weiterleitung an die Gruppe,
       ersatzweise die Call-Eroeffnung. So wartet ein frischer Call nicht
       unbemerkt, nur weil noch nie jemand geantwortet hat. */
    COALESCE(lastAT.AT_Datum, o.letzte_Weiterleitung, o.erstellt)
                                                        AS [Letzte externe Reaktion],

    (
        CASE CAST(LEFT(o.prioritaet, 1) AS INT)
            WHEN 1 THEN 3
            WHEN 2 THEN 2
            WHEN 3 THEN 1
            ELSE 1
        END
        *
        (
            0
            + CASE WHEN DATEDIFF(DAY, o.erstellt, GETDATE()) > 365 THEN 1 ELSE 0 END
            + CASE WHEN o.dauer >= 20 THEN 2 WHEN o.dauer BETWEEN 10 AND 19 THEN 1 ELSE 0 END
            + CASE WHEN DATEDIFF(DAY, o.letzte_aenderung, GETDATE()) >= 30 THEN 2
                   WHEN DATEDIFF(DAY, o.letzte_aenderung, GETDATE()) BETWEEN 14 AND 29 THEN 1 ELSE 0 END
            + CASE WHEN o.Anzahl_LT_Verschiebungen >= 6 THEN 1 ELSE 0 END
            + CASE WHEN o.status = 'Wartend' AND (o.WAKI_bis IS NULL OR o.WAKI_bis < GETDATE()-1) THEN 1 ELSE 0 END
            + CASE
                  WHEN o.status IN ('In Bearbeitung','in Bearbeitung') AND o.loesung_bis IS NULL
                       AND CAST(o.letzte_Weiterleitung AS DATE) < DATEADD(DAY, -7, CAST(GETDATE() AS DATE)) THEN 1
                  WHEN o.status IN ('In Bearbeitung','in Bearbeitung') AND o.loesung_bis IS NOT NULL
                       AND DATEDIFF(DAY, o.loesung_bis, GETDATE()) BETWEEN 1 AND 7 THEN 1
                  WHEN o.status IN ('In Bearbeitung','in Bearbeitung') AND o.loesung_bis IS NOT NULL
                       AND DATEDIFF(DAY, o.loesung_bis, GETDATE()) >= 8 THEN 2
                  ELSE 0
              END
            + CASE
                  WHEN o.status = 'In Bearbeitung'
                       AND CAST(o.loesung_bis AS DATE) < CAST(GETDATE() AS DATE)
                       AND o.nicht_auswerten_fuer_kd_kommunikation = 1 THEN 1
                  WHEN o.status = 'In Bearbeitung' AND o.loesung_bis IS NULL THEN 1
                  ELSE 0
              END
        )
    )                                                   AS Score

FROM open_calls AS o

OUTER APPLY (
    SELECT TOP (1) r1.erstellt AS AT_Datum
    FROM recent_ATs AS r1
    WHERE r1.callnr = o.callnr
      AND r1.kunde = o.meldende_firma_kurzz
      AND r1.ersteller IS NOT NULL
      AND r1.taetigkeit IN (
          'outgoing email','call to customer','Receipt','update delivery',
          'technical service estimate offer','conference with customer',
          'service-order_remote-cons','remote analysis with phone call'
      )
    ORDER BY r1.erstellt DESC
) AS lastAT

/* Keine Einschraenkung mehr auf Gruppen oder Bearbeiter: Das Board filtert selbst
   (Filter-Chips je Liste, Bereich "Sonst." fuer unbekannte Gruppen). */

/* =========================================================================
   VORSCHLAG (v1.41): geschlossene Calls der letzten zwei Jahre mitliefern.
   Grundlage fuer Tagesstatistik (neu/geschlossen/wieder geoeffnet), die in
   der Vorwoche geschlossenen Top-10-Calls und die Reaktionszeit. Geschlossene
   Calls stehen im Board in keiner Tagesliste und keiner Mail.
   closed_calls hat keine Spalten zugeordneter_supman, letzte_Weiterleitung,
   Anzahl_LT_Verschiebungen und nicht_auswerten_fuer_kd_kommunikation (Lauf vom
   2026-09-11); dafuer stehen hier Leerwerte.
   Gibt es ein Abschlussdatum (z. B. cc.geschlossen_am), bitte als
   "AS Geschlossen" mitgeben; sonst nimmt das Board [Letzte_Änderung].
   Score, letzte Kundeninfo und Tage ohne Info bleiben bei geschlossenen leer.
   ========================================================================= */
UNION ALL
SELECT
    cc.prioritaet                                       AS Prio,
    cc.callnr                                           AS Call,
    cc.erstellt                                         AS [Eröffnet],
    cc.verantwortliche_gruppe                           AS Gruppe,
    UPPER(cc.verantwortlicher_benutzer)                 AS Bearbeiter,
    cc.meldende_firma_kurzz                             AS Kunde,
    cc.titel                                            AS Titel,
    NULL                                                AS SupMan,               -- gibt es in closed_calls nicht
    cc.status                                           AS Status,
    cc.dauer                                            AS Dauer,
    NULL                                                AS Weiterleitung,        -- gibt es in closed_calls nicht
    cc.letzte_aenderung                                 AS [Letzte_Änderung],
    cc.WAKI_bis                                         AS Wartend_bis,
    cc.loesung_bis                                      AS [Lösung_bis],
    NULL                                                AS [Terminänderungen],   -- gibt es in closed_calls nicht
    cc.primaere_kundenbetreuung                         AS Kundenbetreuung,
    'Nein'                                              AS [nicht werten für Kd.Komm.],  -- gibt es in closed_calls nicht
    NULL                                                AS [Letzte Info an Kd.],
    NULL                                                AS [Tage ohne Info an Kd.],
    NULL                                                AS [Letzte externe Reaktion],
    0                                                   AS Score
FROM closed_calls AS cc
WHERE cc.erstellt >= DATEADD(YEAR, -2, GETDATE())
