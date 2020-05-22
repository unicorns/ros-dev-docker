#!/bin/bash

if [ -f "/usr/src/catkin_ws/devel/setup.bash" ]; then
    source "/usr/src/catkin_ws/devel/setup.bash"
elif [ -f "/opt/carla-ros-bridge/catkin_ws/install/setup.bash" ]; then
    source "/opt/carla-ros-bridge/catkin_ws/install/setup.bash"
elif [ -f "/opt/ros/kinetic/setup.bash" ]; then
    source "/opt/ros/kinetic/setup.bash"
fi

# cd into the working directory
cd /usr/src/catkin_ws
