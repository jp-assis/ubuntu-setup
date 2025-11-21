# Ubuntu Setup

Script to bootstrap a fresh **Ubuntu 22.04** with common repositories, packages and Zsh theme. 

## Quick Start

```bash
chmod +x setup.sh
./setup.sh          # default setup
./setup.sh --grub   # include Grub Customizer
./setup.sh --help   # show options
```

What it does:

* Adds APT repos: **Docker**, **Google Chrome**, **VS Code**.
* Imports optional custom GPG keyring from `config-files/gpg-keys/repo_keys.gpg`.
* Installs packages listed in `config-files/required_packages.txt`.
* Installs **Powerlevel10k** theme for Zsh (if `~/.oh-my-zsh` exists).


## Exporting Packages and GPG Keys

Inside `export/` there are two helper scripts:

### 1. Export installed packages

```bash
cd export/
chmod +x export_packages.sh
./export_packages.sh
```

Creates **`config-files/apt-packages.txt`** with your installed packages.

### 2. Export GPG keys

```bash
cd export/
chmod +x get_gpg.sh
./get_gpg.sh
```

Creates **`config-files/gpg-keys/repo_keys.gpg`**, used by `setup.sh` to import custom APT keys.


## Customization

* **Packages:** edit `config-files/required_packages.txt`.
* **Repositories / keys:** adjust URLs and GPG handling directly in `setup.sh`.

---

Designed for **Ubuntu 22.04 LTS (Jammy Jellyfish)**.
