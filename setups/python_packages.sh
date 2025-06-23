#!/bin/bash
# Set up Python packages for EDL projects using GoPiGo3
# ================

sudo pip3 install opencv-python --break-system-packages
sudo pip3 install ipywidgets --break-system-packages

sudo pip3 install piServoCtl --break-system-packages
sudo pip install adafruit-circuitpython-dotstar --break-system-packages
sudo pip uninstall Jetson.GPIO --break-system-packages -y

sudo pip3 install matplotlib  --break-system-packages
sudo pip3 install google-cloud-vision --break-system-packages
sudo pip3 install google-cloud-translate --break-system-packages
sudo pip3 install apriltag  --break-system-packages
sudo pip3 install seaborn --break-system-packages
sudo pip3 install sparkfun-pi-servo-hat --break-system-packages
sudo pip3 install imutils --break-system-packages
sudo pip3 install pillow --break-system-packages
sudo pip install Flask  --break-system-packages

sudo pip install jupyterlab-tour --break-system-packages
sudo pip install ipyevents --break-system-packages
sudo pip install lckr_jupyterlab_variableinspector --break-system-packages
sudo pip install requests --break-system-packages

sudo pip install jupyterlab-language-pack-zh-CN --break-system-packages
sudo pip install jupyterlab-language-pack-zh-TW --break-system-packages
sudo pip install jupyterlab-language-pack-pt-BR --break-system-packages
sudo pip install  jupyterlab-language-pack-fr-FR --break-system-packages
sudo pip install jupyterlab-language-pack-de-DE --break-system-packages
sudo pip install  jupyterlab-language-pack-id-ID --break-system-packages
sudo pip install  jupyterlab-language-pack-es-ES --break-system-packages

# pip freeze > /home/pi/GoPiGo3_PiOS_Bookworm/py_packages.txt
