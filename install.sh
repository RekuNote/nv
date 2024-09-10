#!/bin/bash

# Installation script for NV Package Manager

# Constants
SCRIPT_URL="https://raw.githubusercontent.com/RekuNote/nv/main/nv"
INSTALL_DIR="/usr/local/bin/nv"
TEMP_SCRIPT="/tmp/nv"
BASHRC_PATH="$HOME/.bashrc"
ZSHRC_PATH="$HOME/.zshrc"
SHELL=$(basename "$SHELL")

# Colors
RESET_COLOR='\033[0m'
INFO_COLOR='\033[1;34m'
ERROR_COLOR='\033[1;31m'

# Function to check if the system is compatible
function check_compatibility {
    if ! grep -q '^ID=ubuntu' /etc/os-release && ! grep -q '^ID=debian' /etc/os-release; then
        echo -e "${ERROR_COLOR}This script is only compatible with Ubuntu or Debian-based distributions.${RESET_COLOR}"
        exit 1
    fi
}

# Function to check and install required packages
function check_dependencies {
    local dependencies=("curl" "jq" "dpkg" "apt-get")
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

# Function to download the latest version of nv
function download_nv {
    echo "Downloading the latest version of nv..."
    curl -s -o "$TEMP_SCRIPT" "$SCRIPT_URL"
    if [ $? -ne 0 ]; then
        echo -e "${ERROR_COLOR}Error downloading nv script from $SCRIPT_URL${RESET_COLOR}"
        exit 1
    fi
    chmod +x "$TEMP_SCRIPT"
}

# Function to move nv to the appropriate directory and update PATH
function install_nv {
    echo "Installing nv to $INSTALL_DIR..."
    sudo mv "$TEMP_SCRIPT" "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${ERROR_COLOR}Error moving nv script to $INSTALL_DIR${RESET_COLOR}"
        exit 1
    fi

    if ! grep -q "$INSTALL_DIR" <<< "$PATH"; then
        echo "Adding $INSTALL_DIR to PATH..."
        if [ "$SHELL" = "bash" ]; then
            echo "export PATH=\$PATH:$INSTALL_DIR" >> "$BASHRC_PATH"
            source "$BASHRC_PATH"
        elif [ "$SHELL" = "zsh" ]; then
            echo "export PATH=\$PATH:$INSTALL_DIR" >> "$ZSHRC_PATH"
            source "$ZSHRC_PATH"
        else
            echo -e "${ERROR_COLOR}Unsupported shell: $SHELL. Please add $INSTALL_DIR to your PATH manually.${RESET_COLOR}"
        fi
    fi

    echo -e "${INFO_COLOR}nv installed successfully! 🎉${RESET_COLOR}"
}

# Function to add command not found handler to shell configuration
function add_command_not_found_handler {
    local shell_rc_path="$1"
    local handler_function='
function command_not_found_handle() {
    local cmd="$1"

    # Check if `nv` is installed and available
    if command -v nv >/dev/null 2>&1; then
        # Check if the package exists in the local package list
        if nv list | grep -q "$cmd"; then
            echo "Command '\''$cmd'\'' not found, but can be installed with:"
            echo ""
            echo "sudo nv install $cmd"
            return
        fi
    fi

    # Default behavior if `nv` is not available or the package isn't found
    echo "Command '\''$cmd'\'' not found, but can be installed with:"
    echo ""
    echo "sudo apt install $cmd"
}
'
    # Add the handler function if not already present
    if ! grep -q "command_not_found_handle" "$shell_rc_path"; then
        echo "$handler_function" >> "$shell_rc_path"
        echo "Added command not found handler to $shell_rc_path"
    else
        echo "Command not found handler already present in $shell_rc_path"
    fi
}

# Main script logic
check_compatibility
check_dependencies
download_nv
install_nv

# Add command not found handler based on the shell
if [ "$SHELL" = "/bin/bash" ]; then
    add_command_not_found_handler "$BASHRC_PATH"
elif [ "$SHELL" = "/bin/zsh" ]; then
    add_command_not_found_handler "$ZSHRC_PATH"
else
    echo -e "${ERROR_COLOR}Unsupported shell: $SHELL. Please add the command not found handler manually.${RESET_COLOR}"
fi

echo -e "${INFO_COLOR}nv installation complete. Please restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc for zsh) to apply changes.${RESET_COLOR}"
