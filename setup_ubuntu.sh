#!/bin/bash

set -e

INSTALL_GRUB_CUSTOMIZER=false

####################################################################
# COMMAND LINE OPTIONS
####################################################################
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --grub       Install Grub Customizer"
    echo "  --help       Display this help message and exit"
}

# Parse command-line options
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
# SUDO
####################################################################
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges."
    sudo -v
fi

# Update sudo time stamp until the script finishes
sudo_keep_alive() {
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

sudo_keep_alive
trap 'kill $(jobs -p)' EXIT # Terminate sudo_keep_alive

####################################################################
# PROGRESS BAR
####################################################################
TOTAL_STEPS=9
CURRENT_STEP=0

# Display progress bar
display_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    BAR_WIDTH=50
    FILLED_WIDTH=$((CURRENT_STEP * BAR_WIDTH / TOTAL_STEPS))
    EMPTY_WIDTH=$((BAR_WIDTH - FILLED_WIDTH))
    FILLED_BAR=$(printf "%0.s#" $(seq 1 $FILLED_WIDTH))
    EMPTY_BAR=$(printf "%0.s-" $(seq 1 $EMPTY_WIDTH))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -ne "Progress: [${FILLED_BAR}${EMPTY_BAR}] $PERCENT% \r"
}

####################################################################
# MAIN SCRIPT
####################################################################

# Import gpg keys from file
echo 'Importing GPG keys from repo_keys.gpg'
sudo mkdir -p /etc/apt/trusted.gpg.d/
sudo cp config-files/gpg-keys/repo_keys.gpg /etc/apt/trusted.gpg.d/
sudo mv /etc/apt/trusted.gpg.d/repo_keys.gpg /etc/apt/trusted.gpg.d/oldrepo-archive-keyring.gpg

display_progress

# ADD all necessary repositories
echo 'Adding necessary apt repositories'

# 1. Docker Repository
echo 'Adding Docker repository'
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
display_progress

# 2. Google Chrome Repository
echo 'Adding Google Chrome repository'
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
display_progress


# 4. Grub Customizer PPA
if [ "$INSTALL_GRUB_CUSTOMIZER" = true ]; then
    echo 'Adding Grub Customizer PPA'
    sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
    sudo apt update
    sudo apt install -y grub-customizer
fi
display_progress

# 5. Visual Studio Code Repository
echo 'Adding Visual Studio Code repository'
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
display_progress

# Update package lists
sudo apt update

# Setup vscode Install
echo 'Setting up vscode installation'
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt update

display_progress

# Install packages
echo 'Installing apt packages'
xargs sudo apt-get install -y < config-files/required_packages.txt
sudo apt upgrade -y

display_progress

# Install zsh theme Powerlevel10k
echo 'Installing shell theme Powerlevel10k'
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
fi

display_progress

# Copy config files
echo 'Copying config files'
cp -rf config-files/zshell/.zshrc ~/
cp -rf config-files/p10k/.p10k.zsh ~/
mkdir -p ~/.config/terminator/ && cp -rf config-files/terminator/config ~/.config/terminator

display_progress

echo -ne '\nAll done!\n'
echo 'Remember to import the VSCode settings available at: config-files/vscode/'