# GoPiGo3_PiOS_Bookworm

Install GoPiGo3 on PiOS Bookworm

- Removed GoPiGo3 software I2C (depended on wiringpi/pigpio not avail on PiOS Bookworm/Pi5)
- Updated distance_sensor and easy_distance_sensor to default to hardware I2C
- Recoded gopigo3_power.py to use gpiod
- Lowered the GoPiGo3 SPI transfer rate to 432000 for increased reliability under Bookworm
- Does not install GoPiGo3 desktop apps 


