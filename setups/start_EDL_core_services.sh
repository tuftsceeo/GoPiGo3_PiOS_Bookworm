#!/bin/bash
# Starts WayVNC, NoVNC, Websockify, JupyterLab, and Shell In A Box on a GoPiGo3 PiOS Bookworm system.
# Copies EDL Web Homepage.
# ==========

# ==== EDL Set Ups ===
sudo apt update
sudo apt upgrade 

sudo apt install wayvnc novnc websockify

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



