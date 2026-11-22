# Builds yt-videos.json: long-form uploads only (no Shorts, no livestreams), newest first.
# Secret file (outside the site folder, never committed):
#   C:\Users\Vorongo\Desktop\vorongo-youtube-secret.txt
# Run:  powershell -File update-yt-videos.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$secretFile = "C:\Users\Vorongo\Desktop\vorongo-youtube-secret.txt"
$outFile = Join-Path $root "yt-videos.json"
$channelId = "UCgKDfPRw_y6-h7n-n7cfYMg"

if (-not (Test-Path $secretFile)) { throw "Missing secret file." }
$key = (Get-Content -LiteralPath $secretFile -Raw).Trim()
if (-not $key) { throw "Secret file is empty." }

function Invoke-YT([string]$endpoint) {
  $uri = "https://www.googleapis.com/youtube/v3/" + $endpoint + "&key=" + $key
  $tmp = [IO.Path]::GetTempFileName()
  curl.exe -sL -o $tmp $uri
  $raw = Get-Content -LiteralPath $tmp -Raw -Encoding utf8
  Remove-Item -LiteralPath $tmp -Force
  $obj = $raw | ConvertFrom-Json
  if ($obj.error) { throw "YouTube API error (code $($obj.error.code)); details hidden to protect the key." }
  return $obj
}

$ch = Invoke-YT ("channels?part=contentDetails&id=" + $channelId)
$uploads = $ch.items[0].contentDetails.relatedPlaylists.uploads
if (-not $uploads) { throw "No uploads playlist found." }

$items = New-Object System.Collections.Generic.List[object]
$pageToken = ""
do {
  $page = Invoke-YT ("playlistItems?part=contentDetails&maxResults=50&playlistId=" + $uploads + $(if ($pageToken) { "&pageToken=" + $pageToken } else { "" }))
  foreach ($it in $page.items) { $items.Add([pscustomobject]@{ id = $it.contentDetails.videoId }) }
  $pageToken = [string]$page.nextPageToken
} while ($pageToken)

$details = @{}
$ids = @($items | ForEach-Object { $_.id })
for ($i = 0; $i -lt $ids.Count; $i += 50) {
  $end = [Math]::Min($i + 49, $ids.Count - 1)
  $batch = ($ids[$i..$end]) -join ","
  $v = Invoke-YT ("videos?part=snippet,contentDetails,liveStreamingDetails&id=" + $batch)
  foreach ($x in $v.items) { $details[$x.id] = $x }
}

function Get-Seconds([string]$iso) {
  $m = [regex]::Match($iso, 'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?')
  return ([int]("0" + $m.Groups[1].Value) * 3600) + ([int]("0" + $m.Groups[2].Value) * 60) + [int]("0" + $m.Groups[3].Value)
}

$result = New-Object System.Collections.Generic.List[object]
$skippedShort = 0; $skippedLive = 0
foreach ($it in $items) {
  $d = $details[$it.id]
  if (-not $d) { continue }
  if ($d.liveStreamingDetails) { $skippedLive++; continue }
  if ((Get-Seconds $d.contentDetails.duration) -le 60) { $skippedShort++; continue }
  $result.Add([ordered]@{
    id = $it.id
    title = $d.snippet.title
    date = $d.snippet.publishedAt.Substring(0,10)
    url = "https://www.youtube.com/watch?v=" + $it.id
  })
}
$sorted = @($result | Sort-Object -Property date -Descending)
[IO.File]::WriteAllText($outFile, ($sorted | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding $false))
"videos: $($sorted.Count); skipped shorts (<=60s): $skippedShort; skipped livestreams: $skippedLive"