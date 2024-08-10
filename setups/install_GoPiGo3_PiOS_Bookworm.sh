#!/bin/bash

# Script works on:
# - PiOS Bookworm 32-bit Desktop
# - PiOS Bookworm 64-bit Desktop

# REQUIREMENTS:
# - System must have pi user
# - Must be user pi when running this script

# USAGE:  
#    wget https://raw.githubusercontent.com/slowrunner/GoPiGo3_PiOS_Bookworm/main/setups/install_GoPiGo3_PiOS_Bookworm.sh
#    source install_GoPiGo3_PiOS_Bookworm.sh


cd /home/pi
git clone http://www.github.com/DexterInd/GoPiGo3.git /home/pi/Dexter/GoPiGo3
sudo curl -kL dexterindustries.com/update_tools | bash -s -- --system-wide --use-python3-exe-too --install-deb-debs --install-python-package
sudo apt install -y --no-install-recommends python3-curtsies
git clone https://github.com/DexterInd/DI_Sensors.git /home/pi/Dexter/DI_Sensors

# === pigpiod
# wget https://github.com/joan2937/pigpio/archive/master.zip
# unzip master.zip
# cd pigpio-master
# make
# sudo make install
# cd ..
# rm master.zip

git clone https://github.com/slowrunner/GoPiGo3_PiOS_Bookworm.git /home/pi/GoPiGo3_PiOS_Bookworm

# sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/pigpiod.service /etc/systemd/system
# sudo systemctl enable pigpiod.service
# sudo systemctl start pigpiod.service
# systemctl status pigpiod.service

# === setup RFR_Tools
sudo git clone https://github.com/DexterInd/RFR_Tools.git /home/pi/Dexter/lib/Dexter/RFR_Tools
sudo apt  install -y libffi-dev

cd /home/pi/Dexter/lib/Dexter//RFR_Tools/miscellaneous/

sudo mv di_i2c.py di_i2c.py.orig
sudo mv setup.py setup.py.orig
sudo cp ~/GoPiGo3_PiOS_Bookworm/i2c/di_i2c.py.bookworm di_i2c.py
sudo cp ~/GoPiGo3_PiOS_Bookworm/RFR_Tools/setup.py .
sudo python3 setup.py install

# === also depends on smbus-cffi

sudo pip3 install smbus-cffi --break-system-packages


# ==== GPG3_POWER SERVICE ===
cd ~
sudo cp /home/pi/Dexter/GoPiGo3/Install/gpg3_power.service /etc/systemd/system
sudo chmod 644 /etc/systemd/system/gpg3_power.service
sudo systemctl daemon-reload
sudo systemctl enable gpg3_power.service
sudo systemctl start gpg3_power.service
systemctl status gpg3_power.service


# ==== SETUP GoPiGo3 and DI_Sensors Python3 eggs
cd /home/pi/Dexter/GoPiGo3/Software/Python

sudo mv setup.py setup.py.orig
sudo cp ~/GoPiGo3_PiOS_Bookworm/GPG_Soft_Python/setup.py .
sudo python3 setup.py install

cd /home/pi/Dexter/DI_Sensors/Python/di_sensors
mv easy_distance_sensor.py easy_distance_sensor.py.orig
mv distance_sensor.py distance_sensor.py.orig
cp ~/GoPiGo3_PiOS_Bookworm/di_sensors/distance_sensor.py.bookworm distance_sensor.py
cp ~/GoPiGo3_PiOS_Bookworm/di_sensors/easy_distance_sensor.py.bookworm easy_distance_sensor.py
cd /home/pi/Dexter/DI_Sensors/Python
sudo python3 setup.py install

cd /home/pi/Dexter/GoPiGo3/Software/Python/Examples
sudo mv easy_Distance_Sensor.py easy_Distance_Sensor.py.orig
sudo cp ~/GoPiGo3_PiOS_Bookworm/Examples/easy_Distance_Sensor.py.bookworm easy_Distance_Sensor.py



# ==== Setup non-root access rules ====

sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/99-com.rules /etc/udev/rules.d

cp /home/pi/Dexter/GoPiGo3/Install/list_of_serial_numbers.pkl /home/pi/Dexter/.list_of_serial_numbers.pkl

# === ESPEAK-NG
sudo apt install -y espeak-ng
sudo pip3 install py-espeak-ng --break-system-packages
espeak-ng "Am I alive? Can you hear me?"

installresult=$(python3 -c "import gopigo3; g = gopigo3.GoPiGo3()" 2>&1)
if [[ $installresult == *"ModuleNotFoundError"* ]]; then
   echo "GOPIGO3 SOFTWARE INSTALLATION FAILURE: "+$installresult
elif [[ $installresult == *"IOError"* ]]; then
   echo "No SPI response. GoPiGo3 not detected: "+$installresult
   echo "Ensure SPI is enabled in raspi-config."
else
    echo "GOPIGO3 SOFTWARE INSTALLATION SUCCESSFUL."
    echo "Optional - Remove installation files: rm -rf ~/GoPiGo3_PiOS_Bookworm/"
fi
