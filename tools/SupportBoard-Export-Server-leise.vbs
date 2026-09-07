' Reserve-Starter fuer die Server-Fassung: startet den Export ohne jedes Fenster.
' Normalerweise nicht noetig - unter einem Dienstkonto laeuft die Aufgabe unsichtbar.
' Nur einsetzen, wenn trotzdem ein Fenster erscheint (Aufgabe laeuft dann interaktiv).
' Aktion der Aufgabe tauschen (PowerShell als Administrator):
'   $a = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument '"C:\Tools\SupportBoard\SupportBoard-Export-Server-leise.vbs"'
'   Set-ScheduledTask -TaskName "Supportboard Datenexport (Server)" -Action $a
Set fso = CreateObject("Scripting.FileSystemObject")
skript = fso.GetParentFolderName(WScript.ScriptFullName) & "\SupportBoard-Export-Server.ps1"
CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File """ & skript & """", 0, False
