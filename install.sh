#!/bin/bash

# Installation script for NV Package Manager

# Constants
DEFAULT_REPO="https://www.reximemo.net/repo"
SCRIPT_URL="https://raw.githubusercontent.com/RekuNote/nv/main/nv"
INSTALL_DIR="/usr/local/bin/nv"
TEMP_SCRIPT="/tmp/nv"
REPOS_DIR="$HOME/.nv_repos"
REPO_LIST_FILE="$REPOS_DIR/repos.json"
PACKAGES_DIR="$REPOS_DIR/packages"
PACKAGES_TXT="$REPOS_DIR/packages.txt"

# Colors
RESET_COLOR='\033[0m'
INFO_COLOR='\033[1;34m'
ERROR_COLOR='\033[1;31m'

# Function to check if the system is compatible
function check_compatibility {
    if ! grep -q '^ID=ubuntu' /etc/os-release && ! grep -q '^ID=debian' /etc/os-release; then
        echo -e "${ERROR_COLOR}nv is only compatible with Ubuntu or Debian-based distributions.${RESET_COLOR}"
        exit 1
    fi
}

# Function to check and install required packages
function check_dependencies {
    local dependencies=("curl" "jq" "dpkg" "apt-get" "dialog")
    local missing=0

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${ERROR_COLOR}Missing dependency: $dep${RESET_COLOR}"
            missing=1
        fi
    done

    if [ $missing -eq 1 ]; then
        echo -e "${ERROR_COLOR}Please install the missing dependencies and try again.${RESET_COLOR}"
        exit 1
    fi
}

# Function to create the TUI for repo configuration
function configure_repos {
    REPOS_DIR_INPUT=$(dialog --inputbox "Enter the directory for repos (default: $REPOS_DIR):" 8 40 "$REPOS_DIR" 3>&1 1>&2 2>&3)
    [ $? -eq 0 ] || exit

    if [ -n "$REPOS_DIR_INPUT" ]; then
        REPOS_DIR="$REPOS_DIR_INPUT"
    fi

    # Ensure the repos directory exists
    mkdir -p "$REPOS_DIR"
    REPO_LIST_FILE="$REPOS_DIR/repos.json"
    PACKAGES_DIR="$REPOS_DIR/packages"
    PACKAGES_TXT="$REPOS_DIR/packages.txt"

    # Initialize repos.json and packages.txt if they don't exist
    if [ ! -f "$REPO_LIST_FILE" ]; then
        echo "[]" > "$REPO_LIST_FILE"
    fi

    if [ ! -f "$PACKAGES_TXT" ]; then
        echo "" > "$PACKAGES_TXT"
    fi

    # Add default repo if it's the first time
    if [ "$(jq '. | length' "$REPO_LIST_FILE")" -eq 0 ]; then
        jq --arg url "$DEFAULT_REPO" '. += [{"url": $url}]' "$REPO_LIST_FILE" > "$REPO_LIST_FILE.tmp"
        mv "$REPO_LIST_FILE.tmp" "$REPO_LIST_FILE"
    fi

    # Display current repos and allow modifications
    while true; do
        REPO_LIST=$(jq -r '.[] | .url' "$REPO_LIST_FILE")
        REPO_SELECTION=$(dialog --menu "Manage Repositories" 15 50 8 $(echo "$REPO_LIST" | awk '{print NR " " $0}') 3>&1 1>&2 2>&3)

        [ $? -eq 0 ] || exit

        if [[ "$REPO_SELECTION" == "" ]]; then
            break
        fi

        if [[ "$REPO_SELECTION" == "$DEFAULT_REPO" ]]; then
            # Remove default repo
            jq --arg url "$DEFAULT_REPO" 'del(.[] | select(.url == $url))' "$REPO_LIST_FILE" > "$REPO_LIST_FILE.tmp"
            mv "$REPO_LIST_FILE.tmp" "$REPO_LIST_FILE"
        else
            # Add a new repo
            NEW_REPO_URL=$(dialog --inputbox "Enter repository URL:" 8 40 "" 3>&1 1>&2 2>&3)
            [ $? -eq 0 ] || exit

            if [ -n "$NEW_REPO_URL" ]; then
                jq --arg url "$NEW_REPO_URL" '. += [{"url": $url}]' "$REPO_LIST_FILE" > "$REPO_LIST_FILE.tmp"
                mv "$REPO_LIST_FILE.tmp" "$REPO_LIST_FILE"
            fi
        fi
    done
}

# Function to download the latest version of nv
function download_nv {
    echo "Downloading the latest version of nv..."
    curl -s -o "$TEMP_SCRIPT" "$SCRIPT_URL"
    if [ $? -ne 0 ]; then
        echo -e "${ERROR_COLOR}Error downloading nv from $SCRIPT_URL${RESET_COLOR}"
        exit 1
    fi
    chmod +x "$TEMP_SCRIPT"
}

# Function to move nv to the appropriate directory and update PATH
function install_nv {
    echo "Installing nv to $INSTALL_DIR..."
    mv "$TEMP_SCRIPT" "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${ERROR_COLOR}Error moving nv script to $INSTALL_DIR${RESET_COLOR}"
        exit 1
    fi

    if ! grep -q "$INSTALL_DIR" <<< "$PATH"; then
        echo "Adding $INSTALL_DIR to PATH..."
        echo "export PATH=\$PATH:$INSTALL_DIR" >> ~/.bashrc
        source ~/.bashrc
    fi

    echo -e "${INFO_COLOR}nv installed successfully! 🎉${RESET_COLOR}"
}

# Main script logic
check_compatibility
check_dependencies

# Configure repos and directories using TUI
configure_repos

# Download and install nv
download_nv
install_nv
