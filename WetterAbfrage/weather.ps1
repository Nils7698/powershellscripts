<#
.SYNOPSIS
    Wetterabfrage Skript

.DESCRIPTION
    Dieses Skript fragt aktuelle Wetterdaten von einer API ab und gibt diese aus.
#>

$location = Read-Host "Bitte Ort eingeben"

# --- API Key laden ---
$keyFile = "$PSScriptRoot\apikey.txt"

if (-not (Test-Path $keyFile)) {
    Write-Error "apikey.txt wurde nicht gefunden. Bitte erstelle die Datei im Skriptordner mit deinem API-Key."
    exit 1
}

try {
    $ApiKey = Get-Content -Path $keyFile -ErrorAction Stop | Select-Object -First 1
}
catch {
    Write-Error "Fehler beim Lesen der apikey.txt: $_"
    exit 1
}

$apiUrl = "https://api.weatherapi.com/v1/current.json?key=$ApiKey&q=$location&aqi=no"

# --- API Anfrage ---
try {
    $response = Invoke-RestMethod -Uri $apiUrl
} catch {
    Write-Error "API Anfrage fehlgeschlagen: $_"
    exit 1
}

# --- API Antwort verarbeiten und ausgeben ---
Write-Host "Ort: $($response.location.name)"
Write-Host "Land: $($response.location.country)"
Write-Host "Temperatur: $($response.current.temp_c) °C"
Write-Host "Gefühlt wie: $($response.current.feelslike_c) °C"
Write-Host "Wetter: $($response.current.condition.text)"
Write-Host "Luftfeuchtigkeit: $($response.current.humidity)%"
Write-Host "Wind: $($response.current.wind_kph) km/h aus $($response.current.wind_dir)"
Write-Host "Letztes Update: $($response.current.last_updated)"
Write-Host "--------------------------------"
Read-Host "Drücke Enter zum Beenden..."