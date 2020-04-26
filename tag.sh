#!/bin/bash -e

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

docker tag ros-dev docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev:kinetic-$1
docker tag ros-dev-nvidia docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev:kinetic-nvidia-$1

echo $1
