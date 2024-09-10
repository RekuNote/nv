#!/bin/bash

# Installation script for NV Package Manager

# Constants
SCRIPT_URL="https://raw.githubusercontent.com/RekuNote/nv/main/nv"
INSTALL_DIR="/usr/local/bin/nv"
TEMP_SCRIPT="/tmp/nv"

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
    sudo nv update
}

# Main script logic
check_compatibility
check_dependencies
download_nv
install_nv
