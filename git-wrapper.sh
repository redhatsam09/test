#!/bin/bash
# Git Sitcom - Wrapper Script for Git Commands
# Plays custom sounds when Git commands are executed

# Directory where hooks and sounds are stored
HOOK_DIR="$HOME/.git-hooks"
SOUNDS_DIR="$HOOK_DIR/sounds"

# Detect OS
OS="unknown"
if [ "$(uname)" == "Darwin" ]; then
    OS="macos"
elif [ "$(uname)" == "Linux" ]; then
    OS="linux"
elif [[ "$(uname)" == *"MINGW"* ]] || [[ "$(uname)" == *"MSYS"* ]] || [[ "$(uname)" == *"CYGWIN"* ]]; then
    OS="windows"
fi

# Find real git executable
find_real_git() {
    # Return first git executable that isn't our wrapper
    for git_path in $(which -a git 2>/dev/null); do
        if [ "$git_path" != "$0" ] && [ "$git_path" != "$HOOK_DIR/git-wrapper" ]; then
            echo "$git_path"
            return 0
        fi
    done
    
    # Try common locations if which fails
    for git_path in "/usr/bin/git" "/usr/local/bin/git" "/bin/git" "/mingw64/bin/git"; do
        if [ -x "$git_path" ]; then
            echo "$git_path"
            return 0
        fi
    done
    
    # Last resort
    echo "git"
}

# Play sound based on OS and available players
play_sound() {
    local sound_file="$1"
    
    # Check if sound file exists
    if [ ! -f "$sound_file" ]; then
        return 1
    fi
    
    # Play sound based on OS and available players
    if [ "$OS" == "linux" ]; then
        if command -v mpg123 &> /dev/null; then
            mpg123 -q "$sound_file" &>/dev/null & disown
        elif command -v paplay &> /dev/null; then
            paplay "$sound_file" &>/dev/null & disown
        elif command -v aplay &> /dev/null; then
            aplay -q "$sound_file" &>/dev/null & disown
        fi
    elif [ "$OS" == "macos" ]; then
        if command -v afplay &> /dev/null; then
            afplay "$sound_file" &>/dev/null & disown
        elif command -v mpg123 &> /dev/null; then
            mpg123 -q "$sound_file" &>/dev/null & disown
        fi
    elif [ "$OS" == "windows" ]; then
        if command -v powershell.exe &> /dev/null; then
            powershell.exe -c "[System.Reflection.Assembly]::LoadWithPartialName('System.Media'); (New-Object System.Media.SoundPlayer '$sound_file').PlaySync();" &>/dev/null & disown
        fi
    fi
    
    return 0
}

# Get the real git executable
REAL_GIT=$(find_real_git)

# Handle no arguments
if [ $# -eq 0 ]; then
    exec "$REAL_GIT"
    exit $?
fi

# Get the git command
cmd="$1"

# Play appropriate sound based on command
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
        # Check if invalid command
        if ! "$REAL_GIT" help 2>/dev/null | grep -q "^   $cmd"; then
            play_sound "$SOUNDS_DIR/error.mp3"
        fi
        ;;
esac

# Execute the real git command
exec "$REAL_GIT" "$@"
