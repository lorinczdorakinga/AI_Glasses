# Server API contract
# These are the endpoints DataProvider calls.
# Adjust your Node.js server to match, or update the URLs in data_provider.dart.

# ── Auth header ──────────────────────────────────────────────────────────────
# All requests include:  Authorization: Bearer <token>

# ── Image upload (called by BleImageService) ─────────────────────────────────
POST /api/images/upload
  multipart/form-data:
    image      = JPEG bytes
    imageIndex = integer (0-9999, matches ESP32 counter)

  Response 200: { "ok": true }
  # Server should:
  #   1. Save the image
  #   2. Run the per-image AI prompt → get { activity, score, reason }
  #   3. Persist the result linked to the user + imageIndex
  #   4. If enough entries accumulated → run batch summary prompt →
  #      persist { summary, focus, consumption, activity, social, explore }

# ── Activities ───────────────────────────────────────────────────────────────
GET /api/glasses/activities
  Response 200:
  {
    "activities": [
      {
        "activity": "reading at desk",   // max 5 words (from per-image AI)
        "score": true,                   // aligned with goal?
        "reason": "User is focused...",  // one sentence
        "timestamp": "2025-05-23T09:14:00Z"
      },
      ...
    ]
  }
  # Return today's entries, newest first.

# ── Daily summary ─────────────────────────────────────────────────────────────
GET /api/glasses/summary
  Response 200:
  {
    "summary": "One sentence describing today's batch",
    "focus":       72,   // 0-100
    "consumption": 40,
    "activity":    65,
    "social":      20,
    "explore":     55
  }
  # Return the latest batch summary for today.
  # If no batch yet, return all zeros and an empty summary string.

# ── Quest ─────────────────────────────────────────────────────────────────────
GET /api/glasses/quest
  Response 200:
  {
    "quest":     "Go outside without your phone for 30 minutes.",
    "completed": false
  }
  # Already used by daily_quest_overlay for the POST /api/auth/quest/complete call.

# ── Battery ──────────────────────────────────────────────────────────────────
GET /api/glasses/battery
  Response 200:
  {
    "battery": 41   // integer 0-100
  }
  # Optional: you can skip this endpoint entirely and instead read the battery
  # directly from BLE (CMD_BAT_UUID notify), which BleImageService already does.
  # DataProvider.batteryPercent is set by BleImageService._handleBattery()
  # without any server call. The GET endpoint is a fallback for when BLE is
  # not connected but the user opens the app.