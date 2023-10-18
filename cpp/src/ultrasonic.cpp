
/*
 *  https://www.dexterindustries.com/GoPiGo3/
 *  https://github.com/DexterInd/GoPiGo3
 *
 *  Copyright (c) 2017 Dexter Industries
 *  Released under the MIT license (http://choosealicense.com/licenses/mit/).
 *  For more information see https://github.com/DexterInd/GoPiGo3/blob/master/LICENSE.md
 *
 *  This is an example for using an ultrasonic sensor with the GoPiGo3.
 *
 *  Hardware: Connect a "grove ultrasonic ranger" to GPG3 AD2 port.
 *            (Not HC-SR04 - those do not work with this code)
 *
 *  Results:  You should see the value go down and up as you move your hand in front of the Grove Ultrasonic Ranger.
 *
 *  Example run command:
 *    ./ultrasonic
 *
 */

#include <GoPiGo3.h>    // for GoPiGo3
#include <stdio.h>      // for printf
#include <unistd.h>     // for usleep
#include <signal.h>     // for catching exit signals

GoPiGo3 GPG;

void exit_signal_handler(int signo);

int main(){
  signal(SIGINT, exit_signal_handler); // register the exit function for Ctrl+C

  GPG.detect(); // Make sure that the GoPiGo3 is communicating and that the firmware is compatible with the drivers.

  GPG.set_grove_type(GROVE_2, GROVE_TYPE_US); //GROVE_1 or GROVE2 as wired

  sensor_ultrasonic_t US;

  usleep(50000); // wait 0.05sec for sensor to be configured

  while(true){
    int USerror = GPG.get_grove_value(GROVE_2, &US);  // GROVE_1 or GROVE_2 as wired
    printf("US: Error %d  %4dmm \n", USerror, US.mm);
    usleep(20000);  // sleep for 0.02 sec

  }
}

// Signal handler that will be called when Ctrl+C is pressed to stop the program
void exit_signal_handler(int signo){
  if(signo == SIGINT){
    GPG.reset_all();    // Reset everything so there are no run-away motors
    exit(-2);
  }
}
