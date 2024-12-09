#!/bin/bash

# Samba Setup Script for Linux
# Author: Your Name
# Description: Installs Samba and configures users and a shared directory.

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root or use sudo."
  exit 1
fi

# Update system and install Samba
echo "Updating package list and installing Samba..."
apt update && apt install -y samba

# Check if Samba installed successfully
if [ $? -ne 0 ]; then
  echo "Failed to install Samba. Please check your package manager."
  exit 1
fi

# Backup Samba configuration
SMB_CONF="/etc/samba/smb.conf"
echo "Backing up Samba configuration file to ${SMB_CONF}.bak..."
cp "$SMB_CONF" "${SMB_CONF}.bak"

# Add a share configuration
SHARE_NAME="shared"
SHARE_PATH="/srv/samba/${SHARE_NAME}"
echo "Creating Samba share directory at ${SHARE_PATH}..."
mkdir -p "$SHARE_PATH"
chmod 2770 "$SHARE_PATH"

echo "Adding share configuration to $SMB_CONF..."
cat <<EOT >>"$SMB_CONF"

[$SHARE_NAME]
   path = $SHARE_PATH
   valid users = @smbgroup
   read only = no
   browsable = yes
EOT

# Add a Samba group
GROUP_NAME="smbgroup"
echo "Creating group $GROUP_NAME..."
groupadd "$GROUP_NAME"

# Function to create a Samba user
create_smb_user() {
  local username=$1
  echo "Creating user $username..."
  useradd -M -s /sbin/nologin -G "$GROUP_NAME" "$username"
  smbpasswd -a "$username"
  smbpasswd -e "$username"
}

# Create users
echo "Creating Samba users..."
read -p "Enter usernames to create (space-separated): " -a usernames
for username in "${usernames[@]}"; do
  create_smb_user "$username"
done

# Restart Samba services
echo "Restarting Samba services..."
systemctl restart smbd
systemctl enable smbd

# Print success message
echo "Samba setup complete!"
echo "Shared directory: $SHARE_PATH"
echo "Configuration file: $SMB_CONF"
