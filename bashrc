if [ -f /usr/src/catkin_ws/devel/setup.bash ]; then
    source /usr/src/catkin_ws/devel/setup.bash
elif [ -f /opt/ros/kinetic/setup.bash ]; then
    source /opt/ros/kinetic/setup.bash
fi