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

    /* NEU fuer den Reiter "Reaktionszeit": Zeitpunkt der ERSTEN Reaktion nach aussen.
       Das Board misst daraus die Zeit von der Eroeffnung bis zur ersten Reaktion und
       bewertet sie gegen die Fristen (Rot 30 Min., Blau 4 Std., Grün 48 Std.).
       Der Spaltenname muss genau so lauten. NULL = noch keine Reaktion. */
    firstAT.AT_Datum                                    AS [Erste externe Reaktion],

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

OUTER APPLY (
    SELECT TOP (1) r2.erstellt AS AT_Datum
    FROM recent_ATs AS r2
    WHERE r2.callnr = o.callnr
      AND r2.kunde = o.meldende_firma_kurzz
      AND r2.ersteller IS NOT NULL
      AND r2.taetigkeit IN (
          'outgoing email','call to customer','Receipt','update delivery',
          'technical service estimate offer','conference with customer',
          'service-order_remote-cons','remote analysis with phone call'
      )
    ORDER BY r2.erstellt ASC
) AS firstAT

/* Hier kommen weitere Gruppen dazu, sobald das Board sie braucht – z. B. die Unterstuetzungsdienste
   (Consulting, SAP-CC, ImplementationServices) fuer die Tagesaufgabe "Mail an Unterstuetzungsdienste".
   Die Gruppennamen muessen exakt so heissen wie in der Verwaltung des Boards eingetragen. */
WHERE o.verantwortliche_gruppe IN (
          '3rd_SD', '3rd_PD', 'Productmanagement',
          '2nd_CAQ', '2nd_MF', '2nd_HR', '1st_Level', 'Hotline'
      )
  AND o.verantwortlicher_benutzer NOT IN (
          'FSO', 'DTA', 'AYX', 'YZH', 'KBY', 'DCO',
          'KRI', 'SHY', 'CCM', 'KRG', 'CHF', 'KYT'
      );
