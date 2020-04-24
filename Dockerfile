FROM ubuntu:16.04

RUN apt-get update && apt-get install -y lsb-release
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
      && apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# =============== Project dependencies ===============
RUN apt-get update && apt-get install -y ros-kinetic-desktop-full python-pip python3-pip ros-kinetic-navigation ros-kinetic-jsk-recognition-msgs

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
RUN apt-get install -y wget
# https://github.com/cdr/code-server/blob/8608ae2f08ef1d4cc8ab2bc1d90633b018a4f41b/ci/release-image/Dockerfile#L36
RUN cd /tmp \
    && wget -q https://github.com/cdr/code-server/releases/download/3.1.1/code-server-3.1.1-linux-x86_64.tar.gz \
    && tar -xzf code-server*.tar.gz \
    && rm code-server*.tar.gz \
    && mv code-server* /usr/local/lib/code-server \
    && ln -s /usr/local/lib/code-server/code-server /usr/local/bin/code-server

# dumb-init
RUN wget -q https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb
RUN dpkg -i dumb-init_*.deb && rm dumb-init_*.deb

# Dev dependencies
RUN apt-get install -y vim
RUN apt-get install -y git
RUN apt-get install -y python3-pyqt5
RUN pip install --upgrade pip
RUN python -m pip install catkin_tools casadi utm xmltodict
RUN pip3 install --upgrade pip
RUN python3 -m pip install geopy pyyaml rospkg utm psycopg2

RUN rosdep init

# Expose port for code-server
EXPOSE 8080
WORKDIR /usr/src/catkin_ws
USER docker:docker
ENV PATH="$HOME/.local/bin:${PATH}"

RUN rosdep update

RUN echo "[ -f ~/.bashrc.local ] && source ~/.bashrc.local" >> /home/docker/.bashrc
COPY bashrc /home/docker/.bashrc.local

ENTRYPOINT ["dumb-init", "fixuid", "-q", "/usr/local/bin/code-server", "--host", "0.0.0.0", "."]

# Useful code-server commands:
#   `code-server --host=0.0.0.0 .`
#   `nohup code-server --host=0.0.0.0 . > /tmp/code-server.log &`

# References:
# https://github.com/cdr/code-server/blob/8608ae2f08ef1d4cc8ab2bc1d90633b018a4f41b/ci/release-image/Dockerfile
