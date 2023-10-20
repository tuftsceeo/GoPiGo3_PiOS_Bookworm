#!/bin/bash

# sudo docker run -it osrf/ros:humble-desktop
echo
echo *** PRESS CTRL-D TO EXIT DOCKER
echo
sudo docker run -it --net=host --privileged r2hd
