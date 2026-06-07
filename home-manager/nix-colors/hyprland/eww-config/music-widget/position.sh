#!/usr/bin/env bash

# File to store the real start time across script restarts
STATE_FILE="/tmp/playerctl_pos_state"

# Helper function to format seconds into M:SS
format_time() {
    local total_seconds=$1
    local min=$((total_seconds / 60))
    local sec=$((total_seconds % 60))
    printf "%d:%02d\n" "$min" "$sec"
}

# Clear any stale states on a fresh script boot
rm -f "$STATE_FILE"

while true; do
    STATUS=$(playerctl status 2>/dev/null)

    # If stopped or no player is open, clear state and output nothing
    if [ -z "$STATUS" ] || [ "$STATUS" == "Stopped" ]; then
        rm -f "$STATE_FILE"
        echo ""
        sleep 1
        continue
    fi

    # Fetch current track metadata and raw position
    TRACK_ID=$(playerctl metadata --format '{{mpris:trackid}}{{title}}' 2>/dev/null)
    POS_RAW=$(playerctl position 2>/dev/null)
    POS_INT=${POS_RAW%.*}
    POS_INT=${POS_INT:-0}
    NOW=$(date +%s)

    # 1. IF PAUSED: playerctl is always 100% accurate.
    # We output it directly and update our baseline so it's ready for the resume.
    if [ "$STATUS" == "Paused" ]; then
        playerctl position -f '{{duration(position)}}' 2>/dev/null
        
        REAL_START=$((NOW - POS_INT))
        echo "START_TIME=$REAL_START" > "$STATE_FILE"
        echo "SAVED_TRACK_ID=\"$TRACK_ID\"" >> "$STATE_FILE"
        
        sleep 1
        continue
    fi

    # 2. IF PLAYING: Check if Spotify's position is bugged out (stuck at 0)
    if [ "$POS_INT" -eq 0 ]; then
        if [ -f "$STATE_FILE" ]; then
            source "$STATE_FILE"
            
            # If we are on the same track, bypass Spotify and rely on our internal clock
            if [ "$SAVED_TRACK_ID" == "$TRACK_ID" ]; then
                ELAPSED=$((NOW - START_TIME))
                format_time "$ELAPSED"
            else
                # Track just changed! Mark this exact second as the true start time.
                echo "START_TIME=$NOW" > "$STATE_FILE"
                echo "SAVED_TRACK_ID=\"$TRACK_ID\"" >> "$STATE_FILE"
                echo "0:00"
            fi
        else
            # Edge case: Script was booted mid-song while Spotify was already glitched.
            # We are forced to start at 0:00, but we will track perfectly from this moment on.
            echo "START_TIME=$NOW" > "$STATE_FILE"
            echo "SAVED_TRACK_ID=\"$TRACK_ID\"" >> "$STATE_FILE"
            echo "0:00"
        fi
    else
        # Spotify is reporting a healthy, true position (> 0).
        # Always trust the live player over script calculations when it's working!
        playerctl position -f '{{duration(position)}}' 2>/dev/null
        
        # Keep our state file perfectly calibrated in the background
        REAL_START=$((NOW - POS_INT))
        echo "START_TIME=$REAL_START" > "$STATE_FILE"
        echo "SAVED_TRACK_ID=\"$TRACK_ID\"" >> "$STATE_FILE"
    fi

    # Poll every 1 second
    sleep 1
done
