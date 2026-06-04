#!/bin/bash

# --- EDIT THIS NAME ONLY ---
TOOL_NAME="gflip"
# ---------------------------

# Configuration (Dynamic based on TOOL_NAME)
SOURCE_SCRIPT="${TOOL_NAME}.sh"
TARGET_DIR="$HOME/.$TOOL_NAME"
TARGET_SCRIPT="$TARGET_DIR/$TOOL_NAME.sh"
CONFIG_FILE="$TARGET_DIR/profiles.json"
COMPLETION_FILE="$TARGET_DIR/completion.bash"
BASHRC="$HOME/.bashrc"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Starting Git-Flip (${TOOL_NAME}) installation...${NC}"

# 1. Check if source script exists
if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    echo -e "${RED}Error: '$SOURCE_SCRIPT' not found in current directory!${NC}"
    exit 1
fi

# 2. Create target directory
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "Creating directory $TARGET_DIR..."
    mkdir -p "$TARGET_DIR"
fi

# 3. Initialize profiles.json if missing
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Initializing $CONFIG_FILE..."
    echo "{}" > "$CONFIG_FILE"
fi

# 4. Copy script to target
echo "Installing script to $TARGET_SCRIPT..."
cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"

# 5. Write tab-completion script
echo "Setting up tab-completion..."
cat > "$COMPLETION_FILE" << EOF
# ${TOOL_NAME} - bash tab completion
_${TOOL_NAME}_completions() {
    local cur prev
    COMPREPLY=()
    cur="\${COMP_WORDS[COMP_CWORD]}"
    prev="\${COMP_WORDS[COMP_CWORD-1]}"
    
    # Define your exact arrays
    local commands=(add list update delete use status help uninstall)
    local flags=(-a -l -u -d -x -s -h -un)
    
    # Colors
    local GREEN=\$'\e[0;32m'
    local NC=\$'\e[0m'
    
    # Gather profile keys
    local profiles=()
    if [[ -f "$CONFIG_FILE" ]]; then
        mapfile -t profiles < <(jq -r 'keys[]' "$CONFIG_FILE" 2>/dev/null)
    fi

    # Context-specific logic (gflip use <TAB>, etc.)
    case "\$prev" in
        use)
            COMPREPLY=(\$(compgen -W "\${profiles[*]} --local" -- "\$cur"))
            return 0
            ;;
        update|-u|delete|-d)
            COMPREPLY=(\$(compgen -W "\${profiles[*]}" -- "\$cur"))
            return 0
            ;;
    esac

    if [[ "\${COMP_WORDS[1]}" == "use" && \$COMP_CWORD -eq 3 ]]; then
        COMPREPLY=(\$(compgen -W "--local" -- "\$cur"))
        return 0
    fi

    # TOP-LEVEL LOGIC (When typing just: gflip <TAB>)
    if [[ "\$prev" == "${TOOL_NAME}" ]]; then
        # Combine all possible structural words cleanly into COMPREPLY so Bash handles them natively
        local opts=("\${profiles[@]}" "\${commands[@]}" "\${flags[@]}")
        COMPREPLY=(\$(compgen -W "\${opts[*]}" -- "\$cur"))
        
        # If the user hasn't typed anything yet, force our custom aligned visual layout matrix
        if [[ -z "\$cur" ]]; then
            # Colorize the profiles array for display
            local colored_profiles=()
            for prof in "\${profiles[@]}"; do
                colored_profiles+=("\${GREEN}\${prof}\${NC}")
            done

            # Print the custom aligned rows directly to the terminal display safely
            printf "\n%s\n" "\${colored_profiles[*]}"
            printf "%-8s%-8s%-8s%-8s%-8s%-8s%-8s%-12s\n" "\${commands[@]}"
            printf "%-8s%-8s%-8s%-8s%-8s%-8s%-8s%-4s\n" "\${flags[@]}"
            
            # Redraw the current prompt clean line so it doesn't duplicate text
            bind '"\e[0n": redraw-current-line' 2>/dev/null
            printf '\e[5n'
        fi
    fi

    return 0
}
complete -F _${TOOL_NAME}_completions ${TOOL_NAME}
EOF

# 6. Add alias to .bashrc
ALIAS_LINE="alias $TOOL_NAME='$TARGET_SCRIPT'"
if grep -q "alias $TOOL_NAME=" "$BASHRC"; then
    echo -e "${YELLOW}Alias '$TOOL_NAME' already exists. Updating...${NC}"
    sed -i "s|alias $TOOL_NAME=.*|$ALIAS_LINE|" "$BASHRC"
else
    echo "Adding alias to .bashrc..."
    echo -e "\n# ${TOOL_NAME} - Git Identity Manager\n$ALIAS_LINE" >> "$BASHRC"
fi

# 7. Add completion source to .bashrc
COMPLETION_LINE="source \"$COMPLETION_FILE\""
if grep -q "$COMPLETION_FILE" "$BASHRC"; then
    echo -e "${YELLOW}Completion already in .bashrc. Skipping...${NC}"
else
    echo "Adding tab-completion to .bashrc..."
    echo -e "$COMPLETION_LINE" >> "$BASHRC"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}Run this to activate:${NC}  source ~/.bashrc"
echo -e "${BLUE}Then try:${NC}              $TOOL_NAME help"