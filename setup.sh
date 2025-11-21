#!/bin/bash

set -euo pipefail

INSTALL_GRUB_CUSTOMIZER=false

####################################################################
# PATHS
####################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config-files"

####################################################################
# HELPERS
####################################################################
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --grub       Install Grub Customizer"
    echo "  --help       Display this help message and exit"
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: required command '$1' not found in PATH."
        echo "Please install '$1' and re-run this script."
        exit 1
    fi
}

####################################################################
# OPTIONS
####################################################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --grub)
            INSTALL_GRUB_CUSTOMIZER=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help to display usage information."
            exit 1
            ;;
    esac
done

####################################################################
# PRECHECKS
####################################################################
require_command sudo
require_command curl
require_command gpg
require_command dpkg
require_command lsb_release
require_command xargs

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Warning: '${CONFIG_DIR}' not found. Some steps may be skipped."
fi

if [ "$EUID" -ne 0 ]; then
    echo "Some steps require sudo; requesting credentials..."
    sudo -v
fi

####################################################################
# PROGRESS BAR
####################################################################
TOTAL_STEPS=8
CURRENT_STEP=0

display_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local BAR_WIDTH=50
    local FILLED_WIDTH=$((CURRENT_STEP * BAR_WIDTH / TOTAL_STEPS))
    local EMPTY_WIDTH=$((BAR_WIDTH - FILLED_WIDTH))
    local FILLED_BAR EMPTY_BAR
    FILLED_BAR=$(printf "%0.s#" $(seq 1 "$FILLED_WIDTH"))
    EMPTY_BAR=$(printf "%0.s-" $(seq 1 "$EMPTY_WIDTH"))
    local PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -ne "Progress: [${FILLED_BAR}${EMPTY_BAR}] ${PERCENT}% \r"
}

####################################################################
# MAIN
####################################################################

# 1. Custom APT GPG keys (optional)
if [ -f "${CONFIG_DIR}/gpg-keys/repo_keys.gpg" ]; then
    echo 'Importing custom APT GPG keys from repo_keys.gpg'
    sudo mkdir -p /etc/apt/trusted.gpg.d/
    sudo cp "${CONFIG_DIR}/gpg-keys/repo_keys.gpg" /etc/apt/trusted.gpg.d/
    sudo mv /etc/apt/trusted.gpg.d/repo_keys.gpg /etc/apt/trusted.gpg.d/oldrepo-archive-keyring.gpg
else
    echo "Skipping custom APT GPG keys (not found: ${CONFIG_DIR}/gpg-keys/repo_keys.gpg)"
fi
display_progress

# 2. Docker repo
echo 'Adding Docker APT repository'
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
display_progress

# 3. Google Chrome repo
echo 'Adding Google Chrome APT repository'
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
display_progress

# 4. VS Code repo + optional Grub PPA + apt update
echo 'Adding Visual Studio Code APT repository'
sudo mkdir -p /etc/apt/keyrings
if [ -f /usr/share/keyrings/microsoft.gpg ]; then
    MS_KEYRING="/usr/share/keyrings/microsoft.gpg"
else
    MS_KEYRING="/etc/apt/keyrings/microsoft.gpg"
    if [ ! -f "$MS_KEYRING" ]; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
            | gpg --dearmor > /tmp/packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg "$MS_KEYRING"
        rm -f /tmp/packages.microsoft.gpg
    else
        echo "  - Microsoft keyring already exists at $MS_KEYRING"
    fi
fi
if grep -R "https://packages.microsoft.com/repos/code" /etc/apt/sources.list /etc/apt/sources.list.d >/dev/null 2>&1; then
    echo "  - VS Code repository already configured, skipping"
else
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${MS_KEYRING}] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
fi
display_progress

# 5. Install packages + upgrade
if [ -f "${CONFIG_DIR}/required_packages.txt" ]; then
    echo 'Installing APT packages from required_packages.txt'
    grep -vE '^\s*#' "${CONFIG_DIR}/required_packages.txt" \
      | grep -vE '^\s*$' \
      | xargs -r sudo apt-get install -y
else
    echo "Skipping package installation (not found: ${CONFIG_DIR}/required_packages.txt)"
fi

if [ "$INSTALL_GRUB_CUSTOMIZER" = true ]; then
    echo 'Ensuring Grub Customizer is installed'
    sudo apt-get install -y grub-customizer
fi

echo 'Upgrading existing packages'
sudo apt-get upgrade -y
display_progress

# 6. Oh My Zsh
echo 'Installing Oh My Zsh (if not present)'
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        echo "Warning: failed to install Oh My Zsh (network or curl issue)."
    }
else
    echo "Oh My Zsh already installed at $HOME/.oh-my-zsh"
fi
display_progress

# 7. Powerlevel10k
echo 'Installing Powerlevel10k Zsh theme (if not present)'
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "${ZSH_CUSTOM_DIR}/themes/powerlevel10k" ]; then
    mkdir -p "${ZSH_CUSTOM_DIR}/themes"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM_DIR}/themes/powerlevel10k" || {
        echo "Warning: failed to clone Powerlevel10k (git missing or network issue)."
    }
else
    echo "Powerlevel10k already installed at ${ZSH_CUSTOM_DIR}/themes/powerlevel10k"
fi
display_progress

# 8. Change shell to zsh if not already
if [ "$SHELL" != "/bin/zsh" ]; then
    echo 'Changing default shell to zsh'
    chsh -s /bin/zsh || {
        echo "Warning: failed to change default shell to zsh."
    }
fi
display_progress

echo -ne '\nSystem setup done!\n'
echo "You can now run the dotfiles script inside .dotfiles to apply your configs."
