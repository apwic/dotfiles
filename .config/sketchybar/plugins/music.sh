#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
NAME="music"

# Check Spotify.app first
if osascript -e 'application "Spotify" is running' &>/dev/null; then
  STATE=$(osascript -e 'tell application "Spotify" to player state' 2>/dev/null)
  if [ "$STATE" = "playing" ]; then
    TRACK=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
    ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
    if [ -n "$TRACK" ] && [ -n "$ARTIST" ]; then
      NEW_LABEL="$TRACK — $ARTIST"
      sketchybar --set "$NAME" drawing=on label="$NEW_LABEL"
      exit 0
    fi
  fi
fi

# Nothing is playing
sketchybar --set "$NAME" drawing=off label=""

exit 0
