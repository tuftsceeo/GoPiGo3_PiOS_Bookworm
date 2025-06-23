#!/bin/bash
# This includes installation of necessary packages, configuration of ip address speaking, power and
# wifi_led antenna services and tests setup of the GoPiGo3 Python API.
# ===========

# ==== GPG3_POWER SERVICE ===
echo -e "Removing non-working RPi.GPIO supplied with Bookworm"
sudo apt remove -y python3-rpi.gpio
echo -e "Installing working RPi.GPIO for gpg3_power.service"
#sudo pip3 install rpi-lgpio --break-system-packages # this is broken in Bookworm now
sudo apt install -y python3-rpi.gpio

cd ~
sudo cp /home/pi/Dexter/GoPiGo3/Install/gpg3_power.service /etc/systemd/system
sudo chmod 644 /etc/systemd/system/gpg3_power.service
sudo systemctl daemon-reload
sudo systemctl enable gpg3_power.service
sudo systemctl start gpg3_power.service

sudo cp /home/pi/Dexter/GoPiGo3/Install/antenna_wifi.service /etc/systemd/system
sudo chmod 644 /etc/systemd/system/antenna_wifi.service
sudo systemctl daemon-reload
sudo systemctl enable antenna_wifi.service
sudo systemctl start antenna_wifi.service
       

# === ESPEAK-NG
#sudo apt install -y espeak-ng
sudo apt install espeak-ng espeak-ng-data libespeak-ng-dev 
# needed for py-espeak-ng 
echo "Installing py-espeak-ng"
sudo pip3 install py-espeak-ng --break-system-packages
sudo apt-get install mbrola mbrola-us1 mbrola-us2 mbrola-us3
# get MBROLA voices
echo "Installing pygame"
sudo apt install python3-pygame
echo "Setting Volume to 100%"
amixer -D pulse set Master 100%
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


cd /home/pi/Dexter/GoPiGo3/Troubleshooting/

echo "==============================="
echo "GoPiGo3 Firmware and Hardware Test"
echo "==============================="

echo "GoPiGo3 Troubleshooting Script log" > log.txt
sudo bash hardware_and_firmware_test.sh 2>&1| tee -a log.txt
echo "==============================="




echo -e "\n DONE --- READY TO REBOOT...."

echo "REMINDER - You need to enable VNC in sudo raspi-config"
echo "Interfaces -> VNC -> Enable"
echo "==============================="
sleep 30

echo "Next PART 3 - run setups/start_EDL_core_services.sh"

