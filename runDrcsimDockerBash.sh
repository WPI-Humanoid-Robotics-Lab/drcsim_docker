#!/usr/bin/env bash

if [[ "$(docker images -q drcsim:gazebo 2> /dev/null)" == "" ]]; then
  docker build -t drcsim:gazebo .
fi

if [[ "$(docker network ls | grep docker_bridge 2> /dev/null)" == "" ]]; then
  echo "creating network bridge for docker image"
  docker network create --subnet 201.1.1.0/16 --driver bridge docker_bridge
fi

echo "running drcsim 0.11 docker container"

 XAUTH=/tmp/.docker.xauth
 xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
if [ ! -f /tmp/.docker.xauth ]
then
  export XAUTH=/tmp/.docker.xauth
  xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
fi

# Use lspci to check for the presence of an nvidia graphics card
has_nvidia=`lspci | grep -i nvidia | wc -l`

# Set docker gpu parameters
if [ ${has_nvidia} -gt 0 ]
then
  # check if nvidia-modprobe is installed
  if ! which nvidia-modprobe > /dev/null
  then
    echo nvidia-docker-plugin requires nvidia-modprobe
    echo please install nvidia-modprobe
    exit -1
  fi
fi

docker run --rm --name drcsim \
   --runtime=nvidia \
   -e ROS_MASTER_URI=http://201.1.1.10:11311 \
  -e ROS_IP=201.1.1.10 \
  --ulimit rtprio=99 \
  --net=docker_bridge\
  --ip=201.1.1.10 \
  -it \
  drcsim:gazebo /bin/bash
