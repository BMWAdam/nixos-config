#!/usr/bin/env python3
import sys
import time
import threading
import unicodedata

width    = 22
delay    = 0.3
seed_pos = 0.0

if len(sys.argv) > 1:
    try:
        width = int(sys.argv[1])
    except ValueError:
        pass

if len(sys.argv) > 2:
    try:
        delay = float(sys.argv[2])
    except ValueError:
        pass

if len(sys.argv) > 3:
    try:
        seed_pos = float(sys.argv[3])
    except ValueError:
        pass

def strip_symbols(text):
    result = []
    for ch in text:
        cp  = ord(ch)
        cat = unicodedata.category(ch)
        is_emoji = (
            0x1F300 <= cp <= 0x1FAFF or
            0x2600 <= cp <= 0x26FF  or
            0x2700 <= cp <= 0x27BF  or
            0xFE00 <= cp <= 0xFE0F
        )
        if is_emoji:
            continue
        if cat.startswith(('L', 'N', 'P', 'Z')):
            result.append(ch)
        elif ch == ' ' or (0x20 <= cp <= 0x7E):
            result.append(ch)
    return ''.join(result).strip()

current_text = "No Music Playing"
pending_text = None
pending_time = 0
lock         = threading.Lock()
DEBOUNCE     = 0.15

def read_input():
    global current_text, pending_text, pending_time
    for line in sys.stdin:
        cleaned = strip_symbols(line.strip()) or "No Music Playing"
        with lock:
            pending_text = cleaned
            pending_time = time.monotonic()

threading.Thread(target=read_input, daemon=True).start()

# Track frames and target wake times sequentially to bypass scheduler jitter
frame_index = int(seed_pos)
target_time = time.monotonic()

while True:
    with lock:
        if pending_text is not None and (time.monotonic() - pending_time) >= DEBOUNCE:
            if pending_text != current_text:
                frame_index = int(seed_pos)  # Resets scroll to the beginning for new tracks
            current_text = pending_text
            pending_text = None

    text = current_text

    if len(text) <= width:
        print(text, flush=True)
        # Keep target time updated while static so it doesn't rush when scrolling resumes
        target_time = time.monotonic() + delay
        time.sleep(delay)
    else:
        scroll_text = text + " \u2022 "
        scroll_len  = len(scroll_text)
        
        i           = frame_index % scroll_len
        end_idx     = i + width

        if end_idx <= scroll_len:
            out = scroll_text[i:end_idx]
        else:
            out = scroll_text[i:] + scroll_text[:end_idx - scroll_len]

        print(out, flush=True)
        
        # Advance frame state linearly
        frame_index += 1
        target_time += delay
        
        # Calculate precision sleep window to reach the exact next frame target
        sleep_for = target_time - time.monotonic()
        if sleep_for > 0:
            time.sleep(sleep_for)
        else:
            # System fell behind (lag spike); reset target to prevent rapid catch-up frames
            target_time = time.monotonic()
            