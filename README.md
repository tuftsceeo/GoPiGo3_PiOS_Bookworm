# bookworm_test
GoPiGo3 on Bookworm  - especially i2c, i2c distance sensor, Grove Ultrasonic Ranger, and MPU9250 IMU


- Installed current (Oct 7,2023) 64-bit PiOS Desktop (bullseye)
- Upgraded OS to bookworm (Debian 12)
- Installed GoPiGo3 software
- Removed GoPiGo3 software I2C (depended on wiringpi not avail on bookworm)
- Updated distance_sensor and easy_distance_sensor to default to hardware I2C
- Passed all basic GoPiGo3 tests
- tested pypi imusensor package for MPU9250 IMU (appears to work, board is partially fried)
 
