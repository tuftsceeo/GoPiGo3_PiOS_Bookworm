#!/bin/bash
# Set up Python packages for EDL projects using GoPiGo3
# ================

# Image Libraries
sudo pip3 install opencv-python --break-system-packages
# sudo pip3 install pillow --break-system-packages # probably not needed?
sudo pip3 install apriltag  --break-system-packages
sudo pip3 install imutils --break-system-packages

# Servo Libraries
sudo pip3 install piServoCtl --break-system-packages
sudo pip3 install sparkfun-pi-servo-hat --break-system-packages

# Plotting Libraries
sudo pip3 install matplotlib  --break-system-packages
sudo pip3 install seaborn --break-system-packages

# Google Cloud Libraries
sudo pip3 install google-cloud-vision --break-system-packages
sudo pip3 install google-cloud-translate --break-system-packages

sudo pip install Flask  --break-system-packages

# ================
# Install JupyterLab extensions
# ================
sudo pip3 install ipywidgets --break-system-packages
sudo pip install jupyterlab-tour --break-system-packages
sudo pip install ipyevents --break-system-packages
sudo pip install lckr_jupyterlab_variableinspector --break-system-packages
# sudo pip install ipydrawio --break-system-packages #diagrams in jupyterlab, but it wants jupyterlab 3.8 not 4.0 installed from extension manager?
sudo pip install ipympl --break-system-packages # JupyterLab Matplotlib support
sudo pip install requests --break-system-packages

# ================
# Install JupyterLab languages
# ================
sudo pip install jupyterlab-language-pack-zh-CN --break-system-packages
sudo pip install jupyterlab-language-pack-zh-TW --break-system-packages
sudo pip install jupyterlab-language-pack-pt-BR --break-system-packages
sudo pip install  jupyterlab-language-pack-fr-FR --break-system-packages
sudo pip install jupyterlab-language-pack-de-DE --break-system-packages
sudo pip install  jupyterlab-language-pack-id-ID --break-system-packages
sudo pip install  jupyterlab-language-pack-es-ES --break-system-packages

sudo pip install simplejpeg==1.8.2 --break-system-packages # Fixes the numpy 2 issue

sudo pip install adafruit-circuitpython-dotstar --break-system-packages # This wants the Jetson.GPIO package so not currently working
sudo pip uninstall Jetson.GPIO --break-system-packages -y # Uninstall Jetson.GPIO as it causes issues on Pi

# Setup EDL Resources Library
cd ~
cd GoPiGo3_PiOS_Bookworm/setups/EDLResourcesLib
sudo pip3 install -e . --break-system-packages

# pip freeze > /home/pi/GoPiGo3_PiOS_Bookworm/py_packages.txt
