#!/bin/bash

# Initialize the script file
echo "#!/bin/bash" > add_repositories.sh

# Find all PPAs added via add-apt-repository
grep -hr "^deb .*ppa.launchpad.net" /etc/apt/sources.list.d/ | while read -r line; do
    ppa_name=$(echo "$line" | grep -oP '(?<=ppa.launchpad.net/)[^/]+/[^/]+')
    if [[ -n "$ppa_name" ]]; then
        echo "sudo add-apt-repository -y ppa:$ppa_name" >> add_repositories.sh
    fi
done

# Find other repositories added via add-apt-repository
grep -hr "^deb " /etc/apt/sources.list.d/ | grep -v "ppa.launchpad.net" | while read -r line; do
    echo "sudo add-apt-repository -y '$line'" >> add_repositories.sh
done

# Make the script executable
chmod +x add_repositories.sh

# Export all GPG keys for the repositories
sudo apt-key exportall > repo_keys.gpg
