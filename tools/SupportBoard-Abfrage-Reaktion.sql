/* =========================================================================
   Supportmanagement-Board – Zweite Abfrage: externe Reaktion je Call
   NUR LESEND. Optional: Fehlt diese Datei oder schlaegt die Abfrage fehl,
   schreibt das Exportskript die CSV trotzdem, die Spalte bleibt dann leer.

   Zwei Spalten, in dieser Reihenfolge:
     1. Call            Call-Nummer (Verknuepfung zur Hauptabfrage)
     2. [Externe Reaktion]  Kalenderzeit von der Eroeffnung bis zur ersten
                        externen Aktion, in Tagen (0 = noch keine)
   Der Name der zweiten Spalte wird so in die CSV uebernommen.
   ========================================================================= */
SELECT
    cs.callnr                                           AS Call,
    cs.erste_ext_aktion_kalender / 86400.0              AS [Externe Reaktion]
FROM call_statistics AS cs
