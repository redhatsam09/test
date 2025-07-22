#!/bin/bash
# Git Sitcom Wrapper - Unix format (LF line endings)
# Author: redhatsam09

# Locate directories and files
HOOK_DIR="${HOME}/.git-hooks"
SOUNDS_DIR="${HOOK_DIR}/sounds"

# Find real git executable
real_git=""
for path in "/usr/bin/git" "/usr/local/bin/git" "/bin/git"; do
    if [ -x "$path" ]; then
        real_git="$path"
        break
    fi
done

if [ -z "$real_git" ]; then
    real_git=$(which git | grep -v "$0" | head -1)
fi

# Simple sound player function
play_sound() {
    local sound="$1"
    if [ ! -f "$sound" ]; then
        return 0
    fi
    
    if command -v aplay &>/dev/null; then
        aplay -q "$sound" &>/dev/null & disown
    elif command -v paplay &>/dev/null; then
        paplay "$sound" &>/dev/null & disown
    elif command -v mpg123 &>/dev/null; then
        mpg123 -q "$sound" &>/dev/null & disown
    elif command -v afplay &>/dev/null; then
        afplay "$sound" &>/dev/null & disown
    elif command -v powershell.exe &>/dev/null; then
        powershell.exe -c "(New-Object Media.SoundPlayer '$sound').Play()" &>/dev/null & disown
    fi
}

# No arguments case
if [ $# -eq 0 ]; then
    exec "$real_git"
    exit $?
fi

# Get command
cmd="$1"

# Process command
case "$cmd" in
    "add")
        play_sound "$SOUNDS_DIR/add.mp3"
        ;;
    "commit")
        play_sound "$SOUNDS_DIR/commit.mp3"
        ;;
    "push")
        play_sound "$SOUNDS_DIR/push.mp3"
        ;;
    "pull")
        play_sound "$SOUNDS_DIR/pull.mp3"
        ;;
    "merge")
        play_sound "$SOUNDS_DIR/merge.mp3"
        ;;
    "clone")
        play_sound "$SOUNDS_DIR/clone.mp3"
        ;;
    *)
        # Check for invalid command
        if ! "$real_git" help 2>/dev/null | grep -q "^   $cmd"; then
            play_sound "$SOUNDS_DIR/error.mp3"
        fi
        ;;
esac

# Execute the real git command
exec "$real_git" "$@"