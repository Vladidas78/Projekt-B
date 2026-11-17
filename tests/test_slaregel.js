// Browser-Test: SLA-Regeln (ab v1.62) – Regeleditor, Zeitrechnung je Call, Alarm, Lernliste, Statushistorie, Abgleich
const { check, start, anmelden, ende, bildPfad } = require('./_lauf');
const H = 3600000, near = (a, b) => Math.abs(a - b) < 60000;
(async () => {
  const { browser, page, errors } = await start();
  await page.evaluate(() => { now = () => new Date(2026, 10, 4, 12, 0); }); // Mi 04.11.2026 12:00
  await anmelden(page);
  const W = (d, von, nach, st) => `${d}|${von}|HO1|${nach}|PD1|${st}|HO1`;
  const mkCsv = (opt = {}) => {
    const hdr = ['Prio', 'Call', 'Eröffnet', 'Gruppe', 'Bearbeiter', 'Kunde', 'Titel', 'SupMan', 'Status', 'Dauer', 'Letzte_Weiterleitung', 'Letzte_Änderung', 'Wartend_bis', 'Lösung_bis', 'Terminänderungen', 'Kundenbetreuung', 'Status seit', 'Weiterleitungen'];
    if (opt.hist) hdr.push('Statushistorie');
    const row = (prio, call, er, gruppe, kunde, status, la, seit, wl, hist) => { const a = [prio, call, er, gruppe, 'PD1', kunde, 'Beispiel', '', status, '1.00', '', la, '', '', '0', 'MPDV_Europe', seit || '', wl || '']; if (opt.hist) a.push(hist || ''); return a.join(';'); };
    const aStatus = opt.aIb ? 'In Bearbeitung' : 'Wartend', aLa = opt.aIb ? '2026-11-04T11:00:00' : '2026-11-03T12:00:00';
    const aHist = ['2026-11-02T08:00:00|Neu|', '2026-11-02T10:00:00|In Bearbeitung|Neu', '2026-11-02T15:00:00|Wartend|In Bearbeitung', '2026-11-04T11:00:00|In Bearbeitung|Wartend'].join(' # ');
    return '﻿' + [hdr.join(';'),
      // A: ALPHA Rot, Hotline -> Dispatcher (Neu) -> 2nd_MF (In Bearbeitung), heute Wartend, letzte Aenderung Di 12:00
      row('1 - ROT', '900401', '2026-11-02T08:00:00', '2nd_MF', 'ALPHA', aStatus, aLa, '', [W('2026-11-02T08:30:00', 'Hotline', 'Dispatcher', 'Neu'), W('2026-11-02T10:00:00', 'Dispatcher', '2nd_MF', 'In Bearbeitung')].join(' # '), aHist),
      // B: BRAVO Blau, keine Weiterleitung, In Bearbeitung seit Eroeffnung (Mi 09:00)
      row('2 - BLAU', '900402', '2026-11-04T09:00:00', 'Hotline', 'BRAVO', 'In Bearbeitung', '2026-11-04T09:30:00'),
      // C: ALPHA Gruen, Hotline -> 2nd_HR (In Bearbeitung) Mo 09:00, Wartend laut „Status seit“ Mo 13:00
      row('3 - GRUEN', '900403', '2026-11-02T08:00:00', '2nd_HR', 'ALPHA', 'Wartend', '2026-11-04T10:00:00', '2026-11-02T13:00:00', W('2026-11-02T09:00:00', 'Hotline', '2nd_HR', 'In Bearbeitung')),
      // D: ALPHA Blau, geschlossen – nie in einer Regel
      row('2 - BLAU', '800404', '2026-10-20T08:00:00', '2nd_MF', 'ALPHA', 'Gelöst', '2026-10-21T08:00:00'),
      // E: CHARLIE Gruen
      row('3 - GRUEN', '900405', '2026-11-03T08:00:00', '2nd_CAQ', 'CHARLIE', 'In Bearbeitung', '2026-11-03T08:00:00'),
    ].join('\n');
  };
  const laden = async csv => { await page.evaluate(async csv => { await importCallFile(new File([csv], 'SupportBoard-Daten.csv', { type: 'text/csv' })); }, csv); await page.waitForTimeout(300); };
  await laden(mkCsv());
  // Reiter und Regel per Oberflaeche anlegen
  await page.click('#tabs button[data-tab="slaregel"]'); await page.waitForTimeout(200);
  const leer = await page.evaluate(() => document.querySelector('#srBasis')?.textContent.replace(/\s+/g, ' ') || '');
  check('Reiter „SLA-Regeln“ mit Datenbasis: Statushistorie fehlt, Status seit vorhanden, Weiterleitungen bei 2 von 4 offenen, gelernt', /Statushistorie .*fehlt/.test(leer) && /Status seit .*vorhanden/.test(leer) && /bei 2 von 4 offenen Calls/.test(leer) && /Gelernte Statuswechsel .*4 Calls verfolgt · Statuswechsel mit genauem Zeitpunkt: 1 \(der erste am 02\.11\.2026, 13:00\)/.test(leer), leer.slice(0, 700));
  await page.click('#btnSrAdd'); await page.waitForTimeout(200);
  const r0 = await page.evaluate(() => JSON.parse(JSON.stringify(state.slaRegeln)));
  check('Regel hinzufügen: Vorgabe Arbeitszeiten, zählt Neu + In Bearbeitung, pausiert Wartend, Ziel 8, alle Kunden/Prios', r0.length === 1 && r0[0].gz === true && r0[0].zaehlen.join() === 'Neu,In Bearbeitung' && r0[0].pausieren.join() === 'Wartend' && r0[0].ziel === 8 && r0[0].prio.length === 0 && r0[0].kunden === '' && r0[0].typ === 'slaFast', JSON.stringify(r0));
  await page.fill('[data-sr="0|kunden"]', 'ALPHA'); await page.$eval('[data-sr="0|kunden"]', el => el.dispatchEvent(new Event('change'))); await page.waitForTimeout(200);
  // Regel 2: Blau, Kalenderzeit, Ziel 2 Std.
  await page.click('#btnSrAdd'); await page.waitForTimeout(200);
  await page.click('[data-srprio="1|blau"]'); await page.waitForTimeout(150);
  await page.selectOption('[data-sr="1|gz"]', '0'); await page.waitForTimeout(150);
  await page.fill('[data-sr="1|ziel"]', '2'); await page.$eval('[data-sr="1|ziel"]', el => el.dispatchEvent(new Event('change'))); await page.waitForTimeout(200);
  const r1 = await page.evaluate(() => JSON.parse(JSON.stringify(state.slaRegeln)));
  check('Regel 1 Kunde ALPHA; Regel 2 Prio Blau, Kalenderzeit, Ziel 2 Std.', r1[0].kunden === 'ALPHA' && r1[1].prio.join() === 'blau' && r1[1].gz === false && r1[1].ziel === 2, JSON.stringify(r1));
  // Chip-Ausschluss: Wartend in Regel 2 auf „zaehlen“ -> verschwindet aus „pausieren“
  const wIdx = await page.evaluate(() => slaStatusOptionen().indexOf('Wartend'));
  await page.click(`[data-srst="1|zaehlen|${wIdx}"]`); await page.waitForTimeout(150);
  const r2 = await page.evaluate(() => JSON.parse(JSON.stringify(state.slaRegeln[1])));
  await page.click(`[data-srst="1|zaehlen|${wIdx}"]`); await page.waitForTimeout(150);
  const r3 = await page.evaluate(() => JSON.parse(JSON.stringify(state.slaRegeln[1])));
  check('Status zählt oder pausiert, nie beides (Wartend wandert, zweiter Klick nimmt ihn heraus)', r2.zaehlen.includes('Wartend') && !r2.pausieren.includes('Wartend') && !r3.zaehlen.includes('Wartend') && !r3.pausieren.includes('Wartend'), JSON.stringify([r2, r3]));
  await page.evaluate(() => { state.slaRegeln[1].pausieren = ['Wartend']; touch('cfg|slaRegeln'); render(); });
  // Rechnung
  const get = () => page.evaluate(() => state.slaRegeln.map(rg => { const t = slaRegelTreffer(rg); return { alarmN: t.alarmN, list: t.list.map(h => ({ c: String(h.r.Call), ges: h.ges, akt: h.akt, inakt: h.inakt, rest: h.rest, alarm: h.alarm, basis: h.basis.txt, seg: h.seg.map(s => [s.s, s.art, s.q.join('+'), Math.round(s.d / 60000)]) })) }; }));
  let t = await get();
  const A = t[0].list.find(x => x.c === '900401'), C = t[0].list.find(x => x.c === '900403'), B = t[1].list.find(x => x.c === '900402');
  console.log('   A:', JSON.stringify(A), '\n   C:', JSON.stringify(C), '\n   B:', JSON.stringify(B));
  check('Regel 1 trifft A und C (D geschlossen, B/E andere Kunden)', t[0].list.map(x => x.c).sort().join() === '900401,900403', JSON.stringify(t[0].list.map(x => x.c)));
  check('A: aktiv 13,5 Std. (Neu 2 + In Bearbeitung 11,5), inaktiv 9,5 (Wartend ab letzter Änderung), Gesamt 23, Alarm, Basis Weiterleitungen · geschätzt', A && near(A.akt, 13.5 * H) && near(A.inakt, 9.5 * H) && near(A.ges, 23 * H) && A.alarm && A.basis === 'Weiterleitungen · geschätzt' && A.seg.length === 3, JSON.stringify(A));
  check('C: „Status seit“ setzt den Beginn von Wartend exakt – aktiv 5 Std., inaktiv 18, kein Alarm', C && near(C.akt, 5 * H) && near(C.inakt, 18 * H) && near(C.ges, 23 * H) && !C.alarm && /Status seit/.test(C.basis) && !/geschätzt/.test(C.basis), JSON.stringify(C));
  check('B (Regel 2, Kalenderzeit): 3 Std. In Bearbeitung ≥ 2 Std. Ziel → Alarm, Basis „nur Status jetzt“; nur B in Regel 2', B && near(B.akt, 3 * H) && B.alarm && B.basis === 'nur Status jetzt' && t[1].list.length === 1, JSON.stringify(t[1]));
  // Anzeige
  await page.evaluate(() => { pruefeSlaRegeln(); render(); }); await page.waitForTimeout(200);
  const ui = await page.evaluate(() => ({
    badge: document.querySelector('#tabs [data-tab="slaregel"] .cnt')?.textContent.trim(), hidden: document.querySelector('#tabs [data-tab="slaregel"] .cnt')?.classList.contains('hidden'),
    rows0: [...document.querySelectorAll(`#srErg-${state.slaRegeln[0].id} tbody tr`)].map(tr => [...tr.querySelectorAll('td')].map(td => td.textContent.replace(/\s+/g, ' ').trim())),
    alarmRow: !!document.querySelector(`#srErg-${state.slaRegeln[0].id} tbody tr.sr-alarm`), segs: document.querySelectorAll('.srseg').length, kursiv: document.querySelectorAll('.srseg.g').length, gemeldet: [...slaRegelGemeldet]
  }));
  const [state0, state1] = await page.evaluate(() => state.slaRegeln.map(rg => rg.id));
  console.log('   Zeilen Regel 1:', JSON.stringify(ui.rows0));
  check('Reiter-Zähler 2 (A, B), Alarmzeile markiert, Verlauf als Chips (geschätzte kursiv), Hinweis für A (Regel 1) und B (Regel 2) gemeldet', ui.badge === '2' && !ui.hidden && ui.alarmRow && ui.segs >= 5 && ui.kursiv >= 1 && ui.gemeldet.includes(state0 + '|900401') && ui.gemeldet.includes(state1 + '|900402'), JSON.stringify(ui));
  check('Tabelle Regel 1: A zuerst mit Gesamt 23,0 / aktiv 13,5 / inaktiv 9,5 / erreicht', ui.rows0[0] && ui.rows0[0][0].startsWith('900401') && ui.rows0[0][6] === '23,0 Std.' && ui.rows0[0][7] === '13,5 Std.' && ui.rows0[0][8] === '9,5 Std.' && /erreicht/.test(ui.rows0[0][9]), JSON.stringify(ui.rows0[0]));
  const cp = await page.evaluate(() => slaRegelTabelle(state.slaRegeln[0]).plain);
  check('Kopie: A-Zeile mit Zeiten, Hinweis, Datenbasis und Verlauf', /^900401\tRot\tALPHA\tBeispiel\t2nd_MF\tPD1\tWartend\t23,0 Std\.\t13,5 Std\.\t9,5 Std\.\t\d+ Min\.\t8,0 Std\.\terreicht\tWeiterleitungen · geschätzt\tNeu .* › In Bearbeitung .* › Wartend .*pausiert\)$/m.test(cp), cp);
  // Startseite
  await page.click('#tabs button[data-tab="heute"]'); await page.waitForTimeout(250);
  const heute = await page.evaluate(() => ({ karte: !!document.querySelector('#srHeute'), rows: [...document.querySelectorAll('#srHeute tbody tr')].map(tr => tr.textContent.replace(/\s+/g, ' ').trim()) }));
  check('Startseite: Karte „SLA-Regeln: Eskalationsziel erreicht“ mit A und B', heute.karte && heute.rows.length === 2 && heute.rows.some(x => /900401/.test(x)) && heute.rows.some(x => /900402/.test(x)), JSON.stringify(heute));
  await page.click('#srHeute [data-goto="slaregel"]'); await page.waitForTimeout(200);
  check('Knopf auf der Startseite führt in den Reiter', await page.evaluate(() => activeTab === 'slaregel'), '');
  // Lernen: A wechselt Mi 11:00 auf In Bearbeitung
  await laden(mkCsv({ aIb: true }));
  t = await get();
  const A2 = t[0].list.find(x => x.c === '900401');
  const sv = await page.evaluate(() => JSON.parse(JSON.stringify(statusVerlaufEintrag(alleZeilen().find(r => String(r.Call) === '900401')))));
  console.log('   A gelernt:', JSON.stringify(sv), JSON.stringify(A2));
  check('Gelernt: A Wartend (geschätzt, eingefroren) → In Bearbeitung Mi 11:00; aktiv 14,5, inaktiv 8,5', sv && sv.v.length === 2 && sv.v[0][1] === 'Wartend' && sv.v[0][2] === 1 && sv.v[1][1] === 'In Bearbeitung' && !sv.v[1][2] && near(A2.akt, 14.5 * H) && near(A2.inakt, 8.5 * H) && /gelernt/.test(A2.basis), JSON.stringify([sv, A2]));
  // Aeltere Datei (A wieder Wartend mit letzter Aenderung Di 12:00) darf das Gelernte nicht zurueckdrehen
  await laden(mkCsv());
  const svAlt = await page.evaluate(() => JSON.parse(JSON.stringify(statusVerlaufEintrag(alleZeilen().find(r => String(r.Call) === '900401')))));
  check('Ältere Datei: kein falscher Rückwechsel in der Lernliste', svAlt && svAlt.v.length === 2 && svAlt.v[1][1] === 'In Bearbeitung', JSON.stringify(svAlt));
  // Statushistorie ersetzt alles
  await laden(mkCsv({ aIb: true, hist: true }));
  t = await get();
  const A3 = t[0].list.find(x => x.c === '900401');
  check('Statushistorie: A aktiv 8,0 (Neu 2 + IB 5 + IB 1), inaktiv 15,0, Alarm genau am Ziel, Basis „Statushistorie“', A3 && near(A3.akt, 8 * H) && near(A3.inakt, 15 * H) && A3.alarm && A3.basis === 'Statushistorie', JSON.stringify(A3));
  await page.click('#tabs button[data-tab="slaregel"]'); await page.waitForTimeout(200);
  await page.selectOption('[data-sr="0|gz"]', '0'); await page.waitForTimeout(200);
  t = await get();
  const A4 = t[0].list.find(x => x.c === '900401');
  check('Arbeitszeiten Nein: A Gesamt 52 Std., aktiv 8, inaktiv 44 (Kalenderzeit)', A4 && near(A4.ges, 52 * H) && near(A4.akt, 8 * H) && near(A4.inakt, 44 * H), JSON.stringify(A4));
  const basis2 = await page.evaluate(() => document.querySelector('#srBasis')?.textContent.replace(/\s+/g, ' ') || '');
  check('Datenbasis meldet die Statushistorie', /liefert der Export/.test(basis2), basis2.slice(0, 300));
  // Team-Abgleich
  const mg = await page.evaluate(() => {
    const a = { '1': { v: [[100, 'Neu', 1], [200, 'Wartend']] } }, b = { '1': { v: [[100, 'Neu'], [150, 'Wartend', 1], [300, 'In Bearbeitung']] }, '2': { v: [[50, 'Neu', 1]] } };
    return { m: mergeStatusVerlaufMonat(a, b), shared: SHARED_MAPS.includes('statusVerlauf') && SHARED_CFG.includes('slaRegeln') };
  });
  check('Abgleich: Vereinigung je Call, gleicher Status hintereinander → frühester, sicher vor geschätzt', JSON.stringify(mg.m) === JSON.stringify({ '1': { v: [[100, 'Neu'], [150, 'Wartend', 1], [300, 'In Bearbeitung']] }, '2': { v: [[50, 'Neu', 1]] } }) && mg.shared, JSON.stringify(mg));
  // Regel aus -> kein Alarm; Regel loeschen
  await page.click('[data-sr="1|aktiv"]'); await page.waitForTimeout(200);
  const aus = await page.evaluate(() => ({ n: slaRegelAlarmCalls(), karte: !!document.querySelector(`#srErg-${state.slaRegeln[1].id}`) }));
  check('Regel 2 aus: kein Ergebnis mehr, nur noch A im Alarm', aus.n === 1 && !aus.karte, JSON.stringify(aus));
  await page.click('[data-srdel="1"]'); await page.waitForTimeout(200);
  check('Regel löschen', await page.evaluate(() => state.slaRegeln.length === 1), '');
  // Beispieldaten
  await page.evaluate(() => { now = () => new Date(); loadDemo(); }); await page.waitForTimeout(400);
  await page.evaluate(() => { state.slaRegeln = [slaRegelNeu()]; touch('cfg|slaRegeln'); render(); }); await page.waitForTimeout(200);
  await page.click('#tabs button[data-tab="slaregel"]'); await page.waitForTimeout(300);
  const demo = await page.evaluate(() => ({ rows: document.querySelectorAll('[id^="srErg-"] tbody tr').length, basis: [...new Set([...document.querySelectorAll('[id^="srErg-"] tbody tr td:nth-child(11)')].map(td => td.textContent.trim()))] }));
  console.log('   Demo:', JSON.stringify(demo));
  check('Beispieldaten: Regel zeigt Calls ohne Fehler', demo.rows > 0, JSON.stringify(demo));
  await page.screenshot({ path: bildPfad('slaregel.png'), fullPage: false });
  await ende(browser, errors);
})();
