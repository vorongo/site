# Updates yt-stats.json via YouTube Data API.
# Secret file (NOT inside the site folder):
#   C:\Users\Vorongo\Desktop\vorongo-youtube-secret.txt
# Do NOT upload that file or this script with the public site.
# Run:  powershell -File update-yt-stats.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$secretFile = Join-Path (Split-Path -Parent $root) "vorongo-youtube-secret.txt"
$outFile = Join-Path $root "yt-stats.json"
$channelId = "UCgKDfPRw_y6-h7n-n7cfYMg"

if (-not (Test-Path $secretFile)) {
  Write-Error "Missing secret file: $secretFile"
}

$key = (Get-Content -LiteralPath $secretFile -Raw).Trim()
if (-not $key) { Write-Error "Secret file is empty." }

$url = "https://www.googleapis.com/youtube/v3/channels?part=statistics&id=$channelId&key=$key"
$raw = curl.exe -sL $url
$json = $raw | ConvertFrom-Json
$stats = $json.items[0].statistics
if (-not $stats) { Write-Error "No statistics in API response. Check key / API enablement.`n$raw" }

$payload = [ordered]@{
  subscriberCount = [string]$stats.subscriberCount
  videoCount      = [string]$stats.videoCount
  viewCount       = [string]$stats.viewCount
  updatedAt       = (Get-Date).ToUniversalTime().ToString("o")
}

($payload | ConvertTo-Json) | Set-Content -LiteralPath $outFile -Encoding UTF8
Write-Host "Updated $outFile"
Write-Host ("Subs: {0}  Videos: {1}" -f $payload.subscriberCount, $payload.videoCount)
