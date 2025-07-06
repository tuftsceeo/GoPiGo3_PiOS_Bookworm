#!/bin/bash

# EDL Chat Setup Script for GoPiGo3

# Run this last, after python packages

# This script sets up the custom EDL Chat provider for Jupyter AI
# Run from: /home/pi/GoPiGo3_PiOS_Bookworm/setups

echo "========================================="
echo "EDL Chat Setup for Jupyter AI"
echo "========================================="

# Navigate to EDL_Chat directory
EDL_CHAT_DIR="/home/pi/GoPiGo3_PiOS_Bookworm/setups/EDL/EDL_Chat"

if [ ! -d "$EDL_CHAT_DIR" ]; then
    echo "ERROR: EDL_Chat directory not found at $EDL_CHAT_DIR"
    echo "Please ensure you've cloned the EDL_Chat repository first"
    exit 1
fi

cd "$EDL_CHAT_DIR"
echo "Working in: $EDL_CHAT_DIR"

# Check if pyproject.toml exists
if [ ! -f "pyproject.toml" ]; then
    echo "ERROR: pyproject.toml not found in $EDL_CHAT_DIR"
    exit 1
fi

# Check package directory structure
echo ""
echo "1. Checking package structure..."
if [ ! -d "my_jupyter_ai_custom" ]; then
    echo "ERROR: my_jupyter_ai_custom directory not found"
    echo "Please ensure the package directory exists"
    exit 1
fi

if [ ! -f "my_jupyter_ai_custom/__init__.py" ]; then
    echo "ERROR: __init__.py not found in my_jupyter_ai_custom"
    echo "Please ensure __init__.py exists in the package directory"
    exit 1
fi

if [ ! -f "my_jupyter_ai_custom/providers.py" ]; then
    echo "ERROR: providers.py not found in my_jupyter_ai_custom"
    echo "Please ensure providers.py exists in the package directory"
    exit 1
fi

echo "   Package structure verified ✓"

# Set proper permissions for all users (especially jupyter user)
echo ""
echo "2. Setting permissions..."
chmod -R 755 "$EDL_CHAT_DIR"
echo "   Permissions set to allow all users to read/execute ✓"

# Install the package system-wide
echo ""
echo "3. Installing EDL Chat package..."
echo "   Installing with pip system-wide..."

sudo pip install -e . --break-system-packages

if [ $? -eq 0 ]; then
    echo "   Package installed successfully ✓"
else
    echo "ERROR: Package installation failed"
    exit 1
fi

# Restart Jupyter service
echo ""
echo "4. Restarting Jupyter service..."
sudo systemctl restart jupyter

# Wait for service to start
echo "   Waiting for service to start..."
sleep 5

# Check if service is running
if sudo systemctl is-active --quiet jupyter; then
    echo "   Jupyter service restarted successfully ✓"
else
    echo "WARNING: Jupyter service may not have started properly"
    echo "Check with: sudo systemctl status jupyter"
fi

# Check documentation directory
echo ""
echo "5. Checking documentation directory..."
DOC_DIR="/home/jupyter/EDL/Resources/doc_chunks"
if [ -d "$DOC_DIR" ]; then
    echo "   Documentation directory found at: $DOC_DIR ✓"
    DOC_COUNT=$(find "$DOC_DIR" -name "*.md" | wc -l)
    echo "   Found $DOC_COUNT markdown files"
else
    echo "WARNING: Documentation directory not found at $DOC_DIR"
    echo "   Please ensure your documentation files are in this location"
fi

# Final instructions with emphasis on /learn command
echo ""
echo "========================================="
echo "✅ SETUP COMPLETE!"
echo "========================================="
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Open Jupyter Lab in your browser"
echo ""
echo "2. In the chat panel settings (gear icon):"
echo "   - Select 'EDL Chat' as your Language Model"
echo "   - Enter your OpenAI API key"
echo "   - Click 'Save changes'"
echo ""
echo "3. ⚠️  IMPORTANT - LOAD THE DOCUMENTATION: ⚠️"
echo "   ╔══════════════════════════════════════════════════════╗"
echo "   ║  In the Jupyter chat, type:  /learn EDL/Resources/doc_chunks/*.md               ║"
echo "   ╚══════════════════════════════════════════════════════╝"
echo ""
echo "   This loads the EDLResources documentation into memory!"
echo "   Without this step, the bot won't know about EDLResources!"
echo ""
echo "========================================="
echo ""
echo "📍 Quick Reference:"
echo "   - EDL Chat location: $EDL_CHAT_DIR"
echo "   - Documentation: $DOC_DIR"
echo "   - Service logs: sudo journalctl -u jupyter -f"
echo ""
echo "💡 To update EDL Chat later:"
echo "   1. cd $EDL_CHAT_DIR"
echo "   2. git pull"
echo "   3. sudo pip install -e . --break-system-packages"
echo "   4. sudo systemctl restart jupyter"
echo ""
echo "🎓 Happy teaching with EDL Chat!"
echo ""