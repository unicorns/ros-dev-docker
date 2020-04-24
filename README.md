# ros-dev-docker
Docker image for ROS

### Getting Started

```
docker pull docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev:kinetic-1.0.0
docker run -v ~/catkin_ws:/usr/src/catkin_ws -u "$(id -u):$(id -g)" -p 8080:8080 -it docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev:kinetic-1.0.0 /bin/bash
```
