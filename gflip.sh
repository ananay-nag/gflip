#!/bin/bash

# Configuration
TOOL_NAME="gflip"
CONFIG_DIR="$HOME/.${TOOL_NAME}"
CONFIG_FILE="$CONFIG_DIR/profiles.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# --- Setup & Validation ---
setup() {
    mkdir -p "$CONFIG_DIR"
    [[ ! -f "$CONFIG_FILE" ]] && echo "{}" > "$CONFIG_FILE"
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: 'jq' is not installed. Run: sudo apt install jq${NC}"
        exit 1
    fi
}

profile_exists() {
    [[ $(jq "has(\"$1\")" "$CONFIG_FILE") == "true" ]]
}

# --- Actions ---

show_help() {
    echo -e "${BOLD}Git-Flip (${TOOL_NAME}) - Multi-Identity Manager${NC}"
    echo -e ""
    echo -e "Usage:"
    echo -e "  ${TOOL_NAME} add | -a                        Add a new profile"
    echo -e "  ${TOOL_NAME} list | -l                       List all profiles"
    echo -e "  ${TOOL_NAME} <profile-name>                  View specific profile details"
    echo -e "  ${TOOL_NAME} update | -u <profile-name>      Update an existing profile"
    echo -e "  ${TOOL_NAME} delete | -d <profile-name>      Remove a profile"
    echo -e "  ${TOOL_NAME} use <profile-name> [--local]    Switch identity (global by default)"
    echo -e "  ${TOOL_NAME} status | -s                     Check which profile is active"
    echo -e "  ${TOOL_NAME} uninstall | -un                 Uninstall ${TOOL_NAME}"
    echo -e "  ${TOOL_NAME} help | -h                       Show this menu"
}

add_or_update() {
    local name=$1
    local is_update=$2
    local existing_name=""
    local existing_email=""

    if [[ -z "$name" ]]; then
        read -p "Enter profile name: " name
    fi

    # Fetch existing data if profile exists
    if profile_exists "$name"; then
        existing_name=$(jq -r ".[\"$name\"].name" "$CONFIG_FILE")
        existing_email=$(jq -r ".[\"$name\"].email" "$CONFIG_FILE")
    fi

    # Block re-adding an existing profile
    if [[ "$is_update" == "false" && -n "$existing_name" ]]; then
        echo -e "${RED}Error: Profile '$name' already exists. Use 'update' to modify it.${NC}"
        exit 1
    fi

    # Prompt — show current values as defaults when updating
    if [[ -n "$existing_name" ]]; then
        read -p "Enter Git User Name ($existing_name): " input_name
        read -p "Enter Git Email ($existing_email): " input_email
        gname=${input_name:-$existing_name}
        gemail=${input_email:-$existing_email}
    else
        read -p "Enter Git User Name: " gname
        read -p "Enter Git Email: " gemail
    fi

    # Validate not empty
    if [[ -z "$gname" || -z "$gemail" ]]; then
        echo -e "${RED}Error: Name and Email cannot be empty.${NC}"
        return 1
    fi

    # Basic email format check
    if [[ ! "$gemail" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
        echo -e "${YELLOW}Warning: Email format looks invalid.${NC}"
    fi

    # Save to JSON
    jq --arg p "$name" --arg u "$gname" --arg e "$gemail" \
        '.[$p] = {"name": $u, "email": $e}' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" \
        && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    echo -e "${GREEN}Profile '$name' saved successfully.${NC}"
}

view_detail() {
    if profile_exists "$1"; then
        echo -e "${BLUE}Profile: $1${NC}"
        jq -r ".[\"$1\"] | \"  Name:  \(.name)\n  Email: \(.email)\"" "$CONFIG_FILE"
    else
        echo -e "${RED}Profile '$1' not found.${NC}"
        show_help
    fi
}

use_profile() {
    local name=$1
    local scope="--global"
    [[ "$2" == "--local" ]] && scope="--local"

    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Provide a profile name.${NC}"
        echo -e "Usage: ${TOOL_NAME} use <profile-name> [--local]"
        exit 1
    fi

    if profile_exists "$name"; then
        local u e
        u=$(jq -r ".[\"$name\"].name" "$CONFIG_FILE")
        e=$(jq -r ".[\"$name\"].email" "$CONFIG_FILE")

        git config $scope user.name "$u"
        git config $scope user.email "$e"

        echo -e "${GREEN}Switched to '$name' [$scope]${NC}"
        echo -e "  Name:  $u"
        echo -e "  Email: $e"
    else
        echo -e "${RED}Profile '$name' not found.${NC}"
    fi
}

list_profiles() {
    local count
    count=$(jq 'keys | length' "$CONFIG_FILE")

    if [[ "$count" -eq 0 ]]; then
        echo -e "${YELLOW}No profiles yet. Run: ${TOOL_NAME} add${NC}"
    else
        echo -e "${BLUE}Saved Profiles:${NC}"
        jq -r 'keys[]' "$CONFIG_FILE" | while read -r key; do
            local name email
            name=$(jq -r ".[\"$key\"].name" "$CONFIG_FILE")
            email=$(jq -r ".[\"$key\"].email" "$CONFIG_FILE")
            echo -e "  ${BOLD}$key${NC} — $name <$email>"
        done
    fi
}

delete_profile() {
    local name=$1
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Provide a profile name.${NC}"
        exit 1
    fi

    if profile_exists "$name"; then
        jq "del(.[\"$name\"])" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" \
            && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        echo -e "${GREEN}Deleted profile '$name'.${NC}"
    else
        echo -e "${RED}Profile '$name' not found.${NC}"
    fi
}

check_status() {
    local curr_name curr_email
    curr_name=$(git config user.name 2>/dev/null)
    curr_email=$(git config user.email 2>/dev/null)

    if [[ -z "$curr_name" && -z "$curr_email" ]]; then
        echo -e "${YELLOW}No Git identity is currently set.${NC}"
        return
    fi

    echo -e "${BOLD}Current Git Identity:${NC}"
    echo -e "  Name:  $curr_name"
    echo -e "  Email: $curr_email"

    local match
    match=$(jq -r \
        "to_entries[] | select(.value.name==\"$curr_name\" and .value.email==\"$curr_email\") | .key" \
        "$CONFIG_FILE")

    if [[ -n "$match" ]]; then
        echo -e "  ${BOLD}Matched Profile:${NC} ${GREEN}$match${NC}"
    else
        echo -e "  ${YELLOW}No matching ${TOOL_NAME} profile found.${NC}"
    fi
}

uninstall() {
    read -p "Are you sure you want to uninstall ${TOOL_NAME}? [y/N]: " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && echo "Aborted." && return

    rm -rf "$CONFIG_DIR"
    sed -i "/alias $TOOL_NAME=/d" "$HOME/.bashrc"
    sed -i "/$TOOL_NAME\/completion/d" "$HOME/.bashrc"
    echo -e "${GREEN}Uninstalled ${TOOL_NAME}. Run: source ~/.bashrc${NC}"
}

# --- Execution ---
setup

case "$1" in
    add|-a)         add_or_update "$2" "false" ;;
    list|-l)        list_profiles ;;
    update|-u)      add_or_update "$2" "true" ;;
    delete|-d)      delete_profile "$2" ;;
    use)            use_profile "$2" "$3" ;;
    status|-s)      check_status ;;
    help|--help|-h) show_help ;;
    uninstall|-un)  uninstall ;;
    *)
        if [[ -n "$1" ]]; then
            view_detail "$1"
        else
            show_help
        fi
        ;;
esac