' Startet den Datenexport ohne sichtbares Fenster.
' In der Aufgabenplanung als Programm eintragen:  wscript.exe "C:\MPDV\SupportTool\SupportBoard-Export-leise.vbs"
' Der Pfad zum Skript steht in der naechsten Zeile - bei Bedarf anpassen.
Set fso = CreateObject("Scripting.FileSystemObject")
skript = fso.GetParentFolderName(WScript.ScriptFullName) & "\SupportBoard-Export.ps1"
CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & skript & """", 0, False
