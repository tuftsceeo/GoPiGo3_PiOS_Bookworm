/*
 *  https://www.dexterindustries.com/GoPiGo3/
 *  https://github.com/DexterInd/GoPiGo3
 *
 *  Copyright (c) 2017 Dexter Industries
 *  Released under the MIT license (http://choosealicense.com/licenses/mit/).
 *  For more information see https://github.com/DexterInd/GoPiGo3/blob/master/LICENSE.md
 *
 *  This code is an example for using GoPiGo3 servos.

 *  Modeled after /home/pi/Dexter/GoPiGo3/Software/Python/Examples/Servo.py
 *
 *  Results:  When you run this program, you should see two servos rotating back and forth
 *
 */

#include <GoPiGo3.h>   // for GoPiGo3
#include <stdio.h>     // for printf
#include <unistd.h>    // for usleep
#include <signal.h>    // for catching exit signals

GoPiGo3 GPG;

void exit_signal_handler(int signo);

int main(){
  signal(SIGINT, exit_signal_handler); // register the exit function for Ctrl+C

  GPG.detect(); // Make sure that the GoPiGo3 is communicating and that the firmware is compatible with the drivers.

  while(true){
    for (int i = 1000; i < 2001; ++i) {
        GPG.set_servo(SERVO_1, i);
        GPG.set_servo(SERVO_2, 3000-i);
        usleep(1000);  // 1 milli-second = 1000 micro-seconds
    }

    for (int i = 1000; i < 2001; ++i) {
        GPG.set_servo(SERVO_2, i);
        GPG.set_servo(SERVO_1, 3000-i);
        usleep(1000);
    }


  }
}

// Signal handler that will be called when Ctrl+C is pressed to stop the program
void exit_signal_handler(int signo){
  if(signo == SIGINT){
    GPG.reset_all();    // Reset everything so there are no run-away motors
    exit(-2);
  }
}
