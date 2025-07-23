#!/bin/bash
# Git Laugh - Installation Script
# Automatically installs audio players and configures git hooks

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Git Laugh - Installation Script${NC}"
echo -e "${YELLOW}=============================${NC}"

# Directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_DIR="$HOME/.git-hooks"
SOUNDS_DIR="$HOOK_DIR/sounds"

# Create directories
mkdir -p "$SOUNDS_DIR"

# Detect OS
OS="unknown"
if [ "$(uname)" == "Darwin" ]; then
    OS="macos"
elif [ "$(uname)" == "Linux" ]; then
    OS="linux"
elif [[ "$(uname)" == *"MINGW"* ]] || [[ "$(uname)" == *"MSYS"* ]] || [[ "$(uname)" == *"CYGWIN"* ]]; then
    OS="windows"
fi

echo -e "${GREEN}Detected OS: ${OS}${NC}"

# Install audio player if needed
install_audio_player() {
    echo -e "${YELLOW}Checking for audio player...${NC}"
    
    if [ "$OS" == "linux" ]; then
        # Check for package managers
        PKG_MANAGER=""
        if command -v apt-get &> /dev/null; then
            PKG_MANAGER="apt-get"
        elif command -v dnf &> /dev/null; then
            PKG_MANAGER="dnf"
        elif command -v yum &> /dev/null; then
            PKG_MANAGER="yum"
        elif command -v pacman &> /dev/null; then
            PKG_MANAGER="pacman"
        fi
        
        # Install audio player
        if [ -n "$PKG_MANAGER" ]; then
            if ! command -v aplay &> /dev/null && ! command -v paplay &> /dev/null && ! command -v mpg123 &> /dev/null; then
                echo -e "${YELLOW}No audio player found. Installing...${NC}"
                if [ "$PKG_MANAGER" == "apt-get" ]; then
                    sudo apt-get update
                    sudo apt-get install -y mpg123
                elif [ "$PKG_MANAGER" == "dnf" ] || [ "$PKG_MANAGER" == "yum" ]; then
                    sudo $PKG_MANAGER install -y mpg123
                elif [ "$PKG_MANAGER" == "pacman" ]; then
                    sudo pacman -Sy --noconfirm mpg123
                fi
                echo -e "${GREEN}Audio player installed!${NC}"
            else
                echo -e "${GREEN}Audio player already installed.${NC}"
            fi
        else
            echo -e "${YELLOW}No package manager found. Please manually install an audio player.${NC}"
            echo -e "${YELLOW}Try: mpg123, alsa-utils, or pulseaudio-utils${NC}"
        fi
    elif [ "$OS" == "macos" ]; then
        # macOS has afplay built in, but we can offer to install mpg123 as fallback
        if ! command -v brew &> /dev/null; then
            echo -e "${YELLOW}Homebrew not found. Using built-in afplay.${NC}"
        elif ! command -v mpg123 &> /dev/null; then
            echo -e "${YELLOW}Installing mpg123 as fallback player...${NC}"
            brew install mpg123
            echo -e "${GREEN}mpg123 installed!${NC}"
        else
            echo -e "${GREEN}Audio player already installed.${NC}"
        fi
    elif [ "$OS" == "windows" ]; then
        # Windows uses PowerShell's System.Media.SoundPlayer
        echo -e "${GREEN}Windows will use PowerShell's audio playback capabilities.${NC}"
    else
        echo -e "${RED}Unknown OS. Please install an audio player manually.${NC}"
    fi
}

# Copy sound files
echo -e "${YELLOW}Copying sound files...${NC}"
if [ -d "$SCRIPT_DIR/sounds" ]; then
    cp -f "$SCRIPT_DIR"/sounds/*.mp3 "$SOUNDS_DIR/" 2>/dev/null
    echo -e "${GREEN}Sound files copied successfully!${NC}"
else
    echo -e "${RED}Error: sounds directory not found!${NC}"
    echo -e "${YELLOW}Creating sounds directory. Please add MP3 files:${NC}"
    echo -e "${YELLOW}add.mp3, commit.mp3, push.mp3, pull.mp3, merge.mp3, clone.mp3, error.mp3${NC}"
    mkdir -p "$SCRIPT_DIR/sounds"
    exit 1
fi

# Install audio player
install_audio_player

# Create git wrapper script
echo -e "${YELLOW}Creating git wrapper script...${NC}"
cat > "$HOOK_DIR/git-wrapper" << 'WRAPPER'
#!/bin/bash
# Git Laugh - Wrapper Script for Git Commands
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
WRAPPER

chmod +x "$HOOK_DIR/git-wrapper"
echo -e "${GREEN}Git wrapper script created!${NC}"

# Add to shell profiles
add_to_profile() {
    local profile="$1"
    if [ -f "$profile" ]; then
        if ! grep -q "# Git Laugh" "$profile" &>/dev/null; then
            echo "" >> "$profile"
            echo "# Git Laugh" >> "$profile"
            echo "alias git='$HOOK_DIR/git-wrapper'" >> "$profile"
            echo -e "${GREEN}Added Git Laugh alias to $profile${NC}"
            return 0
        else
            echo -e "${YELLOW}Git Laugh alias already exists in $profile${NC}"
            return 1
        fi
    fi
    return 1
}

echo -e "${YELLOW}Setting up shell aliases...${NC}"
added=0
if add_to_profile "$HOME/.bashrc"; then added=1; fi
if add_to_profile "$HOME/.zshrc"; then added=1; fi
if add_to_profile "$HOME/.bash_profile"; then added=1; fi

if [ "$added" -eq 0 ]; then
    echo -e "${YELLOW}Could not automatically add to shell profile.${NC}"
    echo -e "${YELLOW}Please add this line manually to your shell profile:${NC}"
    echo "alias git='$HOOK_DIR/git-wrapper'"
fi

# Special setup for Windows
if [ "$OS" == "windows" ]; then
    echo -e "${YELLOW}Setting up Windows-specific configuration...${NC}"
    
    # Create a PowerShell profile if it doesn't exist
    if command -v powershell.exe &> /dev/null; then
        powershell.exe -Command "if (!(Test-Path -Path \$PROFILE -PathType Leaf)) { New-Item -Path \$PROFILE -ItemType File -Force }" &>/dev/null
        
        # Add function to PowerShell profile
        powershell.exe -Command "if (!(Select-String -Path \$PROFILE -Pattern 'Git-Laugh')) { Add-Content -Path \$PROFILE -Value \"`n# Git Laugh`nfunction Git { & '$HOOK_DIR/git-wrapper' `$args }\" }" &>/dev/null
        
        echo -e "${GREEN}Added Git function to PowerShell profile!${NC}"
        echo -e "${YELLOW}Note: On Windows, use 'Git' (capital G) for sounds to play.${NC}"
    fi
fi

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}To use Git Laugh immediately, restart your terminal or run:${NC}"

if [ "$OS" == "windows" ]; then
    echo -e "Open a new PowerShell window and use 'Git' instead of 'git'"
else
    echo -e "source ~/.bashrc  # or appropriate shell profile"
fi

echo -e "\n${GREEN}Enjoy your sound effects!${NC}"
