#!/bin/bash

if [ -f "/usr/src/catkin_ws/devel/setup.bash" ]; then
    source "/usr/src/catkin_ws/devel/setup.bash"
elif [ -f "/opt/global_catkin_ws_deps/install/setup.bash" ]; then
    source "/opt/global_catkin_ws_deps/install/setup.bash"
elif [ -f "/opt/ros/kinetic/setup.bash" ]; then
    source "/opt/ros/kinetic/setup.bash"
fi

# cd into the working directory
cd /usr/src/catkin_ws

# use XDG_DATA_HOME for bash history
export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}"/bash/history
# source custom bashrc if available
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/bash/bashrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/bash/bashrc"
