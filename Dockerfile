FROM carlasim/carla:0.9.8 as carla

FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y lsb-release software-properties-common apt-transport-https
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
      && apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# =============== Project dependencies ===============
RUN add-apt-repository -y ppa:ubuntugis
RUN apt-get update && apt-get install -y ros-kinetic-desktop-full python-pip python3-pip ros-kinetic-navigation ros-kinetic-jsk-recognition-msgs ros-kinetic-rosbridge-suite qgis
RUN apt-get install -y git wget libpng16-16 locales gdb libomp-dev

# Update locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && dpkg-reconfigure --frontend=noninteractive locales

RUN pip install --upgrade pip
RUN python -m pip install catkin_tools casadi utm xmltodict pygame matplotlib==2.2.5 simple_pid tornado pymongo
RUN pip3 install --upgrade pip
RUN python3 -m pip install geopy pyyaml rospkg utm psycopg2 bandit

# Carla client
COPY --from=carla --chown=root /home/carla/PythonAPI /opt/carla/PythonAPI
RUN cd /opt/carla/PythonAPI/carla && \
    python -m wheel convert dist/carla*py2.7*.egg && \
    python -m pip install carla*cp27*.whl
RUN cd /opt/carla/PythonAPI/carla && \
    python3 -m wheel convert dist/carla*py3.5*.egg && \
    python3 -m pip install carla*cp35*.whl

# Carla ROS bridge
# Fix version at 0.9.8 (b83e62a9bb7ab318f9dc24e21b92fa75f5a9ffb0)
RUN mkdir -p /opt/carla-ros-bridge/catkin_ws/src && \
    cd /opt/carla-ros-bridge && \
    git clone https://github.com/carla-simulator/ros-bridge.git --recursive && \
    cd catkin_ws/src && \
    ln -s ../../ros-bridge && \
    cd ros-bridge && \
    git checkout b83e62a9bb7ab318f9dc24e21b92fa75f5a9ffb0

# ===============  Add a non-root user ===============
RUN addgroup --gid 1000 docker && \
    adduser --uid 1000 --ingroup docker --home /home/docker --shell /bin/sh --disabled-password --gecos "" docker && \
    echo "docker ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN USER=docker && \
    GROUP=docker && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

# =============== Development dependencies ===============
# code-server
# https://github.com/cdr/code-server/blob/8608ae2f08ef1d4cc8ab2bc1d90633b018a4f41b/ci/release-image/Dockerfile#L36
RUN cd /tmp \
    && wget -q https://github.com/cdr/code-server/releases/download/3.2.0/code-server-3.2.0-linux-x86_64.tar.gz \
    && tar -xzf code-server*.tar.gz \
    && rm code-server*.tar.gz \
    && mv code-server* /usr/local/lib/code-server \
    && ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

# VNC
RUN apt install -y lxde x11vnc xvfb mesa-utils supervisor

# simplescreenrecorder
RUN apt install -y build-essential cmake pkg-config qt4-qmake libqt4-dev desktop-file-utils \
                   libavformat-dev libavcodec-dev libavutil-dev libswscale-dev libasound2-dev \
                   libpulse-dev libjack-jackd2-dev libgl1-mesa-dev libglu1-mesa-dev libx11-dev \
                   libxfixes-dev libxext-dev libxi-dev libxinerama-dev
USER docker:docker
RUN cd /tmp && \
    git clone https://github.com/ben-z/ssr.git && \
    cd ssr && \
    ENABLE_32BIT_GLINJECT=FALSE ./simple-build-and-install
USER root:root

# dumb-init
RUN wget -q https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb
RUN dpkg -i dumb-init_*.deb && rm dumb-init_*.deb

# Dev dependencies
RUN apt-get install -y vim terminator

RUN rosdep init

# Expose ports for code-server, rosbridge (websocket) and vnc
EXPOSE 8080
EXPOSE 9090
EXPOSE 5900

WORKDIR /usr/src/catkin_ws
USER docker:docker
ENV PATH="$HOME/.local/bin:${PATH}"
ENV SHELL=/bin/bash
ENV XDG_DATA_HOME=/usr/src/catkin_ws/.xdg-home/data
ENV XDG_CONFIG_HOME=/usr/src/catkin_ws/.xdg-home/config

RUN rosdep update

RUN cd /opt/carla-ros-bridge/catkin_ws && \
    sudo chown -R docker:docker . && \
    /bin/bash -c \
    "source /opt/ros/kinetic/setup.bash && \
    rosdep install -y --from-paths src --ignore-src -r && \
    catkin_make"

RUN echo "[ -f ~/.bashrc.local ] && source ~/.bashrc.local" >> /home/docker/.bashrc
COPY bashrc /home/docker/.bashrc.local

COPY supervisord.conf /etc/supervisor/supervisord.conf
RUN sudo chown -R docker:docker /etc/supervisor

COPY Desktop /home/docker/Desktop

ENTRYPOINT ["dumb-init", "fixuid", "-q", "/usr/bin/supervisord" , "-n"]

# Useful code-server commands:
#   `code-server --host=0.0.0.0 .`
#   `nohup code-server --host=0.0.0.0 . > /tmp/code-server.log &`

# References:
# https://github.com/cdr/code-server/blob/8608ae2f08ef1d4cc8ab2bc1d90633b018a4f41b/ci/release-image/Dockerfile
