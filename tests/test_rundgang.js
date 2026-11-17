// Browser-Test: Rundgang über alle Reiter – mit Beispieldaten und mit einer kleinen CSV (Weiterleitungen, Reaktion, Statushistorie).
// Regressionsschutz: jeder Reiter zeichnet Inhalt, keine Seitenfehler, Kernzahlen der Weiterleitungs- und Reaktionsauswertung stimmen.
const { check, start, anmelden, ende } = require('./_lauf');
(async () => {
  const { browser, page, errors } = await start();
  await anmelden(page);
  const rundgang = async label => {
    const tabs = await page.evaluate(() => sichtbareTabs().map(t => t.id));
    const leer = [];
    for (const id of tabs) {
      await page.click(`#tabs button[data-tab="${id}"]`); await page.waitForTimeout(120);
      const n = await page.evaluate(() => (document.getElementById('view')?.textContent || document.querySelector('main')?.textContent || '').trim().length);
      if (n < 20) leer.push(id);
    }
    check(`${label}: alle ${tabs.length} Reiter zeichnen Inhalt (darunter SLA-Regeln)`, tabs.includes('slaregel') && !leer.length, `leer: ${leer.join(', ')} · Reiter: ${tabs.join(', ')}`);
  };
  await page.evaluate(() => loadDemo()); await page.waitForTimeout(400);
  await page.evaluate(() => { state.slaRegeln = [slaRegelNeu()]; touch('cfg|slaRegeln'); render(); });
  await rundgang('Beispieldaten');
  // CSV: zwei Calls mit Weiterleitungen (Dispatcher → 2nd Level), Reaktion, Prio initial, Statushistorie
  await page.evaluate(() => { now = () => new Date(2026, 10, 4, 12, 0); });
  const hdr = 'Prio;Call;Eröffnet;Gruppe;Bearbeiter;Kunde;Titel;SupMan;Status;Dauer;Letzte_Weiterleitung;Letzte_Änderung;Wartend_bis;Lösung_bis;Terminänderungen;Kundenbetreuung;nicht werten für Kd.Komm.;Letzte Info an Kd.;Tage ohne Info an Kd.;Letzte externe Reaktion;Score;Externe Reaktion;Prioritaet_initial;Weiterleitungen;Statushistorie';
  const W = (d, von, vonB, nach, nachB, st, er) => `${d}|${von}|${vonB}|${nach}|${nachB}|${st}|${er}`;
  const row = (prio, call, er, gruppe, status, wl, la, reakt, hist) => [prio, call, er, gruppe, 'MF1', 'ALPHA', 'Beispiel', '', status, '1.00', '', la, '', '', '0', 'MPDV_Europe', 'Nein', '', '', '', '0', reakt, prio, wl, hist || ''].join(';');
  const csv = '﻿' + [hdr,
    row('1 - ROT', '900501', '2026-11-02T08:00:00', '2nd_MF', 'In Bearbeitung', [W('2026-11-02T08:20:00', 'Hotline', 'HO1', 'Dispatcher', '', 'Neu', 'HO1'), W('2026-11-02T09:00:00', 'Dispatcher', '', '2nd_MF', 'MF1', 'In Bearbeitung', 'DP1')].join(' # '), '2026-11-02T09:00:00', '0.02', '2026-11-02T08:00:00|Neu| # 2026-11-02T09:00:00|In Bearbeitung|Neu'),
    row('2 - BLAU', '900502', '2026-11-03T08:00:00', '2nd_HR', 'Wartend', [W('2026-11-03T08:30:00', 'Hotline', 'HO1', 'Dispatcher', '', 'Neu', 'HO1'), W('2026-11-03T10:00:00', 'Dispatcher', '', '2nd_HR', 'MF2', 'In Bearbeitung', 'DP1')].join(' # '), '2026-11-03T14:00:00', '0.1', ''),
    row('3 - GRUEN', '800503', '2026-10-05T08:00:00', '3rd_PD', 'Gelöst', W('2026-10-05T09:00:00', 'Hotline', 'HO1', '3rd_PD', 'PD1', 'In Bearbeitung', 'HO1'), '2026-10-06T10:00:00', '0.05', ''),
  ].join('\n');
  await page.evaluate(async csv => { await importCallFile(new File([csv], 'SupportBoard-Daten.csv', { type: 'text/csv' })); }, csv);
  await page.waitForTimeout(300);
  const k = await page.evaluate(() => {
    const z = { von: new Date(2026, 10, 1), bis: new Date(2026, 11, 1), label: 'November 2026' };
    const d = wlDispBearb(wlCalls().filter(c => !istUsaAsien(c.r)), z), u = wlDispBearbUeberleitung(z);
    const r1 = alleZeilen().find(r => String(r.Call) === '900501'), r2 = alleZeilen().find(r => String(r.Call) === '900502');
    return { tot: d.tot, rot: d.rows.reduce((a, x) => a + x.rot, 0), ueb: [u.ges, u.gez], st: r1.St?.length, st2: Array.isArray(r2.St) ? r2.St.length : null, prioI: prioReakt(r1), gz: r1.ExtReaktionGz, offen: allRows().length, zu: closedRows().length };
  });
  check('CSV: 2 offene + 1 geschlossener Call, Statushistorie gelesen (2 Wechsel, leere Spalte = keine), Reaktion als Geschäftszeit, Prio initial', k.offen === 2 && k.zu === 1 && k.st === 2 && k.st2 === 0 && k.prioI === 'rot' && Math.abs(k.gz - 0.02 * 86400000) < 1000, JSON.stringify(k));
  check('Weiterleitungen: Dispatcher → 2nd Level im November 2 gezählt (1 Rot), Überleitung 2 von 2', k.tot === 2 && k.rot === 1 && k.ueb.join() === '2,2', JSON.stringify(k));
  await rundgang('CSV');
  await ende(browser, errors);
})();
