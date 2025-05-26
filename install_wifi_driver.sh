#!/bin/bash

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo privileges."
  exit 1
fi

# Determine script's own directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to display progress
display_progress() {
  echo -ne "$1...\r"
}

# Update and install necessary packages
display_progress "Updating and installing necessary packages"
apt-get update -qq
apt-get install -y ndiswrapper-utils-1.9 wget unzip >/dev/null
echo "Updating and installing necessary packages... Done."

# GitHub repository URL (raw files)
REPO_URL="https://github.com/Nevergiveup11837/mt7902driverforlinux/raw/main"

# List of files we need
FILES=(
  "mtkihvx.dll"
  "mtkwl1.dat"
  "mtkwl1_2.dat"
  "mtkwl2.dat"
  "mtkwl2_2.dat"
  "mtkwl2_2s.dat"
  "mtkwl2s.dat"
  "mtkwl3.dat"
  "mtkwl3_2.dat"
  "mtkwl4.dat"
  "mtkwl6ex.cat"
  "mtkwl6ex.inf"
  "mtkwl6ex.sys"
  "WIFI_MT7902_patch_mcu_1_1_hdr.bin"
  "WIFI_MT7922_patch_mcu_1_1_hdr.bin"
  "WIFI_RAM_CODE_MT7902_1.bin"
  "WIFI_RAM_CODE_MT7922_1.bin"
)

echo "Checking for driver files in $SCRIPT_DIR..."
for FILE in "${FILES[@]}"; do
  if [ -f "$SCRIPT_DIR/$FILE" ]; then
    echo "  ✓ $FILE found locally."
  else
    display_progress "Downloading $FILE"
    wget -q "$REPO_URL/$FILE" -O "$SCRIPT_DIR/$FILE"
    if [ $? -ne 0 ]; then
      echo -e "\nFailed to download $FILE. Exiting."
      exit 1
    fi
    echo "  ↓ $FILE downloaded."
  fi
done
echo "All driver files are in place."

# Install driver using NDISWrapper
display_progress "Installing driver with NDISWrapper"
ndiswrapper -i "$SCRIPT_DIR/mtkwl6ex.inf" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\nFailed to install driver with NDISWrapper. Exiting."
  exit 1
fi
echo "Installing driver with NDISWrapper... Done."

# Verify driver installation
display_progress "Verifying driver installation"
ndiswrapper -l
echo "Verifying driver installation... Done."

# Load NDISWrapper module
display_progress "Loading NDISWrapper module"
modprobe ndiswrapper
echo "Loading NDISWrapper module... Done."

# Copy firmware files to the system firmware directory
FIRMWARE_DIR="/lib/firmware"
echo "Copying firmware files to $FIRMWARE_DIR"
for FIRM in WIFI_MT7902_patch_mcu_1_1_hdr.bin WIFI_MT7922_patch_mcu_1_1_hdr.bin WIFI_RAM_CODE_MT7902_1.bin WIFI_RAM_CODE_MT7922_1.bin; do
  cp "$SCRIPT_DIR/$FIRM" "$FIRMWARE_DIR/"
done
echo "Copying firmware files... Done."

# Add NDISWrapper to module startup
display_progress "Adding NDISWrapper to module startup"
ndiswrapper -m >/dev/null 2>&1
update-initramfs -u >/dev/null 2>&1
echo "Adding NDISWrapper to module startup... Done."

echo "Driver installation complete. Please reboot your computer to finalize the configuration."
