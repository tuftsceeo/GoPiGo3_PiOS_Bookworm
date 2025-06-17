#!/bin/bash

# Script works on:
# - PiOS Bookworm 32-bit Desktop
# - PiOS Bookworm 64-bit Desktop

# REQUIREMENTS:
# - System must have pi user
# - Must be user pi when running this script
# - Do not need to configure i2c and spi - script will setup

# USAGE:  
#    wget https://raw.githubusercontent.com/slowrunner/GoPiGo3_PiOS_Bookworm/main/setups/install_GoPiGo3_PiOS_Bookworm.sh
#    source install_GoPiGo3_PiOS_Bookworm.sh


cd /home/pi

echo -e "Get GoPiGo3 Changes For PiOS Bookworm"
git clone https://github.com/tuftsceeo/GoPiGo3_PiOS_Bookworm.git /home/pi/GoPiGo3_PiOS_Bookworm

echo -e "Get Dexter/GoPiGo3/"
git clone http://www.github.com/DexterInd/GoPiGo3.git /home/pi/Dexter/GoPiGo3

echo -e "Get Dexter/DI_Sensors/"
git clone https://github.com/DexterInd/DI_Sensors.git /home/pi/Dexter/DI_Sensors

echo -e "Get Dexter/RFR_Tools/"
git clone https://github.com/DexterInd/RFR_Tools.git /home/pi/Dexter/lib/Dexter/RFR_Tools

echo -e "Get list of serial numbers"
cp /home/pi/Dexter/GoPiGo3/Install/list_of_serial_numbers.pkl /home/pi/Dexter/.list_of_serial_numbers.pkl

echo -e "Setup non-root access rules"
sudo cp /home/pi/GoPiGo3_PiOS_Bookworm/setups/99-com.rules /etc/udev/rules.d

echo -e "Install requirements libffi-dev and python3-curtsies"
sudo apt install -y libffi-dev  
sudo apt install -y --no-install-recommends python3-curtsies

echo -e "setup RFR_TOOLS"
cd /home/pi/Dexter/lib/Dexter//RFR_Tools/miscellaneous/
sudo mv di_i2c.py di_i2c.py.orig
sudo mv setup.py setup.py.orig
sudo cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/i2c/di_i2c.py.bookworm di_i2c.py
sudo cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/RFR_Tools/setup.py .
sudo python3 setup.py install


echo -e "install smbus-cffi python package"
sudo pip3 install smbus-cffi --break-system-packages

echo -e "setup GoPiGo3 Python API"
cd /home/pi/Dexter/GoPiGo3/Software/Python
sudo mv setup.py setup.py.orig
sudo cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/GPG_Soft_Python/setup.py .
sudo mv gopigo3.py gopigo3.py.orig
cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/GPG_Soft_Python/gopigo3.py.bookwormPi5 gopigo3.py
sudo python3 setup.py install

echo -e "setup di_sensors API"
cd /home/pi/Dexter/DI_Sensors/Python/di_sensors
mv easy_distance_sensor.py easy_distance_sensor.py.orig
mv distance_sensor.py distance_sensor.py.orig
cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/di_sensors/distance_sensor.py.bookworm distance_sensor.py
cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/di_sensors/easy_distance_sensor.py.bookworm easy_distance_sensor.py
cd /home/pi/Dexter/DI_Sensors/Python
sudo python3 setup.py install


echo -e "Eliminate software I2C from distance sensor"
cd /home/pi/Dexter/GoPiGo3/Software/Python/Examples
sudo mv easy_Distance_Sensor.py easy_Distance_Sensor.py.orig
sudo cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/Examples/easy_Distance_Sensor.py.bookworm easy_Distance_Sensor.py

echo -e "Copy extended C++ examples to /home/pi/Dexter/GoPiGo3/Software/cpp"
sudo apt install -y cmake
sudo cp -r ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/cpp /home/pi/Dexter/GoPiGo3/Software/

# install calibration panel on desktop
if [[ -d /home/pi/Desktop ]]; then
    cp /home/pi/Dexter/GoPiGo3/Software/Python/Examples/Calibration_Panel/gopigo3_calibration.desktop /home/pi/Desktop/gopigo3_calibration.desktop
fi

# ==== GPG3_POWER SERVICE ===
echo -e "Removing non-working RPi.GPIO supplied with Bookworm"
sudo apt remove -y python3-rpi.gpio
echo -e "Installing working RPi.GPIO for gpg3_power.service"
sudo pip3 install rpi-lgpio --break-system-packages
cd ~
sudo cp /home/pi/Dexter/GoPiGo3/Install/gpg3_power.service /etc/systemd/system
sudo chmod 644 /etc/systemd/system/gpg3_power.service
sudo systemctl daemon-reload
sudo systemctl enable gpg3_power.service
sudo systemctl start gpg3_power.service
systemctl status gpg3_power.service

# === ESPEAK-NG
sudo apt install -y espeak-ng
sudo pip3 install py-espeak-ng --break-system-packages
echo "Setting Volume to 80%"
amixer -D pulse sset Master 80%
espeak-ng "Am I alive? Can you hear me?"


# installs and configures the ip_feedback service
cd /home/pi/GoPiGo3_PiOS_Bookworm/setups
chmod 777 ip_feedback.sh

echo "copying ip_feedback.sh to /home/pi"
cp ip_feedback.sh /home/pi

echo "copying ip_feedback.service to /etc/systemd/system"
sudo cp etc_systemd_system.ip_feedback.service /etc/systemd/system/ip_feedback.service
sudo systemctl daemon-reload
sudo systemctl enable ip_feedback
sudo service ip_feedback start

echo "Adding i2c-dev in /etc/modules"

if grep -q "i2c-dev" /etc/modules; then
        echo "i2c-dev already there"
else
        sudo sh -c "echo 'i2c-dev' >> /etc/modules"
        echo "i2c-dev added"
fi

echo "Making SPI changes in /boot/firmware/config.txt"

if grep -q "#dtparam=spi=on" /boot/firmware/config.txt; then
        sudo sed -i 's/#dtparam=spi=on/dtparam=spi=on/g' /boot/firmware/config.txt
        echo "SPI enabled"
elif grep -q "dtparam=spi=on" /boot/firmware/config.txt; then
        echo "SPI already enabled"
else
        sudo sh -c "echo 'dtparam=spi=on' >> /boot/firmware/config.txt"
        echo "SPI enabled"
fi

echo "Enable I2C changes in /boot/firmware/config.txt"

if grep -q "#dtparam=i2c_arm=on" /boot/firmware/config.txt; then
        sudo sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/g' /boot/firmware/config.txt
        echo "I2C enabled"
elif grep -q "dtparam=i2c_arm=on" /boot/firmware/config.txt; then
        echo "I2C already enabled"
else
        sudo sh -c "echo 'dtparam=i2c_arm=on' >> /boot/firmware/config.txt"
        echo "I2C enabled"
fi

echo "Check Installation Status"

installresult=$(python3 -c "import gopigo3; g = gopigo3.GoPiGo3()" 2>&1)
if [[ $installresult == *"ModuleNotFoundError"* ]]; then
   echo "GOPIGO3 SOFTWARE INSTALLATION FAILURE: "+$installresult
elif [[ $installresult == *"IOError"* ]]; then
   echo "No SPI response. GoPiGo3 not detected: "+$installresult
   echo "Ensure SPI is enabled in raspi-config."
else
    echo "GOPIGO3 SOFTWARE INSTALLATION SUCCESSFUL."
    sleep 10
fi
echo -e "\nREBOOTING...."
sudo reboot 

