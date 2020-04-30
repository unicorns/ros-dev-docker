#!/bin/sh -e

docker build -t ${IMAGE_NAME:-ros-dev} .
docker build -t ${NVIDIA_IMAGE_NAME:-ros-dev-nvidia} . -f nvidia.Dockerfile
