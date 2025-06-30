#!/bin/bash

# Script works on:
# - PiOS Bookworm 32-bit Desktop
# - PiOS Bookworm 64-bit Desktop

# REQUIREMENTS:
# - System must have pi user
# - Must be user pi when running this script
# - Do not need to configure i2c and spi - script will setup

# Forked from: https://github.com/slowrunner/GoPiGo3_PiOS_Bookworm

# USAGE:  
#    wget https://raw.githubusercontent.com/tuftsceeo/GoPiGo3_PiOS_Bookworm/main/setups/install_GoPiGo3_PiOS_Bookworm.sh
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

echo -e "Install requirements libffi-dev and python3-curtsies and cmake"
sudo apt install -y libffi-dev  
sudo apt install -y --no-install-recommends python3-curtsies


echo -e "setup RFR_TOOLS"
cd /home/pi/Dexter/lib/Dexter//RFR_Tools/miscellaneous/
sudo mv di_i2c.py di_i2c.py.orig
sudo mv setup.py setup.py.orig
sudo cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/i2c/di_i2c.py.bookworm di_i2c.py
sudo cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/RFR_Tools/setup.py .
sudo pip3 install -e . --break-system-packages


echo -e "install smbus-cffi python package"
sudo pip3 install smbus-cffi --break-system-packages

echo -e "setup GoPiGo3 Python API"
cd /home/pi/Dexter/GoPiGo3/Software/Python
sudo mv setup.py setup.py.orig
sudo cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/GPG_Soft_Python/setup.py .
sudo mv gopigo3.py gopigo3.py.orig
cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/GPG_Soft_Python/gopigo3.py.bookwormPi5 gopigo3.py
sudo pip3 install -e . --break-system-packages


echo -e "setup di_sensors API"
cd /home/pi/Dexter/DI_Sensors/Python/di_sensors
mv easy_distance_sensor.py easy_distance_sensor.py.orig
mv distance_sensor.py distance_sensor.py.orig
cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/di_sensors/distance_sensor.py.bookworm distance_sensor.py
cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/di_sensors/easy_distance_sensor.py.bookworm easy_distance_sensor.py
cd /home/pi/Dexter/DI_Sensors/Python
sudo pip3 install -e . --break-system-packages


# NO LONGER NEED - SW I2C is now replaced with hardware I2C in di_i2c.py
# echo -e "Eliminate software I2C from distance sensor"
# cd /home/pi/Dexter/GoPiGo3/Software/Python/Examples
# sudo mv easy_Distance_Sensor.py easy_Distance_Sensor.py.orig
# sudo cp ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/Examples/easy_Distance_Sensor.py.bookworm easy_Distance_Sensor.py

# echo -e "Copy extended C++ examples to /home/pi/Dexter/GoPiGo3/Software/cpp"
sudo apt install -y cmake
# sudo cp -r ~/GoPiGo3_PiOS_Bookworm/gpg_sw_changes/cpp /home/pi/Dexter/GoPiGo3/Software/

# install calibration panel on desktop
if [[ -d /home/pi/Desktop ]]; then
    cp /home/pi/Dexter/GoPiGo3/Software/Python/Examples/Calibration_Panel/gopigo3_calibration.desktop /home/pi/Desktop/gopigo3_calibration.desktop
fi

echo -e "PART 1 - DONE RUNNING, NOT TESTED"
echo -e "Now PART 2 - run setups/GoPiGo_Setup_part2.sh"
cd /home/pi