#!/bin/sh

docker build -t ros-dev .
docker build -t ros-dev-nvidia . -f nvidia.Dockerfile
