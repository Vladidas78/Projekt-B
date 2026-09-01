<#
    Supportmanagement-Board – Datenexport
    ---------------------------------------------------------------------------
    Fuehrt die Abfrage aus SupportBoard-Abfrage.sql aus und legt das Ergebnis
    als CSV im Team-Verzeichnis ab. Das Board liest diese Datei anschliessend
    genauso wie bisher die Excel-Liste.

    NUR LESEN – dreifach abgesichert:
      1. Die Abfrage wird vor der Ausfuehrung geprueft: Sie muss mit SELECT
         oder WITH beginnen und darf kein schreibendes Schluesselwort enthalten
         (INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, MERGE, EXEC ...).
      2. Alles laeuft in einer Transaktion, die IMMER zurueckgerollt wird.
         Selbst wenn doch etwas schreiben wuerde, bliebe davon nichts uebrig.
      3. Isolationsstufe ReadUncommitted: Es werden keine Sperren gesetzt,
         laufende Arbeit anderer wird nicht blockiert.

    Bei einem Fehler bleibt die bisherige CSV unveraentert stehen, damit das
    Board weiterhin mit dem letzten guten Stand arbeitet.

    Aufruf:
      .\SupportBoard-Export.ps1                 (normaler Lauf)
      .\SupportBoard-Export.ps1 -Jetzt          (Ad-hoc-Lauf: ueberspringt die
                                                 "Datei ist noch frisch"-Pruefung)
      .\SupportBoard-Export.ps1 -Preview        (Testlauf, schreibt keine Datei)
      .\SupportBoard-Export.ps1 -SetPassword    (Passwort einmalig hinterlegen)

    Tipp fuer "Jetzt synchronisieren": eine Verknuepfung auf dem Desktop mit
      powershell.exe -ExecutionPolicy Bypass -File "PFAD\SupportBoard-Export.ps1" -Jetzt
    anlegen. Danach im Board unten links "Jetzt synchronisieren" klicken –
    das Board liest die frische CSV sofort ein.
#>

[CmdletBinding()]
param(
    [switch]$Preview,
    [switch]$SetPassword,
    [switch]$Jetzt
)

$ErrorActionPreference = 'Stop'
$Basis = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================ EINSTELLUNGEN =================================
# Hier eintragen – sonst muss nichts angepasst werden.

$Server        = 'BeispielServer-01'          # Data Source
$Datenbank     = 'MPDV-Reporting'             # Initial Catalog
$WindowsAuth   = $false                        # $true = eigenes Windows-Konto nutzen,
                                               # $false = Benutzername/Passwort unten
$Benutzer      = 'Beispiel-readonly'          # nur bei $WindowsAuth = $false
$Zielpfad      = '\\Server\Freigabe\Supportmanagement\SupportBoard-Daten.csv'
$AbfrageDatei  = Join-Path $Basis 'SupportBoard-Abfrage.sql'
$PasswortDatei = Join-Path $Basis 'SupportBoard-Export.pwd'   # verschluesselt, s. -SetPassword
$LogDatei      = Join-Path $Basis 'SupportBoard-Export.log'
$TimeoutSek    = 300
# Mehrere Kollegen koennen dieselbe Aufgabe einrichten (Ausfallsicherheit, wenn
# jemand nicht da ist). Ist die Zieldatei juenger als dieser Wert in Minuten,
# beendet sich das Skript sofort - die Datenbank wird dann gar nicht erst gefragt.
# 0 = Pruefung aus (immer abfragen).
$NurWennAelterAlsMin = 12
# ============================================================================

function Schreibe-Log([string]$Text, [string]$Stufe = 'INFO') {
    $Zeile = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Stufe, $Text
    Write-Host $Zeile
    try {
        Add-Content -Path $LogDatei -Value $Zeile -Encoding UTF8
        # Log kurz halten: nur die letzten 500 Zeilen behalten
        $z = @(Get-Content -Path $LogDatei -ErrorAction SilentlyContinue)
        if ($z.Count -gt 500) { Set-Content -Path $LogDatei -Value ($z[-500..-1]) -Encoding UTF8 }
    } catch { }
}

# --- Passwort einmalig hinterlegen (verschluesselt, nur fuer dieses Windows-Konto lesbar)
if ($SetPassword) {
    $sec = Read-Host -Prompt "Passwort fuer '$Benutzer'" -AsSecureString
    $sec | ConvertFrom-SecureString | Set-Content -Path $PasswortDatei -Encoding UTF8
    Write-Host "Passwort gespeichert in: $PasswortDatei"
    Write-Host "Die Datei ist verschluesselt und laesst sich nur mit diesem Windows-Konto auf diesem PC lesen."
    return
}

# --- Abfrage laden und auf Nur-Lesen pruefen -------------------------------
if (-not (Test-Path $AbfrageDatei)) { throw "Abfragedatei nicht gefunden: $AbfrageDatei" }
$Sql = Get-Content -Path $AbfrageDatei -Raw -Encoding UTF8

# Fuer die Pruefung Kommentare UND Text in Anfuehrungszeichen entfernen.
# Wichtig: In der Abfrage stehen Taetigkeiten wie 'update delivery' – das ist
# blosser Text und darf nicht als Schreibbefehl missverstanden werden.
$SqlPruef = [regex]::Replace($Sql,      '/\*[\s\S]*?\*/', ' ')   # /* ... */
$SqlPruef = [regex]::Replace($SqlPruef, '--[^\r\n]*',      ' ')   # -- ...
$SqlPruef = [regex]::Replace($SqlPruef, "'(?:[^']|'')*'",   ' ')   # 'Text'
$SqlPruef = [regex]::Replace($SqlPruef, '\[[^\]]*\]',      ' ')   # [Spaltenname]

$Verboten = @('INSERT','UPDATE','DELETE','DROP','ALTER','CREATE','TRUNCATE','MERGE',
              'GRANT','REVOKE','BACKUP','RESTORE','EXEC','EXECUTE','INTO','SHUTDOWN')
foreach ($w in $Verboten) {
    if ($SqlPruef -match "(?is)\b$w\b") {
        throw "Sicherheitsstopp: Die Abfrage enthaelt '$w'. Es sind ausschliesslich lesende Abfragen erlaubt. Es wurde nichts ausgefuehrt."
    }
}
if ($SqlPruef.TrimStart() -notmatch '(?is)^\s*(SELECT|WITH)\b') {
    throw "Sicherheitsstopp: Die Abfrage beginnt nicht mit SELECT oder WITH. Es wurde nichts ausgefuehrt."
}

# --- Verbindungszeichenfolge ------------------------------------------------
$b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$b['Data Source']     = $Server
$b['Initial Catalog'] = $Datenbank
$b['Connect Timeout'] = 30
$b['Application Name'] = 'SupportBoard-Export (readonly)'
if ($WindowsAuth) {
    $b['Integrated Security'] = $true
} else {
    if (-not (Test-Path $PasswortDatei)) {
        throw "Kein Passwort hinterlegt. Bitte einmalig ausfuehren:  .\SupportBoard-Export.ps1 -SetPassword"
    }
    $sec  = Get-Content -Path $PasswortDatei -Raw | ConvertTo-SecureString
    $cred = New-Object System.Management.Automation.PSCredential ($Benutzer, $sec)
    $b['User ID']  = $Benutzer
    $b['Password'] = $cred.GetNetworkCredential().Password
}

# --- Hilfsfunktionen fuer die CSV-Ausgabe -----------------------------------
$INV = [System.Globalization.CultureInfo]::InvariantCulture

function Format-Wert($Wert) {
    if ($null -eq $Wert -or $Wert -is [System.DBNull]) { return '' }
    if ($Wert -is [datetime]) { return $Wert.ToString('yyyy-MM-ddTHH:mm:ss', $INV) }
    if ($Wert -is [double] -or $Wert -is [decimal] -or $Wert -is [single]) {
        # Dezimaltrennzeichen immer Punkt – sonst liest das Board die Zahl nicht
        return ([double]$Wert).ToString('0.####', $INV)
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

# --- Laeuft schon jemand anderes? -------------------------------------------
# Wenn ein Kollege die Datei gerade aktualisiert hat, ist hier nichts zu tun.
# Mit -Jetzt (Ad-hoc-Lauf per Hand) wird immer abgefragt.
if (-not $Preview -and -not $Jetzt -and $NurWennAelterAlsMin -gt 0 -and (Test-Path $Zielpfad)) {
    $AlterMin = ((Get-Date) - (Get-Item $Zielpfad).LastWriteTime).TotalMinutes
    if ($AlterMin -lt $NurWennAelterAlsMin) {
        Schreibe-Log ("Uebersprungen: Datei ist erst {0:N0} Minuten alt (Schwelle {1}). Ein anderer Rechner war schneller." -f $AlterMin, $NurWennAelterAlsMin)
        exit 0
    }
}

# --- Abfrage ausfuehren -----------------------------------------------------
$conn = $null; $tx = $null; $TempDatei = $null; $Zeilen = 0
try {
    Schreibe-Log "Start – $env:COMPUTERNAME – Server '$Server', Datenbank '$Datenbank'$(if($Preview){' (Testlauf)'})"

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

    if ($Preview) {
        while ($reader.Read()) { $Zeilen++ }
        $reader.Close()
        Schreibe-Log "Testlauf erfolgreich: $Zeilen Zeilen, $($Spalten.Count) Spalten. Es wurde keine Datei geschrieben."
        Write-Host ''
        Write-Host 'Spalten:' -ForegroundColor Cyan
        $Spalten | ForEach-Object { Write-Host "  - $_" }
    } else {
        # Erst in eine temporaere Datei schreiben, dann in einem Zug ersetzen.
        # So sieht das Board nie eine halb geschriebene Datei.
        $Zielordner = Split-Path -Parent $Zielpfad
        if (-not (Test-Path $Zielordner)) { throw "Zielordner nicht erreichbar: $Zielordner" }
        $TempDatei = Join-Path $Zielordner ('~SupportBoard-{0}.tmp' -f ([guid]::NewGuid().ToString('N')))

        $enc = New-Object System.Text.UTF8Encoding($true)   # mit BOM – wegen Umlauten
        $sw  = New-Object System.IO.StreamWriter($TempDatei, $false, $enc)
        try {
            $sw.WriteLine((($Spalten | ForEach-Object { Format-CsvFeld $_ }) -join ';'))
            while ($reader.Read()) {
                $felder = New-Object string[] $reader.FieldCount
                for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                    $felder[$i] = Format-CsvFeld (Format-Wert $reader.GetValue($i))
                }
                $sw.WriteLine(($felder -join ';'))
                $Zeilen++
            }
        } finally { $sw.Dispose() }
        $reader.Close()

        if ($Zeilen -eq 0) {
            throw "Die Abfrage lieferte 0 Zeilen. Die vorhandene Datei wurde nicht ersetzt (Schutz vor leeren Staenden)."
        }

        Move-Item -Path $TempDatei -Destination $Zielpfad -Force
        $TempDatei = $null
        Schreibe-Log "Fertig: $Zeilen Zeilen nach '$Zielpfad' geschrieben (von $env:COMPUTERNAME)."
    }
}
catch {
    Schreibe-Log $_.Exception.Message 'FEHLER'
    Schreibe-Log 'Die bisherige Datei wurde NICHT veraendert.' 'FEHLER'
    exit 1
}
finally {
    # Absicherung 2: Die Transaktion wird immer zurueckgerollt – nie etwas festgeschrieben.
    if ($tx)   { try { $tx.Rollback() } catch { } }
    if ($conn) { try { $conn.Close()  } catch { } }
    if ($TempDatei -and (Test-Path $TempDatei)) { Remove-Item $TempDatei -Force -ErrorAction SilentlyContinue }
}
