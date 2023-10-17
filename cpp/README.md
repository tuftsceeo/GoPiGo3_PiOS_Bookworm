# C++ for GoPiGo3 on Bookworm

DI Examples from /home/pi/Dexter/Software/C and C/Examples with addition of my tests 

REQ: 
  sudo apt install cmake 

To build all programs in src/ dir (included in the CMakeList.txt) 
* cd ~/bookworm_test/cpp
* cmake . 
* make 

To run the executables:
* (cd ~/bookworm_test/cpp)
* ./executable



# THIS DOES NOT WORK ATM! 

To compile an individual program at the cpp/src/ level:
 *    cd /home/pi/bookworm_test/cpp/src
 *    g++ -o motors motors.cpp ../GoPiGo3.cpp -I..
 *  run command:
 *    ./motors


Programs:  
- info:  Read GoPiGo3 info (serial num, firmware version ..) 
- leds:  cycles intensity of left/right red LEDS.  cycles intensity and color of multi-color LED  
- encoders: displays encoder values. Slightly rotate a wheel to see encoder value change 
- drive2secs:  drive forward at max speed for (about) 2 seconds 
- drive: drive GoPiGo3 with 
  -   w  fwd 
  -   s  spin 
  -   x  bwd 
  -   SPACEBAR   stop 
  -   a  left - turn - right d 

- ultrasonic:  plug into AD2 - ( getting "Error 1" ?? ) 
- i2c: reads i2c bus  ( getting "Error 4" ?? ) 
