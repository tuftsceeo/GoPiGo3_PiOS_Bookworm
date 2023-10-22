#!/bin/bash

# Docker invocation with a display
# -v /home:/home/pi/ \
# -v `dirname $(pwd)`:/home/pi/bookworm_test/ROS2_Humble \
# -v /etc/timezone:/etc/timezone:America/New_York
# -e DISPLAY \
# -e QT_GRAPHICSSYSTEM=native \
# -e TZ=`cat /etc/timezone`
 
echo ""
echo "*** PRESS CTRL-D or type exit TO EXIT DOCKER"
echo ""
docker run -it --net=host --privileged \
-v `pwd`:`pwd` \
 r2hd
