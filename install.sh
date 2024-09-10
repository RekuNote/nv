#!/bin/bash

# Dependencies: dialog
# Ensure dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "Dialog is required but not installed. Installing..."
    sudo apt-get install -y dialog
fi

# Configuration Paths
REPOS_DIR="$HOME/.nv_repos"
REPO_LIST_FILE="$REPOS_DIR/repos.json"
PACKAGES_DIR="$REPOS_DIR/packages"
PACKAGES_TXT="$REPOS_DIR/packages.txt"
DEFAULT_REPO_URL="https://www.reximemo.net/repo"

# Function to show a message box
function show_message {
    dialog --msgbox "$1" 10 50
}

# Function to add a repository
function add_repository {
    local url
    url=$(dialog --inputbox "Enter the repository URL:" 8 50 "$DEFAULT_REPO_URL" 3>&1 1>&2 2>&3)
    case "$?" in
        0)
            if [ -n "$url" ]; then
                # Add URL to repo list
                if ! grep -q "$url" "$REPO_LIST_FILE"; then
                    echo "$url" >> "$REPO_LIST_FILE"
                    show_message "Repository added: $url"
                else
                    show_message "Repository already exists: $url"
                fi
            else
                show_message "Repository URL cannot be empty."
            fi
            ;;
        1)
            show_message "Canceled."
            ;;
    esac
}

# Function to remove a repository
function remove_repository {
    local url
    url=$(dialog --inputbox "Enter the repository URL to remove:" 8 50 "" 3>&1 1>&2 2>&3)
    case "$?" in
        0)
            if [ -n "$url" ]; then
                grep -v "$url" "$REPO_LIST_FILE" > "$REPO_LIST_FILE.tmp"
                mv "$REPO_LIST_FILE.tmp" "$REPO_LIST_FILE"
                show_message "Repository removed: $url"
            else
                show_message "Repository URL cannot be empty."
            fi
            ;;
        1)
            show_message "Canceled."
            ;;
    esac
}

# Function to setup the TUI
function setup_tui {
    while true; do
        CHOICE=$(dialog --menu "Setup NV" 15 50 4 \
            "1" "Manage Repositories" \
            "2" "Configure Repositories Directory" \
            "3" "Finish Setup" \
            3>&1 1>&2 2>&3)
        case "$CHOICE" in
            1)
                while true; do
                    REPO_CHOICE=$(dialog --menu "Manage Repositories" 15 50 4 \
                        "1" "Add Repository" \
                        "2" "Remove Repository" \
                        "3" "List Repositories" \
                        "4" "Back" \
                        3>&1 1>&2 2>&3)
                    case "$REPO_CHOICE" in
                        1)
                            add_repository
                            ;;
                        2)
                            remove_repository
                            ;;
                        3)
                            dialog --textbox "$REPO_LIST_FILE" 20 50
                            ;;
                        4)
                            break
                            ;;
                        *)
                            show_message "Invalid choice."
                            ;;
                    esac
                done
                ;;
            2)
                REPOS_DIR=$(dialog --inputbox "Enter the new repositories directory path:" 8 50 "$REPOS_DIR" 3>&1 1>&2 2>&3)
                if [ -n "$REPOS_DIR" ]; then
                    REPO_LIST_FILE="$REPOS_DIR/repos.json"
                    PACKAGES_DIR="$REPOS_DIR/packages"
                    PACKAGES_TXT="$REPOS_DIR/packages.txt"
                    mkdir -p "$PACKAGES_DIR"
                    touch "$REPO_LIST_FILE"
                    touch "$PACKAGES_TXT"
                    echo "[]" > "$REPO_LIST_FILE"
                    show_message "Repositories directory updated to: $REPOS_DIR"
                else
                    show_message "Directory path cannot be empty."
                fi
                ;;
            3)
                break
                ;;
            *)
                show_message "Invalid choice."
                ;;
        esac
    done
}

# Main script execution
dialog --msgbox "Welcome to the NV setup. Let's configure NV package manager." 10 50

# Setup TUI for initial configuration
setup_tui

# Final message
dialog --msgbox "Setup complete! You can now use the NV package manager." 10 50

# Clean up
clear
