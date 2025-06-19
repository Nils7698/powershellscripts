<#
.SYNOPSIS
    System Monitoring Script

.DESCRIPTION
    Dieses Skript sammelt CPU-, RAM- und Festplattenauslastung und erzeugt daraus
    einen zeitlich verlaufenden HTML-Bericht mit Diagrammen.
#>

# --- Konfiguration ---
$OutputFolder = "$PSScriptRoot\report"
$HtmlTemplate = "$PSScriptRoot\template.html"
$OutputFile   = "$OutputFolder\SystemReport.html"
$DataFile     = "$OutputFolder\data.csv"

# --- Ordner vorbereiten ---
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# --- Daten erfassen ---
try {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # CPU: Fallback ohne Get-Counter
    $cpuObj = Get-CimInstance Win32_Processor
    $cpu = ($cpuObj | Measure-Object -Property LoadPercentage -Average).Average
    $cpu = [math]::Round($cpu, 2)

    # RAM
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1024, 2) # in MB
    $freeMem  = [math]::Round($os.FreePhysicalMemory / 1024, 2)
    $usedMem  = $totalMem - $freeMem
    $memPct   = [math]::Round(($usedMem / $totalMem) * 100, 2)

    # Festplatte C:
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $totalDisk = [math]::Round($disk.Size / 1GB, 2)
    $freeDisk  = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedDiskPct = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
}
catch {
    Write-Error "Fehler beim Erfassen der Systemdaten: $_"
    exit 1
}

# --- CSV-Datei initialisieren/erweitern ---
if (-not (Test-Path $DataFile)) {
    "Timestamp,CPU,MemoryPct,DiskPct" | Out-File -Encoding UTF8 -FilePath $DataFile
}
"$timestamp,$cpu,$memPct,$usedDiskPct" | Out-File -Encoding UTF8 -Append -FilePath $DataFile

# --- CSV-Daten vorbereiten für Chart.js ---
try {
    $csv = Import-Csv $DataFile
    $labels = ($csv | ForEach-Object { "'$($_.Timestamp)'" }) -join ","
    $cpuData = ($csv | ForEach-Object { $_.CPU }) -join ","
    $memData = ($csv | ForEach-Object { $_.MemoryPct }) -join ","
    $diskData = ($csv | ForEach-Object { $_.DiskPct }) -join ","
}
catch {
    Write-Error "Fehler beim Verarbeiten der CSV-Daten: $_"
    exit 1
}

# --- HTML generieren ---
try {
    $html = Get-Content $HtmlTemplate -Raw
    $html = $html -replace "{{LABELS}}", $labels
    $html = $html -replace "{{CPU_DATA}}", $cpuData
    $html = $html -replace "{{MEM_DATA}}", $memData
    $html = $html -replace "{{DISK_DATA}}", $diskData

    $html | Out-File -Encoding UTF8 -FilePath $OutputFile
}
catch {
    Write-Error "Fehler beim Generieren des HTML-Berichts: $_"
    exit 1
}