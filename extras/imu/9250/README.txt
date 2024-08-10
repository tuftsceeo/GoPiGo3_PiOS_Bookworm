These programs demonstrate using the MPU9250

REF: https://medium.com/@niru5/hands-on-with-rpi-and-mpu9250-part-3-232378fa6dbc

There are also publisher/subscriber visualization programs there. 

REF: pypi.org/project/imusensor

The repo provides a bridge between MPU9250 and raspberry pi. 
It also lists various caliberation code and filters for getting an accurate orientation from MPU9250 
This repo mostly concentrates on the problem of connecting IMU(MPU9250) to raspberry pi through I2C communication.

Dependencies:  i2c-tools, smbus


See if MPU9250 is present:  sudo i2cdetect -y 1  should show up at 0x68

Basic Usage:

import os
import sys
import time
import smbus

from imusensor.MPU9250 import MPU9250

address = 0x68
bus = smbus.SMBus(1)
imu = MPU9250.MPU9250(bus, address)
imu.begin()
# imu.caliberateGyro()
# imu.caliberateAccelerometer()
# imu.calibrateMagAppros()
# imu.calibrateMagPrecise()
# or load your own caliberation file
#imu.loadCalibDataFromFile("/home/pi/calib_real_bolder.json")

# Set internal low pass filter to remove some basic noise in the values (Hz)
imu.setLowPassFilterFrequency(AcclLowPassFilter184)  # or ...5, 10, 20, 41, 92, 184


while True:
	imu.readSensor()
	imu.computeOrientation()

	print ("roll: {0} ; pitch : {1} ; yaw : {2}".format(imu.roll, imu.pitch, imu.yaw))
	time.sleep(0.1)



Also: https://github.com/kriswiner/MPU9250 
This is a library for getting some accurate orientation from MPU9250. The author has answered a lot of questions in the issues and most of them are very enlightening for anybody working with IMUs. Highly recommend it.

