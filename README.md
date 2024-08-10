# GoPiGo3_PiOS_Bookworm

Installation Of GoPiGo3 Software on PiOS Bookworm

- Supports Raspberry Pi 4 and Raspberry Pi 5  
- Removed GoPiGo3 software I2C
  - (depended on wiringpi/pigpio not avail on PiOS Bookworm/Pi5)
  - I2C devices must use hardware I2C bus connectors (not AD1 or AD2)
- Updated distance_sensor and easy_distance_sensor to default to hardware I2C
- Recoded gopigo3_power.py to use gpiod
- Lowered the GoPiGo3 SPI transfer rate to 432000 for increased reliability under Bookworm
- Does not install GoPiGo3 desktop apps 


### Script works on:
- PiOS Bookworm 32-bit Desktop
- PiOS Bookworm 64-bit Desktop

### REQUIREMENTS
- System must have pi user
- Must be user pi when running this script

### INSTALLATION  
```
wget https://raw.githubusercontent.com/slowrunner/GoPiGo3_PiOS_Bookworm/main/setups/install_GoPiGo3_PiOS_Bookworm.sh
source install_GoPiGo3_PiOS_Bookworm.sh
```
