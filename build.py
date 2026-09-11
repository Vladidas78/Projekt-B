# Baut die drei Ausgaben des Boards aus board.html (Quelle) und package/dist/xlsx.full.min.js (SheetJS).
#   SupportBoard.html             Produktivversion  (KANAL "prod")
#   SupportBoard-SQLTest.html     Testversion SQL   (KANAL "sqltest")
#   SupportBoard-Testserver.html  Testserver-Version (KANAL "sqltest", nur andere Beschriftung)
#   board-artifact.html           Vorschau-Datei fuer das Artefakt (Body der Testversion, ohne Huelle)
import re
content = open('board.html', encoding='utf-8').read()
sheetjs = open('package/dist/xlsx.full.min.js', encoding='utf-8').read()
def wrap(body_src, title):
    body = body_src.replace('/*__SHEETJS__*/', sheetjs).replace('<title>Supportmanagement Board</title>\n', '', 1)
    return ('<!doctype html>\n<html lang="de">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n'
            f'<title>{title}</title>\n</head>\n<body>\n' + body + '\n</body>\n</html>\n')
assert content.count('const KANAL = "prod"; /*__KANAL__*/') == 1
test_src = content.replace('const KANAL = "prod"; /*__KANAL__*/', 'const KANAL = "sqltest";')
def ersetze(s, alt, neu):
    assert s.count(alt) == 1, alt
    return s.replace(alt, neu)
srv_src = test_src
srv_src = ersetze(srv_src, 'const KANAL = "sqltest";', 'const KANAL = "sqltest"; // Testserver-Version: gleicher Kanal wie die Testversion SQL (gleicher Browser-Speicher, gleiche Team-Datei), nur andere Beschriftung')
srv_src = ersetze(srv_src, 'sqltest: { name: "Testversion SQL", badge: "TEST · SQL-Daten",', 'sqltest: { name: "Testserver-Version", badge: "TEST · TESTSERVER",')
srv_src = ersetze(srv_src, 'function kanalName(k) { return k === "prod" ? "Produktivversion" : "Testversion SQL"; }', 'function kanalName(k) { return k === "prod" ? "Produktivversion" : "Testserver-Version"; }')
srv_src = ersetze(srv_src, 'Dashboard-Quelle ist die CSV des SQL-Exports (<b>SupportBoard-Daten.csv</b> im Testordner).', 'Dashboard-Quelle ist die CSV, die der Export auf dem Testserver schreibt (<b>SupportBoard-Daten.csv</b> im Ordner des Boards).')
open('SupportBoard.html', 'w', encoding='utf-8').write(wrap(content, 'Supportmanagement Board'))
open('SupportBoard-SQLTest.html', 'w', encoding='utf-8').write(wrap(test_src, 'Supportmanagement Board – Testversion SQL'))
open('SupportBoard-Testserver.html', 'w', encoding='utf-8').write(wrap(srv_src, 'Supportmanagement Board – Testserver-Version'))
art = test_src.replace('/*__SHEETJS__*/', sheetjs.replace('�', '\\ufffd'))
open('board-artifact.html', 'w', encoding='utf-8').write(art)
print('ok')
