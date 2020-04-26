#!/bin/bash -e

if [ "$#" -eq 0 ]; then
    read version
elif [ "$#" -eq 1 ]; then
    version=$1
else
    echo "Illegal number of parameters"
    exit 1
fi

docker push docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev:kinetic-$version
docker push docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev:kinetic-nvidia-$version

echo $version
