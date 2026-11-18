"""Refresh public YouTube channel statistics without exposing the API key."""
import json
import os
import pathlib
import urllib.parse
import urllib.request
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
CHANNEL_ID = "UCgKDfPRw_y6-h7n-n7cfYMg"
api_key = os.environ.get("YOUTUBE_API_KEY", "").strip()
if not api_key:
    raise SystemExit("YOUTUBE_API_KEY is missing. Configure it as a GitHub Actions secret.")

url = "https://www.googleapis.com/youtube/v3/channels?" + urllib.parse.urlencode({
    "part": "statistics", "id": CHANNEL_ID, "key": api_key
})
with urllib.request.urlopen(url, timeout=20) as response:
    data = json.load(response)
items = data.get("items") or []
if not items or "statistics" not in items[0]:
    raise SystemExit("YouTube API returned no channel statistics.")
stats = items[0]["statistics"]
payload = {
    "subscriberCount": str(stats["subscriberCount"]),
    "videoCount": str(stats["videoCount"]),
    "viewCount": str(stats["viewCount"]),
    "updatedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
}
(ROOT / "yt-stats.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)
print("YouTube statistics updated.")
