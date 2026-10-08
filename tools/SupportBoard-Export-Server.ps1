<#
    Supportmanagement-Board - Datenexport, SERVER-FASSUNG
    ---------------------------------------------------------------------------
    Laeuft auf einem Server (z. B. dem OT-Testserver) rund um die Uhr in der
    Aufgabenplanung, unabhaengig davon, ob jemand angemeldet ist. Fuehrt die
    Abfrage aus SupportBoard-Abfrage.sql aus und legt das Ergebnis als CSV
    im Team-Ordner ab. Das Board liest diese Datei wie gewohnt.

    Zusatzabfragen (optional): Liegen im Skriptordner die Dateien
      SupportBoard-Abfrage-Reaktion.sql       (seit v1.41: Spalten Call, Externe Reaktion)
      SupportBoard-Abfrage-Weiterleitung.sql  (seit v1.43: Spalten Call, Weiterleitungen)
    werden sie zusaetzlich ausgefuehrt. Jede liefert je Call genau einen Wert
    (zwei Spalten: Call und Wert). Das Skript haengt den Wert ueber die
    Call-Nummer an die Zeilen der Hauptabfrage an - es entsteht weiterhin EINE
    CSV mit einer Zeile je Call. Weitere Spalten der Reaktionsabfrage werden
    ignoriert. Nur bei der Weiterleitungsabfrage gilt: Liefert sie mehr als
    zwei Spalten (Rohform: je Weiterleitung eine Zeile mit Call, Datum,
    vorherige Gruppe, vorheriger Bearbeiter, aktuelle Gruppe, aktueller
    Bearbeiter, Folgestatus, Ersteller), buendelt das Skript die Zeilen je Call
    selbst zu einem Text (Felder mit |, Weiterleitungen mit " # ", nach Datum). Fehlt eine Datei, ist sie leer oder schlaegt
    die Abfrage fehl (z. B. weil die Tabelle auf der Schattendatenbank gerade
    abgestellt ist), wird die CSV trotzdem geschrieben; die Spalte bleibt dann
    leer und das Log zeigt eine WARNUNG.

    Unterschiede zur Arbeitsplatz-Fassung (SupportBoard-Export.ps1):
      - Einrichtung per Schalter: -Install legt die Aufgabe an, -Uninstall
        entfernt sie, -Status zeigt Aufgabe, Log und Alter der CSV.
      - Laeuft unter einem Dienstkonto (empfohlen) oder als SYSTEM.
      - Passwort (nur bei SQL-Anmeldung) ist an den RECHNER gebunden, nicht
        an das Konto, das es hinterlegt hat. Ein Administrator fuehrt
        -SetPassword einmal aus, die Aufgabe kann es unter dem Dienstkonto
        lesen. Die Datei ist per Zugriffsrechten auf Administratoren,
        SYSTEM und das Dienstkonto beschraenkt.
      - Log liegt im Zielordner (vom Arbeitsplatz aus lesbar), Fehler
        zusaetzlich im Windows-Ereignisprotokoll (Anwendung).
      - Ersatzpfad: Die CSV wird zusaetzlich in einen Ordner auf dem Server
        gespiegelt, der als Freigabe dient. Kommt der Server nicht an den
        Teamshare, zeigt das Board einfach auf diese Freigabe.
        -ErsatzEinrichten legt Ordner, Rechte und Freigabe an.

    NUR LESEN - dreifach abgesichert (unveraendert):
      1. Die Abfrage wird vor der Ausfuehrung geprueft: Sie muss mit SELECT
         oder WITH beginnen und darf kein schreibendes Schluesselwort enthalten.
      2. Alles laeuft in einer Transaktion, die IMMER zurueckgerollt wird.
      3. Isolationsstufe ReadUncommitted: keine Sperren, niemand wird blockiert.

    Bei einem Fehler bleibt die bisherige CSV unveraendert stehen.

    Aufruf (PowerShell "als Administrator" auf dem Server, im Skriptordner):
      .\SupportBoard-Export-Server.ps1 -SetPassword   (nur bei $WindowsAuth = $false)
      .\SupportBoard-Export-Server.ps1 -Preview       (Testlauf, schreibt keine Datei)
      .\SupportBoard-Export-Server.ps1 -Install       (Aufgabe anlegen + Probelauf)
      .\SupportBoard-Export-Server.ps1 -Status        (Aufgabe, CSV-Alter, letzte Logzeilen)
      .\SupportBoard-Export-Server.ps1 -Jetzt         (Ad-hoc-Lauf von Hand)
      .\SupportBoard-Export-Server.ps1 -Uninstall     (Aufgabe entfernen)
      .\SupportBoard-Export-Server.ps1 -ErsatzEinrichten (Ordner + Freigabe fuer den Ersatzpfad)
#>

[CmdletBinding()]
param(
    [switch]$Preview,
    [switch]$SetPassword,
    [switch]$Jetzt,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Status,
    [switch]$ErsatzEinrichten
)

$ErrorActionPreference = 'Stop'
$SkriptPfad = $MyInvocation.MyCommand.Path
if (-not $SkriptPfad) { $SkriptPfad = $PSCommandPath }
if (-not $SkriptPfad) { throw 'Das Skript muss als Datei gestartet werden (z. B. .\SupportBoard-Export-Server.ps1), nicht als eingefuegter Text.' }
$Basis      = Split-Path -Parent $SkriptPfad

# ============================ EINSTELLUNGEN =================================
# Nur die zwei Werte mit EINTRAGEN ausfuellen - alles andere passt fuer den Betrieb
# auf dem Server (Aufgabe als SYSTEM, SQL-Anmeldung, CSV im Ordner dieses Skripts).

$Server        = '<SERVER>'                    # EINTRAGEN: Data Source (wie im Excel-Verbindungsstring)
$Datenbank     = 'MPDV-Reporting'              # Initial Catalog
$WindowsAuth   = $false                        # $false = SQL-Anmeldung mit $Benutzer + hinterlegtem Passwort (SupportBoard-Export.pwd, -SetPassword)
                                               # $true  = Windows-Anmeldung des Kontos, unter dem die Aufgabe laeuft
$Benutzer      = '<SQL-BENUTZER>'              # EINTRAGEN: User ID (wie im Excel-Verbindungsstring)

# Ziel: SupportBoard-Daten.csv im selben Ordner wie dieses Skript. Von dort liest das
# Board (ueber die Freigabe des Servers). Ein zweites Ziel gibt es nicht.
$Zielpfad      = Join-Path $Basis 'SupportBoard-Daten.csv'

# Ersatzpfad: wird nicht gebraucht, weil das Ziel schon auf dem Server liegt. '' = aus.
$ZielpfadErsatz   = ''
$ErsatzFreigabe   = 'SupportBoard'                 # nur fuer -ErsatzEinrichten
$ErsatzLesegruppe = 'DOMAENE\Domänen-Benutzer'    # nur fuer -ErsatzEinrichten

# Konto, unter dem die Aufgabe laeuft: '' = SYSTEM (so ist die Aufgabe eingerichtet).
# Alternativ 'DOMAENE\svc-konto' (Dienstkonto, Passwort bei -Install) oder 'DOMAENE\gmsa-konto$' (gMSA).
$Dienstkonto   = ''

$IntervallMin  = 10                            # Abstand der Laeufe in Minuten
$AufgabenName  = 'Supportboard Datenexport (Server)'

# --- Pruefung der Einstellungen: fehlt etwas, sagt die Meldung was ----------
foreach ($n in 'Server','Datenbank','Zielpfad') {
    $v = Get-Variable -Name $n -ValueOnly -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($v)) { throw "Einstellung `$$n ist leer oder fehlt. Bitte im Block EINSTELLUNGEN eintragen (die Zeile muss genau `$$n = '...' lauten)." }
}
foreach ($n in 'Server','Benutzer') {
    $v = [string](Get-Variable -Name $n -ValueOnly -ErrorAction SilentlyContinue)
    if ($v.Trim().StartsWith('<')) { throw "Einstellung `$$n ist noch der Platzhalter '$v'. Bitte im Block EINSTELLUNGEN den echten Wert eintragen." }
}
if (-not $WindowsAuth -and [string]::IsNullOrWhiteSpace($Benutzer)) { throw 'Einstellung $Benutzer ist leer, wird aber bei $WindowsAuth = $false gebraucht.' }
if (-not (Split-Path -Parent $Zielpfad)) { throw "Einstellung `$Zielpfad muss ein vollstaendiger Pfad mit Ordner und Dateiname sein, z. B. C:\SupportBoard-Daten\SupportBoard-Daten.csv (aktuell: '$Zielpfad')." }
if ($ZielpfadErsatz -and -not (Split-Path -Parent $ZielpfadErsatz)) { throw "Einstellung `$ZielpfadErsatz muss ein vollstaendiger Pfad mit Ordner und Dateiname sein (aktuell: '$ZielpfadErsatz')." }
if ($null -eq $ZielpfadErsatz) { $ZielpfadErsatz = '' }
if ($null -eq $Dienstkonto)    { $Dienstkonto = '' }

$AbfrageDatei  = Join-Path $Basis 'SupportBoard-Abfrage.sql'
$AbfrageDateiReaktion = Join-Path $Basis 'SupportBoard-Abfrage-Reaktion.sql'   # optional: externe Reaktion je Call (2 Spalten: Call, Wert)
$AbfrageDateiWeiterleitung = Join-Path $Basis 'SupportBoard-Abfrage-Weiterleitung.sql'   # optional (v1.43): Weiterleitungs-Historie je Call (2 Spalten: Call, Weiterleitungen)
$PasswortDatei = Join-Path $Basis 'SupportBoard-Export.pwd'   # verschluesselt, an diesen Rechner gebunden
$LogDatei      = Join-Path (Split-Path -Parent $Zielpfad) 'SupportBoard-Export.log'   # im Zielordner: vom Arbeitsplatz aus lesbar
$LogDateiErsatz = if ($ZielpfadErsatz) { Join-Path (Split-Path -Parent $ZielpfadErsatz) 'SupportBoard-Export.log' } else { Join-Path $Basis 'SupportBoard-Export.log' }
$TimeoutSek    = 300
# Laeuft irgendwo noch die Arbeitsplatz-Aufgabe, schreibt nur einer: Ist die Datei
# juenger als dieser Wert in Minuten, beendet sich das Skript sofort. 0 = aus.
$NurWennAelterAlsMin = 5
$EreignisQuelle = 'SupportBoard-Export'       # Windows-Ereignisprotokoll (Anwendung), nur Fehler
# ============================================================================

function Schreibe-Log([string]$Text, [string]$Stufe = 'INFO') {
    $Zeile = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Stufe, $Text
    Write-Host $Zeile
    foreach ($lp in @($LogDatei, $LogDateiErsatz) | Select-Object -Unique) {
        try {
            $lo = Split-Path -Parent $lp
            if (-not (Test-Path $lo)) { continue }
            Add-Content -Path $lp -Value $Zeile -Encoding UTF8
            $z = @(Get-Content -Path $lp -ErrorAction SilentlyContinue)
            if ($z.Count -gt 500) { Set-Content -Path $lp -Value ($z[-500..-1]) -Encoding UTF8 }
        } catch { }
    }
    if ($Stufe -eq 'FEHLER') {
        try { Write-EventLog -LogName Application -Source $EreignisQuelle -EntryType Error -EventId 1 -Message $Text } catch { }
    }
}

function Ist-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- Passwort: an den Rechner gebunden (DPAPI LocalMachine) ---------------
# Jeder Prozess auf DIESEM Server kann es lesen - deshalb wird die Datei per
# Zugriffsrechten auf Administratoren, SYSTEM und das Dienstkonto beschraenkt.
Add-Type -AssemblyName System.Security

function Schuetze-Passwortdatei {
    try {
        $acl = Get-Acl -Path $PasswortDatei
        $acl.SetAccessRuleProtection($true, $false)   # Vererbung aus, geerbte Rechte verwerfen
        foreach ($r in @($acl.Access)) { $null = $acl.RemoveAccessRule($r) }
        $lesen = [System.Security.AccessControl.FileSystemRights]::Read
        $voll  = [System.Security.AccessControl.FileSystemRights]::FullControl
        $ok    = [System.Security.AccessControl.AccessControlType]::Allow
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule('BUILTIN\Administrators', $voll, $ok)))
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule('NT AUTHORITY\SYSTEM', $voll, $ok)))
        if ($Dienstkonto) { $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($Dienstkonto, $lesen, $ok))) }
        Set-Acl -Path $PasswortDatei -AclObject $acl
        Write-Host "Zugriff auf die Passwortdatei beschraenkt auf: Administratoren, SYSTEM$(if($Dienstkonto){", $Dienstkonto"})."
    } catch {
        Write-Warning "Zugriffsrechte der Passwortdatei konnten nicht gesetzt werden: $($_.Exception.Message)"
        Write-Warning "Bitte von Hand pruefen, dass nur Administratoren, SYSTEM und das Dienstkonto die Datei lesen koennen."
    }
}

if ($SetPassword) {
    if ($WindowsAuth) { Write-Host "Windows-Anmeldung ist aktiv (`$WindowsAuth = `$true) - ein Passwort wird nicht benoetigt."; return }
    $sec   = Read-Host -Prompt "Passwort fuer '$Benutzer'" -AsSecureString
    $klar  = (New-Object System.Management.Automation.PSCredential('x', $sec)).GetNetworkCredential().Password
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($klar)
    $prot  = [System.Security.Cryptography.ProtectedData]::Protect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
    [System.IO.File]::WriteAllText($PasswortDatei, [Convert]::ToBase64String($prot), [System.Text.Encoding]::ASCII)
    $klar = $null; $bytes = $null
    # Rueckprobe sofort, damit ein Fehler hier auffaellt und nicht erst im Nachtlauf
    $probe = [System.Security.Cryptography.ProtectedData]::Unprotect([Convert]::FromBase64String([System.IO.File]::ReadAllText($PasswortDatei).Trim()), $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
    if (-not $probe) { throw 'Passwort konnte nicht zurueckgelesen werden.' }
    Write-Host "Passwort gespeichert und geprueft: $PasswortDatei"
    Write-Host 'Es ist an diesen Server gebunden und laesst sich auf keinem anderen Rechner lesen.'
    Schuetze-Passwortdatei
    return
}

function Lies-Passwort {
    if (-not (Test-Path $PasswortDatei)) {
        throw "Kein Passwort hinterlegt. Bitte einmalig als Administrator ausfuehren:  .\SupportBoard-Export-Server.ps1 -SetPassword"
    }
    $txt = ([System.IO.File]::ReadAllText($PasswortDatei)).Trim()
    try {
        $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect([Convert]::FromBase64String($txt), $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    } catch {
        throw "Die Passwortdatei laesst sich auf diesem Server nicht lesen (an den Rechner gebunden, oder mit der Arbeitsplatz-Fassung erzeugt). Bitte die Datei loeschen und einmalig ausfuehren:  .\SupportBoard-Export-Server.ps1 -SetPassword"
    }
}

# --- Ersatzpfad: Ordner, Rechte und Freigabe auf dem Server -----------------
if ($ErsatzEinrichten) {
    if (-not (Ist-Administrator)) { throw 'Bitte PowerShell "als Administrator" starten.' }
    # Freigegeben wird der lokale Ordner: der Ersatzpfad - oder das Hauptziel, wenn die CSV direkt auf dem Server liegt
    $ep = if ($ZielpfadErsatz) { $ZielpfadErsatz } else { $Zielpfad }
    if ($ep -like '\\*') { throw "Der freizugebende Pfad muss auf diesem Server liegen (z. B. C:\SupportBoard-Daten\...), nicht auf einem Netzlaufwerk: $ep" }
    $o = Split-Path -Parent $ep
    if (-not (Test-Path $o)) { New-Item -ItemType Directory -Path $o | Out-Null; Write-Host "Ordner angelegt: $o" }
    # NTFS-Rechte: Lesegruppe liest, Dienstkonto schreibt (Aendern), Administratoren und SYSTEM voll
    try {
        $acl = Get-Acl -Path $o
        $ok  = [System.Security.AccessControl.AccessControlType]::Allow
        $erb = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
        $pro = [System.Security.AccessControl.PropagationFlags]::None
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($ErsatzLesegruppe, 'ReadAndExecute', $erb, $pro, $ok)))
        if ($Dienstkonto) { $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($Dienstkonto, 'Modify', $erb, $pro, $ok))) }
        Set-Acl -Path $o -AclObject $acl
        Write-Host "Ordnerrechte gesetzt: '$ErsatzLesegruppe' liest$(if($Dienstkonto){", '$Dienstkonto' schreibt"})."
    } catch { Write-Warning "Ordnerrechte konnten nicht gesetzt werden: $($_.Exception.Message)" }
    # Freigabe: nur Lesen fuer die Gruppe. Das Skript schreibt lokal, nicht ueber die Freigabe.
    $sh = Get-SmbShare -Name $ErsatzFreigabe -ErrorAction SilentlyContinue
    if ($sh) {
        if ($sh.Path -ne $o) { throw "Eine Freigabe '$ErsatzFreigabe' zeigt bereits auf '$($sh.Path)'. Bitte anderen Freigabenamen waehlen." }
        Write-Host "Freigabe '$ErsatzFreigabe' besteht bereits."
    } else {
        New-SmbShare -Name $ErsatzFreigabe -Path $o -ReadAccess $ErsatzLesegruppe -Description 'Supportmanagement-Board: CSV-Ersatzpfad (nur lesen)' | Out-Null
        Write-Host "Freigabe angelegt: \\$env:COMPUTERNAME\$ErsatzFreigabe  ->  $o"
    }
    Write-Host ''
    Write-Host "Pfad fuer das Board (Verwaltung -> Dashboard ueberwachen): \\$env:COMPUTERNAME\$ErsatzFreigabe\$(Split-Path -Leaf $ep)" -ForegroundColor Cyan
    Write-Host "Log ueber die Freigabe: \\$env:COMPUTERNAME\$ErsatzFreigabe\SupportBoard-Export.log"
    return
}

# --- Aufgabenplanung: anlegen / entfernen / Status --------------------------
if ($Install) {
    if (-not (Ist-Administrator)) { throw 'Bitte PowerShell "als Administrator" starten - die Aufgabe laeuft unabhaengig von der Anmeldung und braucht dafuer Administratorrechte beim Anlegen.' }
    if (-not (Test-Path $AbfrageDatei)) { throw "Abfragedatei nicht gefunden: $AbfrageDatei" }
    if (-not $WindowsAuth -and -not (Test-Path $PasswortDatei)) { throw "Zuerst das Passwort hinterlegen:  .\SupportBoard-Export-Server.ps1 -SetPassword" }
    $Zielordner = Split-Path -Parent $Zielpfad
    if (-not (Test-Path $Zielordner)) {
        if ($ZielpfadErsatz -and (Test-Path (Split-Path -Parent $ZielpfadErsatz))) {
            Write-Warning "Teamshare-Ordner nicht erreichbar: $Zielordner (als $env:USERNAME). Die CSV landet vorerst nur im Ersatzpfad '$ZielpfadErsatz'."
        } else {
            throw "Zielordner nicht erreichbar: $Zielordner (vom Server aus als $env:USERNAME). Pfad pruefen, Share freigeben - oder Ersatzpfad mit -ErsatzEinrichten anlegen."
        }
    }

    # Ereignisquelle fuer Fehlermeldungen im Windows-Ereignisprotokoll (einmalig, braucht Adminrechte)
    try { if (-not [System.Diagnostics.EventLog]::SourceExists($EreignisQuelle)) { New-EventLog -LogName Application -Source $EreignisQuelle } } catch { }

    # Kein Fenster: Unter Dienstkonto/SYSTEM laeuft die Aufgabe ohnehin in einer unsichtbaren
    # Sitzung; -WindowStyle Hidden sichert das zusaetzlich ab, falls jemand die Aufgabe
    # spaeter auf "nur bei Anmeldung" umstellt.
    $aktion   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $SkriptPfad) -WorkingDirectory $Basis
    $trigger  = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes $IntervallMin) -RepetitionDuration (New-TimeSpan -Days 3650)
    $optionen = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15) `
                    -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 2) `
                    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $beschreibung = 'Liest die Support-Calls aus der Datenbank (nur lesend) und schreibt SupportBoard-Daten.csv fuer das Supportmanagement-Board.'

    if (-not $Dienstkonto) {
        $principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Limited
        Register-ScheduledTask -TaskName $AufgabenName -Action $aktion -Trigger $trigger -Settings $optionen -Principal $principal -Description $beschreibung -Force | Out-Null
        Write-Host "Aufgabe '$AufgabenName' angelegt: laeuft als SYSTEM, alle $IntervallMin Minuten."
        Write-Host "Hinweis: Auf Share und Datenbank greift SYSTEM als Computerkonto '$env:USERDOMAIN\$env:COMPUTERNAME`$' zu - dieses braucht die Rechte."
    } elseif ($Dienstkonto.EndsWith('$')) {
        $principal = New-ScheduledTaskPrincipal -UserId $Dienstkonto -LogonType Password -RunLevel Limited
        Register-ScheduledTask -TaskName $AufgabenName -Action $aktion -Trigger $trigger -Settings $optionen -Principal $principal -Description $beschreibung -Force | Out-Null
        Write-Host "Aufgabe '$AufgabenName' angelegt: laeuft als gMSA '$Dienstkonto', alle $IntervallMin Minuten."
    } else {
        $sec = Read-Host -Prompt "Passwort des Dienstkontos '$Dienstkonto' (wird nur an die Aufgabenplanung uebergeben, nicht gespeichert)" -AsSecureString
        $pw  = (New-Object System.Management.Automation.PSCredential('x', $sec)).GetNetworkCredential().Password
        Register-ScheduledTask -TaskName $AufgabenName -Action $aktion -Trigger $trigger -Settings $optionen -Description $beschreibung -User $Dienstkonto -Password $pw -RunLevel Limited -Force | Out-Null
        $pw = $null
        Write-Host "Aufgabe '$AufgabenName' angelegt: laeuft als '$Dienstkonto' (auch ohne Anmeldung), alle $IntervallMin Minuten."
        Write-Host "Hinweis: Das Dienstkonto braucht das Recht 'Anmelden als Stapelverarbeitungsauftrag' - die Aufgabenplanung vergibt es beim Anlegen normalerweise selbst."
    }
    if (-not $WindowsAuth -and $Dienstkonto) { Schuetze-Passwortdatei }

    # Probelauf unter dem Aufgabenkonto: zeigt sofort, ob Share und Datenbank erreichbar sind
    Write-Host ''
    Write-Host 'Probelauf der Aufgabe (unter dem Aufgabenkonto) ...' -ForegroundColor Cyan
    Start-ScheduledTask -TaskName $AufgabenName
    $warte = 0
    do { Start-Sleep -Seconds 3; $warte += 3; $info = Get-ScheduledTaskInfo -TaskName $AufgabenName; $t = Get-ScheduledTask -TaskName $AufgabenName } while ($t.State -eq 'Running' -and $warte -lt 300)
    Write-Host ("Ergebnis der Aufgabenplanung: {0} (0 = ohne Fehler)" -f $info.LastTaskResult)
    $lg = if (Test-Path $LogDatei) { $LogDatei } elseif (Test-Path $LogDateiErsatz) { $LogDateiErsatz } else { $null }
    if ($lg) { Write-Host "Letzte Logzeilen ($lg):" -ForegroundColor Cyan; Get-Content $lg -Tail 5 | ForEach-Object { Write-Host "  $_" } }
    else { Write-Warning "Kein Log gefunden - das Aufgabenkonto kommt vermutlich weder an den Teamshare noch an den Ersatzordner. Rechte des Kontos pruefen." }
    foreach ($zp in @($Zielpfad, $ZielpfadErsatz)) { if ($zp -and (Test-Path $zp)) { Write-Host ("CSV: {0}, Stand {1:dd.MM.yyyy HH:mm}" -f $zp, (Get-Item $zp).LastWriteTime) } }
    Write-Host ''
    Write-Host 'Fertig. Danach die Arbeitsplatz-Aufgabe(n) deaktivieren, damit nur noch der Server schreibt.'
    return
}

if ($Uninstall) {
    if (-not (Ist-Administrator)) { throw 'Bitte PowerShell "als Administrator" starten.' }
    if (Get-ScheduledTask -TaskName $AufgabenName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $AufgabenName -Confirm:$false
        Write-Host "Aufgabe '$AufgabenName' entfernt. CSV, Log und Passwortdatei bleiben liegen."
    } else { Write-Host "Aufgabe '$AufgabenName' ist nicht vorhanden." }
    return
}

if ($Status) {
    $t = Get-ScheduledTask -TaskName $AufgabenName -ErrorAction SilentlyContinue
    if ($t) {
        $info = Get-ScheduledTaskInfo -TaskName $AufgabenName
        Write-Host ("Aufgabe '{0}': {1}, Konto {2}" -f $AufgabenName, $t.State, $t.Principal.UserId)
        Write-Host ("  letzter Lauf {0:dd.MM.yyyy HH:mm}, Ergebnis {1} (0 = ohne Fehler), naechster Lauf {2:dd.MM.yyyy HH:mm}" -f $info.LastRunTime, $info.LastTaskResult, $info.NextRunTime)
    } else { Write-Host "Aufgabe '$AufgabenName' ist nicht eingerichtet (-Install)." }
    foreach ($zp in @($Zielpfad, $ZielpfadErsatz)) {
        if (-not $zp) { continue }
        $art = if ($zp -ne $Zielpfad) { 'Ersatzpfad' } elseif ($zp -like '\\*') { 'Teamshare' } else { 'Server' }
        if (Test-Path $zp) {
            $d = Get-Item $zp
            $alt = ((Get-Date) - $d.LastWriteTime).TotalMinutes
            $zeilen = (Get-Content $zp | Measure-Object -Line).Lines - 1
            Write-Host ("CSV ({0}): {1}`n  Stand {2:dd.MM.yyyy HH:mm} ({3:N0} Minuten alt), {4} Zeilen" -f $art, $zp, $d.LastWriteTime, $alt, $zeilen)
            if ($alt -gt (3 * $IntervallMin)) { Write-Warning "Die CSV ($art) ist deutlich aelter als das Intervall - die Aufgabe laeuft nicht oder scheitert dort. Log pruefen." }
        } else { Write-Host "CSV ($art) nicht vorhanden oder nicht erreichbar: $zp" }
    }
    $lg = if (Test-Path $LogDatei) { $LogDatei } elseif (Test-Path $LogDateiErsatz) { $LogDateiErsatz } else { $null }
    if ($lg) { Write-Host "Letzte Logzeilen ($lg):" -ForegroundColor Cyan; Get-Content $lg -Tail 10 | ForEach-Object { Write-Host "  $_" } }
    return
}

# --- Abfrage laden und auf Nur-Lesen pruefen -------------------------------
function Pruefe-NurLesen([string]$SqlText, [string]$Name) {
    # Fuer die Pruefung Kommentare UND Text in Anfuehrungszeichen entfernen.
    # In der Abfrage stehen Taetigkeiten wie 'update delivery' - blosser Text.
    $SqlPruef = [regex]::Replace($SqlText,  '/\*[\s\S]*?\*/', ' ')   # /* ... */
    $SqlPruef = [regex]::Replace($SqlPruef, '--[^\r\n]*',      ' ')   # -- ...
    $SqlPruef = [regex]::Replace($SqlPruef, "'(?:[^']|'')*'",   ' ')   # 'Text'
    $SqlPruef = [regex]::Replace($SqlPruef, '\[[^\]]*\]',      ' ')   # [Spaltenname]

    $Verboten = @('INSERT','UPDATE','DELETE','DROP','ALTER','CREATE','TRUNCATE','MERGE',
                  'GRANT','REVOKE','BACKUP','RESTORE','EXEC','EXECUTE','INTO','SHUTDOWN')
    foreach ($w in $Verboten) {
        if ($SqlPruef -match "(?is)\b$w\b") {
            throw "Sicherheitsstopp: Die $Name enthaelt '$w'. Es sind ausschliesslich lesende Abfragen erlaubt. Es wurde nichts ausgefuehrt."
        }
    }
    if ($SqlPruef.TrimStart() -notmatch '(?is)^\s*(SELECT|WITH)\b') {
        throw "Sicherheitsstopp: Die $Name beginnt nicht mit SELECT oder WITH. Es wurde nichts ausgefuehrt."
    }
}
if (-not (Test-Path $AbfrageDatei)) { throw "Abfragedatei nicht gefunden: $AbfrageDatei" }
$Sql = Get-Content -Path $AbfrageDatei -Raw -Encoding UTF8
Pruefe-NurLesen $Sql 'Abfrage'

# Zusatzabfragen (optional): werden genauso geprueft; Fehler beim Ausfuehren stoppen den Export NICHT.
# Jede liefert zwei Spalten (Call, Wert); der Wert wird ueber die Call-Nummer an die Hauptabfrage angehaengt.
$Zusatz = @()
foreach ($z in @(
        @{ Datei = $AbfrageDateiReaktion;      Name = 'Reaktionsabfrage';      Spalte = 'Externe Reaktion'; Buendeln = $false },
        @{ Datei = $AbfrageDateiWeiterleitung; Name = 'Weiterleitungsabfrage'; Spalte = 'Weiterleitungen';   Buendeln = $true })) {
    if (-not (Test-Path $z.Datei)) { continue }
    $t = Get-Content -Path $z.Datei -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($t)) { continue }
    Pruefe-NurLesen $t $z.Name
    $Zusatz += @{ Sql = $t; Name = $z.Name; Spalte = $z.Spalte; Buendeln = [bool]$z.Buendeln; Werte = @{} }
}

# --- Verbindungszeichenfolge ------------------------------------------------
$b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$b['Data Source']      = $Server
$b['Initial Catalog']  = $Datenbank
$b['Connect Timeout']  = 30
$b['Application Name'] = 'SupportBoard-Export Server (readonly)'
if ($WindowsAuth) {
    $b['Integrated Security'] = $true
} else {
    $b['User ID']  = $Benutzer
    $b['Password'] = Lies-Passwort
}

# --- Hilfsfunktionen fuer die CSV-Ausgabe -----------------------------------
$INV = [System.Globalization.CultureInfo]::InvariantCulture

function Format-Wert($Wert) {
    if ($null -eq $Wert -or $Wert -is [System.DBNull]) { return '' }
    if ($Wert -is [datetime]) { return $Wert.ToString('yyyy-MM-ddTHH:mm:ss', $INV) }
    if ($Wert -is [double] -or $Wert -is [decimal] -or $Wert -is [single]) {
        return ([double]$Wert).ToString('0.####', $INV)   # Dezimalpunkt, sonst liest das Board die Zahl nicht
    }
    if ($Wert -is [bool]) { return $(if ($Wert) { 'Ja' } else { 'Nein' }) }
    return [string]$Wert
}

function Format-CsvFeld([string]$Text) {
    if ($null -eq $Text) { return '' }
    $t = $Text -replace "`r`n", ' ' -replace "`r", ' ' -replace "`n", ' '
    if ($t -match '[;"]') { return '"' + ($t -replace '"', '""') + '"' }
    return $t
}

# --- Schreibt gerade jemand anderes? ----------------------------------------
if (-not $Preview -and -not $Jetzt -and $NurWennAelterAlsMin -gt 0) {
    $AlterMin = [double]::MaxValue
    foreach ($zp in @($Zielpfad, $ZielpfadErsatz)) {
        if ($zp -and (Test-Path $zp)) { $a = ((Get-Date) - (Get-Item $zp).LastWriteTime).TotalMinutes; if ($a -lt $AlterMin) { $AlterMin = $a } }
    }
    if ($AlterMin -lt $NurWennAelterAlsMin) {
        Schreibe-Log ("Uebersprungen: Datei ist erst {0:N0} Minuten alt (Schwelle {1}). Ein anderer Rechner war schneller." -f $AlterMin, $NurWennAelterAlsMin)
        exit 0
    }
}

# --- Datei ersetzen (seit 2026-10-08) -----------------------------------------
# Haelt ein anderes Programm die alte CSV offen (Excel oder Editor auf dem Server, ein
# Kollege ueber die Freigabe), meldet Move-Item -Force nur "Eine Datei kann nicht erstellt
# werden, wenn sie bereits vorhanden ist". Deshalb: File.Replace (ersetzt in einem Zug), bei
# Fehler bis zu 5 Versuche im Abstand von 2 Sekunden, zuletzt Kopieren mit Ueberschreiben;
# klappt nichts davon, nennt die Meldung die echte Ursache.
# [NullString]::Value statt $null: PowerShell macht aus $null bei .NET-Aufrufen sonst "",
# und File.Replace scheitert dann mit "Der Pfad hat ein ungueltiges Format".
function Ersetze-Datei([string]$Neu, [string]$Ziel) {
    if (-not (Test-Path -LiteralPath $Ziel)) { [System.IO.File]::Move($Neu, $Ziel); return }
    $letzter = ''
    for ($v = 1; $v -le 5; $v++) {
        try { [System.IO.File]::Replace($Neu, $Ziel, [NullString]::Value); return }
        catch {
            $letzter = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }
            Start-Sleep -Seconds 2
        }
    }
    try {
        [System.IO.File]::Copy($Neu, $Ziel, $true)
        Remove-Item -LiteralPath $Neu -Force -ErrorAction SilentlyContinue
        Schreibe-Log "Ersetzen in einem Zug nicht moeglich ($($letzter.Trim())) - '$Ziel' wurde ueberschrieben." 'WARNUNG'
    } catch {
        $m = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }
        throw "Datei konnte nicht ersetzt werden: $($m.Trim()) (zuvor: $($letzter.Trim())). Ist die CSV geoeffnet? Excel/Editor schliessen; Zugriffe ueber die Freigabe zeigt Get-SmbOpenFile."
    }
}

# --- Zusatzabfragen: je Call ein Wert (eigene Verbindung, eigene Transaktion, immer Rollback) ---
# Liefert eine Hashtable Call -> Wert; bei einem Fehler eine leere Hashtable (Spalte bleibt leer, WARNUNG im Log).
function Lade-Zusatz($z) {
    $c2 = $null; $t2 = $null
    try {
        $c2 = New-Object System.Data.SqlClient.SqlConnection $b.ConnectionString
        $c2.Open()
        $t2 = $c2.BeginTransaction([System.Data.IsolationLevel]::ReadUncommitted)
        $k2 = $c2.CreateCommand(); $k2.Transaction = $t2; $k2.CommandText = $z.Sql; $k2.CommandTimeout = $TimeoutSek
        $r2 = $k2.ExecuteReader()
        $fc = $r2.FieldCount
        if ($fc -lt 2) { $r2.Close(); throw "Die $($z.Name) muss mindestens zwei Spalten liefern: Call und den Wert." }
        $h = @{}
        if ($fc -eq 2 -or -not $z.Buendeln) {
            # Ein Wert je Call. Wertspalte = die Spalte mit dem erwarteten Namen (z. B. 'Externe Reaktion'),
            # egal an welcher Stelle sie steht; gibt es sie nicht, die zweite Spalte. Weitere Spalten werden ignoriert.
            $wi = 1
            for ($i = 1; $i -lt $fc; $i++) { if ($r2.GetName($i) -ieq $z.Spalte) { $wi = $i; break } }
            if ($r2.GetName($wi) -ine $z.Spalte) { Schreibe-Log "$($z.Name): keine Spalte '$($z.Spalte)' gefunden - es wird die Spalte '$($r2.GetName($wi))' angehaengt." 'WARNUNG' }
            $z.Spalte = $r2.GetName($wi)
            while ($r2.Read()) {
                $k = [string]$r2.GetValue(0)
                if ($k) { $k = $k.Trim(); if (-not $h.ContainsKey($k)) { $h[$k] = $r2.GetValue($wi) } }
            }
            $r2.Close()
            Schreibe-Log "$($z.Name): $($h.Count) Calls mit Wert '$($z.Spalte)' - wird ueber die Call-Nummer angehaengt."
        } else {
            # Rohform (v1.45, nur Weiterleitungsabfrage): je Weiterleitung eine Zeile - Spalte 1 Call, Spalte 2 Datum, danach die weiteren Felder.
            # Wird hier je Call zu EINEM Text gebuendelt: Felder mit |, Weiterleitungen mit " # ", sortiert nach Datum.
            # Ergebnis ist dasselbe wie bei einer Buendelung per STRING_AGG in der Abfrage.
            $roh = @{}; $n = 0
            while ($r2.Read()) {
                $k = [string]$r2.GetValue(0)
                if (-not $k) { continue }
                $k = $k.Trim()
                $teile = New-Object System.Collections.Generic.List[string]
                for ($i = 1; $i -lt $fc; $i++) {
                    $teile.Add(((Format-Wert $r2.GetValue($i)) -replace '\|', '/' -replace '#', ' '))
                }
                $d = $r2.GetValue(1)
                $t = if ($d -is [datetime]) { $d } else { [datetime]::MinValue }
                if (-not $roh.ContainsKey($k)) { $roh[$k] = New-Object System.Collections.Generic.List[object] }
                $roh[$k].Add(@{ t = $t; s = ($teile -join '|') })
                $n++
            }
            $r2.Close()
            foreach ($k in @($roh.Keys)) {
                $h[$k] = @($roh[$k] | Sort-Object -Property @{ Expression = { $_.t } } | ForEach-Object { $_.s }) -join ' # '
            }
            Schreibe-Log "$($z.Name): Rohform mit $fc Spalten, $n Zeilen zu $($h.Count) Calls gebuendelt - Spalte '$($z.Spalte)' wird ueber die Call-Nummer angehaengt."
        }
        return $h
    } catch {
        Schreibe-Log "$($z.Name) uebersprungen: $($_.Exception.Message) Die Spalte '$($z.Spalte)' bleibt in dieser CSV leer." 'WARNUNG'
        return @{}
    } finally {
        if ($t2) { try { $t2.Rollback() } catch { } }
        if ($c2) { try { $c2.Close()  } catch { } }
    }
}

# --- Abfrage ausfuehren -----------------------------------------------------
$conn = $null; $tx = $null; $TempDatei = $null; $Zeilen = 0
try {
    Schreibe-Log "Start - $env:COMPUTERNAME als $env:USERDOMAIN\$env:USERNAME - Server '$Server', Datenbank '$Datenbank'$(if($Preview){' (Testlauf)'})"

    foreach ($z in $Zusatz) { $z.Werte = Lade-Zusatz $z }

    $conn = New-Object System.Data.SqlClient.SqlConnection $b.ConnectionString
    $conn.Open()

    # Absicherung 3: keine Sperren, niemand wird blockiert
    $tx = $conn.BeginTransaction([System.Data.IsolationLevel]::ReadUncommitted)

    $cmd = $conn.CreateCommand()
    $cmd.Transaction    = $tx
    $cmd.CommandText    = $Sql
    $cmd.CommandTimeout = $TimeoutSek
    $reader = $cmd.ExecuteReader()

    $Spalten = @(0..($reader.FieldCount - 1) | ForEach-Object { $reader.GetName($_) })
    # Verknuepfung: Spalte "Call" der Hauptabfrage; jede Zusatzspalte wird angehaengt, sofern die Hauptabfrage sie nicht selbst liefert
    $CallIdx = -1
    for ($i = 0; $i -lt $Spalten.Count; $i++) { if ($Spalten[$i] -ieq 'Call') { $CallIdx = $i } }
    $Anhang = @()
    foreach ($z in $Zusatz) {
        $sp = $z.Spalte
        if ($CallIdx -lt 0) { Schreibe-Log "Die Hauptabfrage hat keine Spalte 'Call' - die Werte der $($z.Name) koennen nicht zugeordnet werden." 'WARNUNG'; continue }
        if ($Spalten | Where-Object { $_ -ieq $sp }) { Schreibe-Log "Die Hauptabfrage liefert die Spalte '$sp' selbst - die $($z.Name) wird nicht angehaengt."; continue }
        $Anhang += $z
    }
    $SpaltenAus = @($Spalten)
    foreach ($z in $Anhang) { $SpaltenAus += $z.Spalte }

    if ($Preview) {
        $Treffer = @{}
        foreach ($z in $Anhang) { $Treffer[$z.Spalte] = 0 }
        while ($reader.Read()) {
            $Zeilen++
            if ($Anhang.Count -gt 0) {
                $k = ([string]$reader.GetValue($CallIdx)).Trim()
                foreach ($z in $Anhang) { if ($z.Werte.ContainsKey($k)) { $Treffer[$z.Spalte]++ } }
            }
        }
        $reader.Close()
        Schreibe-Log "Testlauf erfolgreich: $Zeilen Zeilen, $($SpaltenAus.Count) Spalten. Es wurde keine Datei geschrieben."
        foreach ($z in $Anhang) { Schreibe-Log "$($z.Name): Wert '$($z.Spalte)' fuer $($Treffer[$z.Spalte]) von $Zeilen Zeilen gefunden." }
        Write-Host ''
        Write-Host 'Spalten:' -ForegroundColor Cyan
        $SpaltenAus | ForEach-Object { Write-Host "  - $_" }
    } else {
        # Erst lokal in eine temporaere Datei schreiben, dann je Ziel in einem Zug
        # ersetzen. So sieht das Board nie eine halb geschriebene Datei.
        $TempDatei = Join-Path $env:TEMP ('~SupportBoard-{0}.tmp' -f ([guid]::NewGuid().ToString('N')))

        $enc = New-Object System.Text.UTF8Encoding($true)   # mit BOM - wegen Umlauten
        $sw  = New-Object System.IO.StreamWriter($TempDatei, $false, $enc)
        try {
            $sw.WriteLine((($SpaltenAus | ForEach-Object { Format-CsvFeld $_ }) -join ';'))
            while ($reader.Read()) {
                $felder = New-Object string[] $SpaltenAus.Count
                for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                    $felder[$i] = Format-CsvFeld (Format-Wert $reader.GetValue($i))
                }
                if ($Anhang.Count -gt 0) {
                    $k = ([string]$reader.GetValue($CallIdx)).Trim()
                    $j = $reader.FieldCount
                    foreach ($z in $Anhang) {
                        $felder[$j] = if ($z.Werte.ContainsKey($k)) { Format-CsvFeld (Format-Wert $z.Werte[$k]) } else { '' }
                        $j++
                    }
                }
                $sw.WriteLine(($felder -join ';'))
                $Zeilen++
            }
        } finally { $sw.Dispose() }
        $reader.Close()

        if ($Zeilen -eq 0) {
            throw "Die Abfrage lieferte 0 Zeilen. Die vorhandene Datei wurde nicht ersetzt (Schutz vor leeren Staenden)."
        }

        $ok = 0; $fehler = @()
        foreach ($zp in @($Zielpfad, $ZielpfadErsatz)) {
            if (-not $zp) { continue }
            $art = if ($zp -ne $Zielpfad) { 'Ersatzpfad' } elseif ($zp -like '\\*') { 'Teamshare' } else { 'Server' }
            try {
                $zo = Split-Path -Parent $zp
                if (-not (Test-Path $zo)) { throw "Ordner nicht erreichbar: $zo" }
                $zt = Join-Path $zo ('~SupportBoard-{0}.tmp' -f ([guid]::NewGuid().ToString('N')))
                Copy-Item -Path $TempDatei -Destination $zt -Force
                Ersetze-Datei $zt $zp
                Schreibe-Log "Fertig ($art): $Zeilen Zeilen nach '$zp' geschrieben (von $env:COMPUTERNAME)."
                $ok++
            } catch {
                $fehler += "$art '$zp': $($_.Exception.Message)"
                if ($zt -and (Test-Path $zt)) { Remove-Item $zt -Force -ErrorAction SilentlyContinue }
            }
        }
        foreach ($f in $fehler) { Schreibe-Log "Nicht geschrieben - $f" $(if ($ok -gt 0) { 'WARNUNG' } else { 'FEHLER' }) }
        if ($ok -eq 0) { throw "Kein Ziel erreichbar. $($fehler -join ' | ')" }
        if ($fehler.Count -gt 0 -and $ok -gt 0) { Schreibe-Log 'Das Board kann auf den Ersatzpfad (Freigabe des Servers) umgestellt werden, solange der Teamshare nicht erreichbar ist.' 'WARNUNG' }
    }
}
catch {
    Schreibe-Log $_.Exception.Message 'FEHLER'
    Schreibe-Log 'Die bisherige Datei wurde NICHT veraendert.' 'FEHLER'
    exit 1
}
finally {
    # Absicherung 2: Die Transaktion wird immer zurueckgerollt - nie etwas festgeschrieben.
    if ($tx)   { try { $tx.Rollback() } catch { } }
    if ($conn) { try { $conn.Close()  } catch { } }
    if ($TempDatei -and (Test-Path $TempDatei)) { Remove-Item $TempDatei -Force -ErrorAction SilentlyContinue }
}
