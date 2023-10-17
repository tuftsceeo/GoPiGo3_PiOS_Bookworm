/*
 *  https://www.dexterindustries.com/GoPiGo3/
 *  https://github.com/DexterInd/GoPiGo3
 *
 *  Copyright (c) 2017 Dexter Industries
 *  Released under the MIT license (http://choosealicense.com/licenses/mit/).
 *  For more information see https://github.com/DexterInd/GoPiGo3/blob/master/LICENSE.md
 *
 *  This code is an example for using GoPiGo3 motors.
 *  Modified by cyclicalobsessive 2023
 *
 *  Results:  When you run this program, you should see the encoder value for each motor as the robot drives forward for 2 seconds
 *
 *  Example compile command:  (THIS DOES NOT WORK)
 *    g++ -o motors motors.cpp ../GoPiGo3.cpp -I..
 *  Example run command:
 *    sudo ./motors
 *
 *  Build as part of project
 *    cd ~/bookworm_test/cpp
 *    (sudo install cmake)
 *    cmake .
 *    make
 *  To run:
 *    cd ~/bookworm_test/cpp
 *    ./motors
 *
 */

#include <GoPiGo3.h>   // for GoPiGo3
#include <stdio.h>     // for printf
#include <unistd.h>    // for usleep, sleep
#include <signal.h>    // for catching exit signals

GoPiGo3 GPG;

void exit_signal_handler(int signo);

int loop_cnt = 0;
int end_cnt = 2;  // seconds

int main(){
  signal(SIGINT, exit_signal_handler); // register the exit function for Ctrl+C

  GPG.detect(); // Make sure that the GoPiGo3 is communicating and that the firmware is compatible with the drivers.

  // Reset the encoders
  GPG.offset_motor_encoder(MOTOR_LEFT, GPG.get_motor_encoder(MOTOR_LEFT));
  GPG.offset_motor_encoder(MOTOR_RIGHT, GPG.get_motor_encoder(MOTOR_RIGHT));
  GPG.set_motor_power(MOTOR_LEFT, 100);
  GPG.set_motor_power(MOTOR_RIGHT, 100);

  while(loop_cnt < end_cnt){
    // Read the encoders
    int32_t EncoderLeft = GPG.get_motor_encoder(MOTOR_LEFT);
    int32_t EncoderRight = GPG.get_motor_encoder(MOTOR_RIGHT);

    // Use the encoder value from the left motor to control the position of the right motor
    // GPG.set_motor_position(MOTOR_RIGHT, EncoderLeft);

    // Display the encoder values
    printf("Encoder Left: %6d  Right: %6d\n", EncoderLeft, EncoderRight);

    // Delay for one second
    sleep(1);
    loop_cnt++;
  }
  GPG.set_motor_power(MOTOR_RIGHT, 0);
  GPG.set_motor_power(MOTOR_LEFT, 0);
}

// Signal handler that will be called when Ctrl+C is pressed to stop the program
void exit_signal_handler(int signo){
  if(signo == SIGINT){
    GPG.reset_all();    // Reset everything so there are no run-away motors
    exit(-2);
  }
}
