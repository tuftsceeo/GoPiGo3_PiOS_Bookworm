#!/bin/bash

# Simple script to setup i2c-gpio overlay for GoPiGo3
# Configures software I2C on GPIO 2 (SDA) and GPIO 3 (SCL)

CONFIG_FILE="/boot/config.txt"
BACKUP_FILE="/boot/config.txt.backup.$(date +%Y%m%d_%H%M%S)"
REBOOT_NEEDED=0

echo "Setting up i2c-gpio overlay for GoPiGo3..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Backup config.txt
echo "Creating backup: $BACKUP_FILE"
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Check and add i2c_arm parameter
if ! grep -q "^dtparam=i2c_arm=on" "$CONFIG_FILE"; then
    echo "Adding i2c_arm=on parameter..."
    echo "dtparam=i2c_arm=on" >> "$CONFIG_FILE"
    REBOOT_NEEDED=1
else
    echo "i2c_arm already enabled"
fi

# Check and add i2c-gpio overlay
if ! grep -q "dtoverlay=i2c-gpio.*bus=3.*i2c_gpio_sda=2.*i2c_gpio_scl=3" "$CONFIG_FILE"; then
    echo "Adding i2c-gpio overlay..."
    echo "dtoverlay=i2c-gpio,bus=3,i2c_gpio_sda=2,i2c_gpio_scl=3,i2c_gpio_delay_us=2" >> "$CONFIG_FILE"
    REBOOT_NEEDED=1
else
    echo "i2c-gpio overlay already configured"
fi

# Add users to i2c group
echo "Adding users to i2c group..."
usermod -a -G i2c pi 2>/dev/null && echo "Added user 'pi' to i2c group" || echo "User 'pi' already in i2c group or doesn't exist"
usermod -a -G i2c jupyter 2>/dev/null && echo "Added user 'jupyter' to i2c group" || echo "User 'jupyter' already in i2c group or doesn't exist"

# Check if reboot is needed
if [[ $REBOOT_NEEDED -eq 1 ]]; then
    echo
    echo "Configuration updated. Rebooting in 10 seconds..."
    echo "Press Ctrl+C to cancel reboot"
    sleep 10
    reboot
else
    echo
    echo "Configuration already up to date. Testing current setup..."
    
    # Test current setup
    echo
    echo "Testing i2c-gpio setup..."
    
    # Check if i2c-dev module is loaded
    if ! lsmod | grep -q i2c_dev; then
        echo "Loading i2c-dev module..."
        modprobe i2c-dev
    fi
    
    # List i2c buses
    echo "Available I2C buses:"
    if command -v i2cdetect >/dev/null 2>&1; then
        i2cdetect -l
        
        # Test if bus 3 exists and is accessible
        if [ -e /dev/i2c-3 ]; then
            echo
            echo "Testing /dev/i2c-3 access..."
            i2cdetect -y 3 >/dev/null 2>&1 && echo "SUCCESS: /dev/i2c-3 is accessible" || echo "WARNING: /dev/i2c-3 exists but may not be fully functional"
        else
            echo "WARNING: /dev/i2c-3 not found. Reboot may be required."
        fi
    else
        echo "i2c-tools not installed. Install with: apt install i2c-tools"
    fi
    
    # Check group memberships
    echo
    echo "User group memberships:"
    groups pi 2>/dev/null | grep -q i2c && echo "pi: i2c group OK" || echo "pi: NOT in i2c group"
    groups jupyter 2>/dev/null | grep -q i2c && echo "jupyter: i2c group OK" || echo "jupyter: NOT in i2c group"
fi

echo
echo "Setup complete!"