#!/bin/bash
# This script sets up JupyterLab and related services on a GoPiGo3 PiOS Bookworm system.

# SETUP JUPYTER LAB -- AFTER THIS USE GIT TO

# It must be run as the jupyter user.
if [[ $(id -un) != "jupyter" ]]; then
    echo "Error: This script must be run as the jupyter user"
    echo "Current user: $(id -un)"
    exit 1
fi

echo "Running as jupyter user"

# Set up JupyterLab configuration
echo "WAIT then enter some passwords when asked PLEASE"
sleep 10
cd /home/jupyter
jupyter lab --generate-config 
sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/EDL/jupyter_lab_config.py /home/jupyter/.jupyter/jupyter_lab_config.py
echo "ENTER *_REGULAR_* EDL PASSWORD"
jupyter lab password

# Copy the Jupyter service file to systemd
sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/EDL/jupyter.service /etc/systemd/system/jupyter.service
sudo systemctl daemon-reload
sudo systemctl enable jupyter.service 
sudo systemctl start jupyter.service 

# Install Shell In A Box
sudo apt install shellinabox
sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/EDL/shellinabox_config /etc/default/shellinabox

cd /home/jupyter
sudo cp /home/pi/Dexter/GoPiGo3/Software/Python/Examples /home/jupyter/Examples
sudo chgrp -R users /home 
sudo chmod -R g+rwx /home

echo "REMINDER - You need to clone in the EDL jupyter notebooks"
cd /home/jupyter
echo "JUPYTER LAB READY"
echo ""


echo "  IMPORTANT - CLONE GIT HERE"
echo "   ╔════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "   ║  git clone -b student_live https://your-username:your-token@github.com/tuftsceeo/EDL.git               ║"
echo "   ╚════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
echo ""
