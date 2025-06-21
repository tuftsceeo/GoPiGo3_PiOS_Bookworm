# GoPiGo3_PiOS_Bookworm

Installation Of GoPiGo3 Software on PiOS Bookworm

- UNOFFICIAL - Do Not contact ModularRobotics for support on this configuration
- For Raspberry Pi 4 and Raspberry Pi 5  
- Removed GoPiGo3 software I2C
  - I2C devices must use hardware I2C bus connectors (not AD1 or AD2)
- Updated distance_sensor and easy_distance_sensor to default to hardware I2C
- Does not install GoPiGo3 desktop apps 


### Script works on:
- PiOS Bookworm 64-bit Desktop

### REQUIREMENTS
- System must have pi user
- Must be user pi when running this script
- Must be connected to Internet for the install

### INSTALLATION  
```
wget https://raw.githubusercontent.com/tuftsceeo/GoPiGo3_PiOS_Bookworm/main/setups/install_GoPiGo3_PiOS_Bookworm.sh
source install_GoPiGo3_PiOS_Bookworm.sh
```

### After it reboots, FIRST TEST:
```
python3 /home/pi/Dexter/GoPiGo3/Software/Python/Examples/Read_Info.py
```
