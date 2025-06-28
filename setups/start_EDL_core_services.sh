#!/bin/bash
# Starts WayVNC, NoVNC, Websockify, JupyterLab, and Shell In A Box on a GoPiGo3 PiOS Bookworm system.
# Copies EDL Web Homepage.
# ==========

# ==== EDL Set Ups ===
sudo apt update
sudo apt upgrade 

sudo apt install wayvnc novnc websockify

# ==========
# Install NodeJS 20 (for Jupyter Lab 4)
# ==========
# Remove existing nodejs
sudo apt-get remove -y nodejs npm

# Add NodeSource GPG key and repository  
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x bookworm main" | sudo tee /etc/apt/sources.list.d/nodesource.list

# Update and install
sudo apt-get update
sudo apt-get install -y nodejs

# ==========
# Copy the WayVNC configuration file
sudo cp ~/GoPiGo3_PiOS_Bookworm/setups/EDL/wayvnc_config /etc/wayvnc/config

# Copy the Websockify service file to systemd
# Note: Websockify also starts NoVNC to provide a WebSocket interface for NoVNC
sudo cp ~/GoPiGo3_PiOS_Bookworm/setups/EDL/websockify.service /etc/systemd/system/websockify.service 

# Reload systemd to recognize the new service
sudo systemctl daemon-reload
# Also start websockify if you haven't already
sudo systemctl enable websockify.service
sudo systemctl start websockify.service

# Install web server packages
sudo apt install  apache2 php
sudo apt install raspberrypi-net-mods wpagui  
sudo apt install avahi-autoipd bc 
sudo apt install -y mariadb-server mariadb-client

# Copy EDL Webpage 
sudo rm -r /var/www
sudo mkdir -p /var/www/html
sudo cp -r ~/GoPiGo3_PiOS_Bookworm/web/html /var/www
sudo ln -s /etc/hostname /var/www/html/hostname


# Set up JupyterLab and Python packages
sudo apt install python3-setuptools
sudo apt install python3-cffi
sudo pip3 install jupyterlab --break-system-packages
sudo pip3 install numpy pandas matplotlib seaborn scikit-learn --break-system-packages


# Set up Jupyter AI
sudo pip3 install faiss-cpu --break-system-packages
sudo pip3 install jupyter-ai --break-system-packages
sudo pip3 install langchain-openai --break-system-packages

# Create a new user for JupyterLab
sudo adduser jupyter
sudo usermod -a -G adm jupyter
sudo usermod -a -G dialout jupyter
sudo usermod -a -G cdrom jupyter
sudo usermod -a -G sudo jupyter
sudo usermod -a -G audio jupyter
sudo usermod -a -G video jupyter
sudo usermod -a -G plugdev jupyter
sudo usermod -a -G games jupyter
sudo usermod -a -G input jupyter
sudo usermod -a -G render jupyter
sudo usermod -a -G netdev jupyter
sudo usermod -a -G spi jupyter
sudo usermod -a -G i2c jupyter
sudo usermod -a -G gpio jupyter
sudo usermod -a -G lpadmin jupyter

# Give jupyter user necessary permissions
sudo chgrp -R users /home 
sudo chmod -R g+rwx /home

# Add jupyter user to audio and pulse-access groups
# This is necessary for audio playback in JupyterLab
usermod -a -G audio,pulse-access jupyter

# Create the PulseAudio directory structure for jupyter user
mkdir -p /run/user/1001
chown jupyter:jupyter /run/user/1001
chmod 700 /run/user/1001

# Create PulseAudio directory
sudo -u jupyter mkdir -p /run/user/1001/pulse

# Add XDG_RUNTIME_DIR to jupyter user's bashrc if not already there
if ! grep -q "XDG_RUNTIME_DIR" /home/jupyter/.bashrc; then
    echo 'export XDG_RUNTIME_DIR="/run/user/1001"' >> /home/jupyter/.bashrc
fi

# Also add to jupyter user's profile for non-interactive shells
if ! grep -q "XDG_RUNTIME_DIR" /home/jupyter/.profile; then
    echo 'export XDG_RUNTIME_DIR="/run/user/1001"' >> /home/jupyter/.profile
fi

# Set up passwordless sudo for jupyter for the ip_feedback service
echo "jupyter ALL=(ALL) NOPASSWD: /usr/bin/systemctl * ip_feedback*, /bin/systemctl * ip_feedback*" | sudo tee -a /etc/sudoers

# Set up passwordless sudo for jupyter for WiFi Network Management commands
echo "jupyter ALL=(ALL) NOPASSWD: /usr/bin/nmcli *" | sudo tee -a /etc/sudoers

# Set up wallpaper
sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/TuftsWallpaper.png /usr/share/rpd-wallpaper/
pcmanfm --set-wallpaper="/usr/share/rpd-wallpaper/TuftsWallpaper.png"