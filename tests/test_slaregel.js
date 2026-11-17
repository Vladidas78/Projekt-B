// Browser-Test: SLA-Regeln (ab v1.63: nur, was das Board sieht) – Regeleditor, Zeitrechnung je Call, Alarm, Lernliste, Abgleich
const { check, start, anmelden, ende, bildPfad } = require('./_lauf');
const H = 3600000, near = (a, b) => Math.abs(a - b) < 60000;
(async () => {
  const { browser, page, errors } = await start();
  await anmelden(page);
  const hdr = ['Prio', 'Call', 'Eröffnet', 'Gruppe', 'Bearbeiter', 'Kunde', 'Titel', 'SupMan', 'Status', 'Dauer', 'Letzte_Weiterleitung', 'Letzte_Änderung', 'Wartend_bis', 'Lösung_bis', 'Terminänderungen', 'Kundenbetreuung'].join(';');
  const row = (prio, call, er, gruppe, kunde, status, la) => [prio, call, er, gruppe, 'PD1', kunde, 'Beispiel', '', status, '1.00', '', la, '', '', '0', 'MPDV_Europe'].join(';');
  // Stand je Einlesen: A/C wechseln den Status, G ist ein älterer Call, B kommt am Mittwoch neu, D ist geschlossen
  const stand = { A: ['Neu', '2026-11-02T08:00:00'], C: ['Neu', '2026-11-02T08:00:00'], B: null };
  const csv = () => '﻿' + [hdr,
    row('1 - ROT', '900401', '2026-11-02T08:00:00', '2nd_MF', 'ALPHA', ...stand.A),
    row('3 - GRUEN', '900403', '2026-11-02T08:00:00', '2nd_HR', 'ALPHA', ...stand.C),
    row('1 - ROT', '900406', '2026-10-30T08:00:00', '2nd_CAQ', 'ALPHA', 'In Bearbeitung', '2026-10-30T09:00:00'),
    row('3 - GRUEN', '900405', '2026-11-02T08:00:00', '2nd_CAQ', 'CHARLIE', 'In Bearbeitung', '2026-11-02T08:00:00'),
    row('2 - BLAU', '800404', '2026-10-20T08:00:00', '2nd_MF', 'ALPHA', 'Gelöst', '2026-10-21T08:00:00'),
    ...(stand.B ? [row('2 - BLAU', '900402', '2026-11-04T09:00:00', 'Hotline', 'BRAVO', ...stand.B)] : []),
  ].join('\n');
  const einlesen = async (zeit) => {
    await page.evaluate(async ([zeit, csv]) => { now = () => new Date(zeit); await importCallFile(new File([csv], 'SupportBoard-Daten.csv', { type: 'text/csv' })); }, [zeit, csv()]);
    await page.waitForTimeout(250);
  };
  await einlesen('2026-11-02T08:05:00');                                                  // Mo 08:05: erstes Sehen
  stand.A = ['In Bearbeitung', '2026-11-02T10:00:00']; stand.C = ['In Bearbeitung', '2026-11-02T09:00:00'];
  await einlesen('2026-11-02T10:05:00');                                                  // Mo 10:05
  stand.C = ['Wartend', '2026-11-02T13:00:00'];
  await einlesen('2026-11-02T13:05:00');                                                  // Mo 13:05
  stand.A = ['Wartend', '2026-11-03T12:00:00'];
  await einlesen('2026-11-03T12:05:00');                                                  // Di 12:05
  stand.B = ['In Bearbeitung', '2026-11-04T09:00:00'];
  await einlesen('2026-11-04T09:05:00');                                                  // Mi 09:05: B neu
  await page.evaluate(() => { now = () => new Date(2026, 10, 4, 12, 0); render(); });     // Auswertung Mi 12:00
  const sv = await page.evaluate(() => Object.fromEntries(['900401', '900403', '900406', '900402', '800404'].map(c => [c, statusVerlaufEintrag(alleZeilen().find(r => String(r.Call) === c))?.v ?? null])));
  console.log('   gesehen:', JSON.stringify(sv));
  const min = s => Math.round(new Date(s).getTime() / 60000);
  check('Lernliste: A Neu (08:05 gesehen) → In Bearbeitung Mo 10:00 → Wartend Di 12:00 (letzte Änderung); D geschlossen nicht verfolgt', JSON.stringify(sv['900401']) === JSON.stringify([[min('2026-11-02T08:05:00'), 'Neu'], [min('2026-11-02T10:00:00'), 'In Bearbeitung'], [min('2026-11-03T12:00:00'), 'Wartend']]) && sv['800404'] === null && sv['900406'].length === 1, JSON.stringify(sv));
  // Reiter und Regeln per Oberflaeche
  await page.click('#tabs button[data-tab="slaregel"]'); await page.waitForTimeout(200);
  const info = await page.evaluate(() => document.querySelector('#srBasis')?.textContent.replace(/\s+/g, ' ') || '');
  check('Karte „So zählt das Board“: ab Eröffnung, keine Abfrage-Änderung, 5 Calls verfolgt seit Mo 08:05, 4 Wechsel', /ab Eröffnung/.test(info) && /Keine Änderung an Abfrage oder Exportskript nötig/.test(info) && /5 Calls seit 02\.11\.2026, 08:05 · 4 Statuswechsel gesehen/.test(info) && !/Abfrage-Status/.test(info), info);
  await page.click('#btnSrAdd'); await page.waitForTimeout(200);
  const r0 = await page.evaluate(() => JSON.parse(JSON.stringify(state.slaRegeln)));
  check('Regel hinzufügen: Arbeitszeiten, zählt Neu + In Bearbeitung, pausiert Wartend, Ziel 4:00, alle Kunden/Prios', r0.length === 1 && r0[0].gz === true && r0[0].zaehlen.join() === 'Neu,In Bearbeitung' && r0[0].pausieren.join() === 'Wartend' && r0[0].ziel === 4 && r0[0].prio.length === 0 && r0[0].kunden === '', JSON.stringify(r0));
  const setze = async (sel, wert) => { await page.fill(sel, wert); await page.$eval(sel, el => el.dispatchEvent(new Event('change'))); await page.waitForTimeout(150); };
  await setze('[data-sr="0|kunden"]', 'ALPHA');
  await setze('[data-sr="0|ziel"]', '8');
  await page.click('#btnSrAdd'); await page.waitForTimeout(200);
  await page.click('[data-srprio="1|blau"]'); await page.waitForTimeout(150);
  await page.selectOption('[data-sr="1|gz"]', '0'); await page.waitForTimeout(150);
  await setze('[data-sr="1|ziel"]', '120 Min.');
  const r1 = await page.evaluate(() => ({ r: JSON.parse(JSON.stringify(state.slaRegeln)), feld: document.querySelector('[data-sr="1|ziel"]').value, label: slaRegelLabel(state.slaRegeln[1]) }));
  check('Regel 1 ALPHA, Ziel 8; Regel 2 Blau, Kalenderzeit, „120 Min.“ = 2 Std., Feld zeigt 2:00', r1.r[0].kunden === 'ALPHA' && r1.r[0].ziel === 8 && r1.r[1].prio.join() === 'blau' && r1.r[1].gz === false && r1.r[1].ziel === 2 && r1.feld === '2:00' && /2,0 Std\.$/.test(r1.label), JSON.stringify(r1));
  const p = await page.evaluate(() => ({ a: slaZielStd('1:30'), b: slaZielStd('0,25'), c: slaZielStd('90 min'), d: slaZielStd('2 h'), e: slaZielStd('x'), f: fmtZielEingabe(0.25), g: fmtStd(0.25 * 3600000) }));
  check('Eingabe des Ziels: 1:30 / 0,25 / 90 min / 2 h erkannt, Unsinn abgelehnt, 0,25 Std. = 0:15 = 15 Min.', p.a === 1.5 && p.b === 0.25 && p.c === 1.5 && p.d === 2 && Number.isNaN(p.e) && p.f === '0:15' && p.g === '15 Min.', JSON.stringify(p));
  await setze('[data-sr="1|ziel"]', 'bald');
  check('Unsinniges Ziel ändert die Regel nicht', await page.evaluate(() => state.slaRegeln[1].ziel === 2), '');
  // Chip-Ausschluss
  const wIdx = await page.evaluate(() => slaStatusOptionen().indexOf('Wartend'));
  await page.click(`[data-srst="1|zaehlen|${wIdx}"]`); await page.waitForTimeout(150);
  const r2 = await page.evaluate(() => JSON.parse(JSON.stringify(state.slaRegeln[1])));
  await page.click(`[data-srst="1|pausieren|${wIdx}"]`); await page.waitForTimeout(150);
  const r3 = await page.evaluate(() => JSON.parse(JSON.stringify(state.slaRegeln[1])));
  check('Status zählt oder pausiert, nie beides', r2.zaehlen.includes('Wartend') && !r2.pausieren.includes('Wartend') && r3.pausieren.includes('Wartend') && !r3.zaehlen.includes('Wartend'), JSON.stringify([r2, r3]));
  // Rechnung
  const get = () => page.evaluate(() => state.slaRegeln.map(rg => slaRegelTreffer(rg).list.map(h => ({ c: String(h.r.Call), ges: h.ges, akt: h.akt, inakt: h.inakt, alarm: h.alarm, ang: h.v.angenommen }))));
  let t = await get();
  const f = (i, c) => t[i].find(x => x.c === c);
  const A = f(0, '900401'), C = f(0, '900403'), G = f(0, '900406'), B = f(1, '900402');
  console.log('   A:', JSON.stringify(A), '\n   C:', JSON.stringify(C), '\n   G:', JSON.stringify(G), '\n   B:', JSON.stringify(B));
  check('Regel 1 trifft A, C, G (D geschlossen, B/E andere Kunden)', t[0].map(x => x.c).sort().join() === '900401,900403,900406', JSON.stringify(t[0].map(x => x.c)));
  check('A: aktiv 13,5 Std. (Neu 2 + In Bearbeitung 11,5), inaktiv 9,5, Gesamt 23, Alarm, nicht angenommen', A && near(A.akt, 13.5 * H) && near(A.inakt, 9.5 * H) && near(A.ges, 23 * H) && A.alarm && !A.ang, JSON.stringify(A));
  check('C: aktiv 5 Std., inaktiv 18 (Wartend ab Mo 13:00), kein Alarm', C && near(C.akt, 5 * H) && near(C.inakt, 18 * H) && !C.alarm, JSON.stringify(C));
  check('G (älterer Call, erst Mo gesehen): In Bearbeitung ab Eröffnung Fr angenommen – aktiv 31,5 Std., Alarm', G && near(G.akt, 31.5 * H) && G.alarm && G.ang, JSON.stringify(G));
  check('B (Regel 2, Kalenderzeit): 3 Std. ≥ 2 Std. → Alarm; nur B in Regel 2', B && near(B.akt, 3 * H) && B.alarm && t[1].length === 1, JSON.stringify(t[1]));
  // Anzeige
  await page.evaluate(() => { pruefeSlaRegeln(); render(); }); await page.waitForTimeout(200);
  const ids = await page.evaluate(() => state.slaRegeln.map(rg => rg.id));
  const ui = await page.evaluate(id0 => ({
    badge: document.querySelector('#tabs [data-tab="slaregel"] .cnt')?.textContent.trim(),
    rows0: [...document.querySelectorAll(`#srErg-${id0} tbody tr`)].map(tr => [...tr.querySelectorAll('td')].map(td => td.textContent.replace(/\s+/g, ' ').trim())),
    alarmRows: document.querySelectorAll(`#srErg-${id0} tbody tr.sr-alarm`).length, kursiv: document.querySelectorAll(`#srErg-${id0} .srseg.g`).length, gemeldet: [...slaRegelGemeldet]
  }), ids[0]);
  console.log('   Zeilen Regel 1:', JSON.stringify(ui.rows0));
  const zA = ui.rows0.find(z => z[0].startsWith('900401')), zG = ui.rows0.find(z => z[0].startsWith('900406'));
  check('Reiter-Zähler 3 (A, G, B), 2 Alarmzeilen in Regel 1, G zuerst, Hinweise gemeldet', ui.badge === '3' && ui.alarmRows === 2 && ui.rows0[0][0].startsWith('900406') && ui.gemeldet.includes(ids[0] + '|900401') && ui.gemeldet.includes(ids[0] + '|900406') && ui.gemeldet.includes(ids[1] + '|900402'), JSON.stringify(ui));
  check('Zeile A: 23,0 / 13,5 / 9,5 / erreicht / gesehen seit 02.11.2026, 08:05', zA && zA[6] === '23,0 Std.' && zA[7] === '13,5 Std.' && zA[8] === '9,5 Std.' && /erreicht/.test(zA[9]) && zA[10] === '02.11.2026, 08:05', JSON.stringify(zA));
  check('Zeile G: „davor angenommen“, Verlauf kursiv', zG && /davor angenommen/.test(zG[10]) && ui.kursiv >= 1, JSON.stringify(zG));
  const cp = await page.evaluate(() => slaRegelTabelle(state.slaRegeln[0]).plain);
  check('Kopie: A-Zeile mit Zeiten, Hinweis, gesehen seit und Verlauf', /^900401\tRot\tALPHA\tBeispiel\t2nd_MF\tPD1\tWartend\t23,0 Std\.\t13,5 Std\.\t9,5 Std\.\t0 Min\.\t8,0 Std\.\terreicht\t02\.11\.2026, 08:05\tNeu .* › In Bearbeitung .* › Wartend .*pausiert\)$/m.test(cp) && /^900406\t.*\t02\.11\.2026, 08:05 \(davor angenommen\)\t/m.test(cp), cp);
  // Startseite
  await page.click('#tabs button[data-tab="heute"]'); await page.waitForTimeout(250);
  const heute = await page.evaluate(() => ({ karte: document.querySelector('#srHeute h2')?.textContent || '', rows: [...document.querySelectorAll('#srHeute tbody tr')].map(tr => tr.textContent.replace(/\s+/g, ' ').trim()) }));
  check('Startseite: Karte „Schwellenwert erreicht“ mit A, G und B', /Schwellenwert erreicht/.test(heute.karte) && heute.rows.length === 3 && ['900401', '900406', '900402'].every(c => heute.rows.some(x => x.includes(c))), JSON.stringify(heute));
  await page.click('#srHeute [data-goto="slaregel"]'); await page.waitForTimeout(200);
  check('Knopf auf der Startseite führt in den Reiter', await page.evaluate(() => activeTab === 'slaregel'), '');
  // Arbeitszeiten Nein
  await page.selectOption('[data-sr="0|gz"]', '0'); await page.waitForTimeout(200);
  t = await get();
  const A2 = t[0].find(x => x.c === '900401');
  check('Arbeitszeiten Nein: A Gesamt 52 Std., aktiv 28 (Neu 2 + In Bearbeitung 26), inaktiv 24', A2 && near(A2.ges, 52 * H) && near(A2.akt, 28 * H) && near(A2.inakt, 24 * H), JSON.stringify(A2));
  // Team-Abgleich (auch Einträge aus v1.62 mit drittem Feld)
  const mg = await page.evaluate(() => {
    const a = { '1': { v: [[100, 'Neu', 1], [200, 'Wartend']] } }, b = { '1': { v: [[100, 'Neu'], [150, 'Wartend'], [300, 'In Bearbeitung']] }, '2': { v: [[50, 'Neu']] } };
    return { m: mergeStatusVerlaufMonat(a, b), shared: SHARED_MAPS.includes('statusVerlauf') && SHARED_CFG.includes('slaRegeln') };
  });
  check('Abgleich: Vereinigung je Call, gleicher Status hintereinander → frühester', JSON.stringify(mg.m) === JSON.stringify({ '1': { v: [[100, 'Neu'], [150, 'Wartend'], [300, 'In Bearbeitung']] }, '2': { v: [[50, 'Neu']] } }) && mg.shared, JSON.stringify(mg));
  // Regel aus, Regel loeschen
  await page.click('[data-sr="1|aktiv"]'); await page.waitForTimeout(200);
  const aus = await page.evaluate(id1 => ({ n: slaRegelAlarmCalls(), karte: !!document.querySelector(`#srErg-${id1}`) }), ids[1]);
  check('Regel 2 aus: keine Ergebniskarte, nur noch A und G im Alarm', aus.n === 2 && !aus.karte, JSON.stringify(aus));
  await page.click('[data-srdel="1"]'); await page.waitForTimeout(200);
  check('Regel löschen', await page.evaluate(() => state.slaRegeln.length === 1), '');
  // Beispieldaten
  await page.evaluate(() => { now = () => new Date(); loadDemo(); }); await page.waitForTimeout(400);
  await page.evaluate(() => { state.slaRegeln = [slaRegelNeu()]; touch('cfg|slaRegeln'); render(); }); await page.waitForTimeout(200);
  await page.click('#tabs button[data-tab="slaregel"]'); await page.waitForTimeout(300);
  const demo = await page.evaluate(() => document.querySelectorAll('[id^="srErg-"] tbody tr').length);
  check('Beispieldaten: Regel zeigt Calls ohne Fehler', demo > 0, String(demo));
  await page.screenshot({ path: bildPfad('slaregel.png'), fullPage: false });
  await ende(browser, errors);
})();
