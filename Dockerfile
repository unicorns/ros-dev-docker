FROM ubuntu:16.04

RUN apt update && apt install -y lsb-release
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
      && apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# Project dependencies
RUN apt update && apt install -y ros-kinetic-desktop-full python-pip python3-pip ros-kinetic-navigation ros-kinetic-jsk-recognition-msgs
RUN rosdep init && rosdep update

RUN apt install -y wget
# https://github.com/cdr/code-server/blob/8608ae2f08ef1d4cc8ab2bc1d90633b018a4f41b/ci/release-image/Dockerfile#L36
RUN cd /tmp \
    && wget -q https://github.com/cdr/code-server/releases/download/3.1.1/code-server-3.1.1-linux-x86_64.tar.gz \
    && tar -xzf code-server*.tar.gz \
    && rm code-server*.tar.gz \
    && mv code-server* /usr/local/lib/code-server \
    && ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

WORKDIR /usr/src/catkin_ws

# Development dependencies
RUN pip install catkin_tools casadi
RUN apt install -y vim

CMD ["/bin/bash"]
