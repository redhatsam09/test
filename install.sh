#!/bin/bash
# Simple installation script for Git Sitcom

# Set up directories
HOOK_DIR="$HOME/.git-hooks"
SOUNDS_DIR="$HOOK_DIR/sounds"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create directories
mkdir -p "$SOUNDS_DIR"

# Copy sound files
if [ -d "$SCRIPT_DIR/sounds" ]; then
    cp -f "$SCRIPT_DIR"/sounds/*.mp3 "$SOUNDS_DIR/" 2>/dev/null
    echo "Sounds copied successfully"
else
    echo "Error: sounds directory not found"
    exit 1
fi

# Create wrapper script
cat > "$HOOK_DIR/git-wrapper" << 'WRAPPER'
#!/bin/bash
# Git sound wrapper

HOOK_DIR="$HOME/.git-hooks"
SOUNDS_DIR="$HOOK_DIR/sounds"

# Find real git
for git_path in "/usr/bin/git" "/bin/git" "/usr/local/bin/git"; do
    if [ -x "$git_path" ]; then
        REAL_GIT="$git_path"
        break
    fi
done

# Play sound function
play_sound() {
    if [ ! -f "$1" ]; then return; fi
    if command -v aplay &>/dev/null; then
        aplay -q "$1" &>/dev/null & disown
    elif command -v paplay &>/dev/null; then
        paplay "$1" &>/dev/null & disown
    elif command -v mpg123 &>/dev/null; then
        mpg123 -q "$1" &>/dev/null & disown
    elif command -v afplay &>/dev/null; then
        afplay "$1" &>/dev/null & disown
    fi
}

# No args case
if [ $# -eq 0 ]; then
    exec $REAL_GIT
    exit
fi

# Get command
cmd="$1"

# Play sound based on command
case "$cmd" in
    "add") play_sound "$SOUNDS_DIR/add.mp3" ;;
    "commit") play_sound "$SOUNDS_DIR/commit.mp3" ;;
    "push") play_sound "$SOUNDS_DIR/push.mp3" ;;
    "pull") play_sound "$SOUNDS_DIR/pull.mp3" ;;
    "merge") play_sound "$SOUNDS_DIR/merge.mp3" ;;
    "clone") play_sound "$SOUNDS_DIR/clone.mp3" ;;
    *) 
        if ! $REAL_GIT help | grep -q "^   $cmd" 2>/dev/null; then
            play_sound "$SOUNDS_DIR/error.mp3"
        fi
        ;;
esac

# Run real git
exec $REAL_GIT "$@"
WRAPPER

chmod +x "$HOOK_DIR/git-wrapper"

# Set up shell alias
if [ -f "$HOME/.bashrc" ]; then
    echo "" >> "$HOME/.bashrc"
    echo "# Git Sitcom" >> "$HOME/.bashrc"
    echo "alias git='$HOOK_DIR/git-wrapper'" >> "$HOME/.bashrc"
    echo "Added git alias to .bashrc"
fi

echo "Installation complete!"
echo "To start using, run: source ~/.bashrc"