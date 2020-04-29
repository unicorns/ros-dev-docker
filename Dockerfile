FROM carlasim/carla:0.9.8 as carla

FROM ubuntu:16.04

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
RUN python3 -m pip install geopy pyyaml rospkg utm psycopg2

# Carla client
COPY --from=carla --chown=root /home/carla/PythonAPI /opt/carla/PythonAPI
RUN cd /opt/carla/PythonAPI/carla && \
    python -m wheel convert dist/carla*py2.7*.egg && \
    python -m pip install carla*cp27*.whl
RUN cd /opt/carla/PythonAPI/carla && \
    python3 -m wheel convert dist/carla*py3.5*.egg && \
    python3 -m pip install carla*cp35*.whl

# Carla ROS bridge
RUN mkdir -p /opt/carla-ros-bridge/catkin_ws/src && \
    cd /opt/carla-ros-bridge && \
    git clone https://github.com/carla-simulator/ros-bridge.git --recursive && \
    cd catkin_ws/src && \
    ln -s ../../ros-bridge

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
# https://github.com/cdr/code-server/blob/8608ae2f08ef1d4cc8ab2bc1d90633b018a4f41b/ci/release-image/Dockerfile#L36
RUN cd /tmp \
    && wget -q https://github.com/cdr/code-server/releases/download/3.1.1/code-server-3.1.1-linux-x86_64.tar.gz \
    && tar -xzf code-server*.tar.gz \
    && rm code-server*.tar.gz \
    && mv code-server* /usr/local/lib/code-server \
    && ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

RUN sh -c 'echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-$(lsb_release -sc) main" > /etc/apt/sources.list.d/llvm-toolchain.list' && \
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add - && \
    apt-get update && \
    apt-get install -y clangd

# dumb-init
RUN wget -q https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb
RUN dpkg -i dumb-init_*.deb && rm dumb-init_*.deb

# Dev dependencies
RUN apt-get install -y vim

RUN rosdep init

# Expose port for code-server
EXPOSE 8080
WORKDIR /usr/src/catkin_ws
USER docker:docker
ENV PATH="$HOME/.local/bin:${PATH}"

RUN rosdep update

RUN cd /opt/carla-ros-bridge/catkin_ws && \
    sudo chown -R docker:docker . && \
    /bin/bash -c \
    "source /opt/ros/kinetic/setup.bash && \
    rosdep install -y --from-paths src --ignore-src -r && \
    catkin_make"


RUN echo "[ -f ~/.bashrc.local ] && source ~/.bashrc.local" >> /home/docker/.bashrc
COPY bashrc /home/docker/.bashrc.local

ENTRYPOINT ["dumb-init", "fixuid", "-q", "/usr/local/bin/code-server", "--host", "0.0.0.0", "."]

# Useful code-server commands:
#   `code-server --host=0.0.0.0 .`
#   `nohup code-server --host=0.0.0.0 . > /tmp/code-server.log &`

# References:
# https://github.com/cdr/code-server/blob/8608ae2f08ef1d4cc8ab2bc1d90633b018a4f41b/ci/release-image/Dockerfile
