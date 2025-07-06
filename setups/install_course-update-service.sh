#!/bin/bash

# AFTER EDL Repo is cloned to /home/jupyter/EDL

# Installation script for course update service
# Run this script to set up automatic course material updates on robot boot

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="course-update.sh"
SERVICE_NAME="course-update.service"

echo "=== Course Update Service Installation ==="
echo "Installing automatic course material sync service..."
echo

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root or with sudo"
    echo "Usage: sudo $0"
    exit 1
fi

# Check if required files exist
if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
    echo "ERROR: $SCRIPT_NAME not found in $SCRIPT_DIR"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/$SERVICE_NAME" ]; then
    echo "ERROR: $SERVICE_NAME not found in $SCRIPT_DIR"
    exit 1
fi

# Check if target directory exists
if [ ! -d "/home/jupyter/EDL" ]; then
    echo "WARNING: /home/jupyter/EDL directory does not exist"
    echo "Make sure to clone your course repository there before rebooting"
fi

# Install the script
echo "Installing script to /usr/local/bin/..."
cp "$SCRIPT_DIR/$SCRIPT_NAME" /usr/local/bin/
chmod +x "/usr/local/bin/$SCRIPT_NAME"

if [ $? -eq 0 ]; then
    echo "✓ Script installed successfully"
else
    echo "✗ Failed to install script"
    exit 1
fi

# Install the service
echo "Installing systemd service..."
cp "$SCRIPT_DIR/$SERVICE_NAME" /etc/systemd/system/
chmod 644 "/etc/systemd/system/$SERVICE_NAME"

if [ $? -eq 0 ]; then
    echo "✓ Service file installed successfully"
else
    echo "✗ Failed to install service file"
    exit 1
fi

# Reload systemd and enable service
echo "Enabling service for automatic startup..."
systemctl daemon-reload

if systemctl enable "$SERVICE_NAME"; then
    echo "✓ Service enabled successfully"
else
    echo "✗ Failed to enable service"
    exit 1
fi

# Configure git safe directory (in case repo already exists)
if [ -d "/home/jupyter/EDL" ]; then
    echo "Configuring git safe directory..."
    git config --global --add safe.directory /home/jupyter/EDL 2>/dev/null
    echo "✓ Git configuration updated"
fi

# Test the installation
echo
echo "=== Installation Complete ==="
echo
echo "Testing service status..."
if systemctl is-enabled "$SERVICE_NAME" >/dev/null 2>&1; then
    echo "✓ Service is enabled and will run on boot"
else
    echo "✗ Service is not properly enabled"
    exit 1
fi

echo
echo "=== Summary ==="
echo "✓ Script installed: /usr/local/bin/$SCRIPT_NAME"
echo "✓ Service installed: /etc/systemd/system/$SERVICE_NAME"
echo "✓ Service enabled for automatic startup"
echo
echo "The service will automatically:"
echo "  - Run on every boot after network is available"
echo "  - Pull latest course materials from git"
echo "  - Preserve all student work and file timestamps"
echo "  - Stop updating after August 1, 2025"
echo
echo "Manual commands:"
echo "  Test now:        sudo systemctl start $SERVICE_NAME"
echo "  Check status:    sudo systemctl status $SERVICE_NAME"
echo "  View logs:       cat /var/log/course-update.log"
echo "  Disable:         sudo systemctl disable $SERVICE_NAME"
echo
echo "Installation successful! 🎉"