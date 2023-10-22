#!/bin/bash

pushd ~/bookworm_test/ROS2_Humble/docker_images/ros/humble/ubuntu/jammy/desktop
sudo docker build -t ros_docker .
cp Dockerfile ~/bookworm_test/ROS2_Humble/ros2_humble_desktop_dockerfile
popd
sudo docker build . -t r2hd -f ros2_humble_desktop_dockerfile
