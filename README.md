# ros-dev-docker
Docker image for ROS (Kinetic)

**TODO: This documentation needs an update (code-server, VNC, carla-ros-bridge, websocket rosbridge)**

### Getting Started

```
docker pull docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev:kinetic-latest
docker run -v ~/catkin_ws:/usr/src/catkin_ws -u "$(id -u):$(id -g)" -p 8080:8080 -it docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev:kinetic-latest /bin/bash
```

For Nvidia graphic cards:
```
docker pull docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev-nvidia:kinetic-latest
docker run -v ~/catkin_ws:/usr/src/catkin_ws -u "$(id -u):$(id -g)" -p 8080:8080 -it docker.pkg.github.com/unicorns/ros-dev-docker/ros-dev-nvidia:kinetic-latest /bin/bash
```
