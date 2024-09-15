# Ubuntu Setup

This project provides scripts to automate the setup of a fresh Ubuntu installation with all the tools and configurations I usually need.

## Overview

The main script installs a collection of essential packages and configurations, including:

- **Python**
- **Visual Studio Code**
- **Google Chrome**
- **Docker**
- **Terminator** (terminal emulator)
- **Powerlevel10k** (zsh theme)
- And much more

All the packages to be installed are listed in `config-files/apt-packages.txt`.

## Features

- **Automated Package Installation**: Installs all necessary packages listed in `apt-packages.txt`.
- **Repository Setup**: Adds necessary repositories and imports GPG keys.
- **Configuration Files**: Copies configuration files for Zsh, Powerlevel10k, and Terminator.
- **Optional**: Allows optional installation of Grub Customizer via a command-line option.
- **Export Scripts**: Includes scripts to export the list of installed packages and GPG keys from the current system.

## Scripts

### Main Script

- **`setup_ubuntu.sh`**: The main script that sets up your Ubuntu environment.

### Export Scripts (located in `export/`)

1. **`export_packages.sh`**: Creates `apt-packages.txt` based on all packages installed on the running machine.
2. **`get_gpg.sh`**: Creates the `repo_keys.gpg` file containing all GPG keys for the repositories.

## Usage

**This script is designed for Ubuntu systems.**

### Running the Setup Script

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/ubuntu-setup.git
   cd ubuntu-setup
   ```
2. **Make the Script Executable**
   ```bash
    chmod +x setup_ubuntu.sh
    ```
3. **Run the Script**
    ```bash
    ./setup_ubuntu.sh [OPTIONS]
    ```

#### **Options**
- **`--grub`**: Installs Grub Customizer.
- **`--help`**: Installs Grub Customizer.

#### **Example**
```bash
./setup_ubuntu.sh --grub
```
### Exporting Installed Packages and GPG Keys

1. **Export Packages**
    Navigate to the export/ directory and run:
    ```bash
    cd export/
    chmod +x export_packages.sh
    ./export_packages.sh
    ```
    This will generate **`apt-packages.txt`** in the config-files/ directory.

2. **Export GPG Keys**
    Navigate to the export/ directory and run:
    ```bash
    chmod +x get_gpg.sh
    ./get_gpg.sh
    ```
    This will create **`repo_keys.gpg`**.

### Customization
- Adding/Removing Packages

    - Edit **`config-files/apt-packages.txt`** to add or remove packages as needed.
    - The script will install packages listed in this file.

- Adjusting Repositories

    - Update repository URLs and keys in **`setup_ubuntu.sh`** if necessary.

### Compatibility
- Designed for Ubuntu 22.04 LTS (Jammy Jellyfish)
