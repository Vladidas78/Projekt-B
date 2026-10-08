# Baut die zwei Ausgaben des Boards aus board.html (Quelle) und package/dist/xlsx.full.min.js (SheetJS).
#   SupportBoard.html         Produktivversion  (KANAL "prod")
#   SupportBoard_Test.html    Testversion       (KANAL "sqltest": eigener Browser-Speicher, eigene Team-Datei; neue Staende werden hier zuerst erprobt)
#   board-artifact.html       Vorschau-Datei fuer das Artefakt (Body der Testversion, ohne Huelle)
import re
content = open('board.html', encoding='utf-8').read()
sheetjs = open('package/dist/xlsx.full.min.js', encoding='utf-8').read()
def wrap(body_src, title):
    body = body_src.replace('/*__SHEETJS__*/', sheetjs).replace('<title>Supportmanagement Board</title>\n', '', 1)
    return ('<!doctype html>\n<html lang="de">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n'
            f'<title>{title}</title>\n</head>\n<body>\n' + body + '\n</body>\n</html>\n')
assert content.count('const KANAL = "prod"; /*__KANAL__*/') == 1
test_src = content.replace('const KANAL = "prod"; /*__KANAL__*/', 'const KANAL = "sqltest";')
open('SupportBoard.html', 'w', encoding='utf-8').write(wrap(content, 'Supportmanagement Board'))
open('SupportBoard_Test.html', 'w', encoding='utf-8').write(wrap(test_src, 'Supportmanagement Board \u2013 Testversion'))
art = test_src.replace('/*__SHEETJS__*/', sheetjs.replace('\ufffd', '\\ufffd'))
open('board-artifact.html', 'w', encoding='utf-8').write(art)
print('ok')
