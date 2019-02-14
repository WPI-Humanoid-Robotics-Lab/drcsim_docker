#!/usr/bin/env bash

DUID=$((UID%256))
IP=${IPADDR:-172.16.$DUID.$DUID}

if [[ "$(docker images -q drcsim:$DUID 2> /dev/null)" == "" ]]; then
  docker build -t drcsim:$DUID --build-arg ip=$IP .
fi

if [[ "$(docker network ls | grep docker_bridge_$DUID 2> /dev/null)" == "" ]]; then
  echo "creating network bridge for docker image"
  docker network create --subnet=172.16.$DUID.0/24 --driver=bridge docker_bridge_$DUID
fi

echo "running drcsim 0.11 docker container"

# Gazebo won't start gpurayplugin without display
XAUTH=/tmp/.docker.xauth
xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
if [ ! -f /tmp/.docker.xauth ]
then
  export XAUTH=/tmp/.docker.xauth
  xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
fi
DISPLAY="${DISPLAY:-:0}"

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

printf "IP address is $IP \nROS master URI : http://$IP:11311 \nGazebo master URI : http://$IP:11345\n"

docker run --rm --name drcsim_${USER} \
    -e DISPLAY=unix$DISPLAY \
    --net=docker_bridge_$DUID \
    --ip=$IP \
    -e XAUTHORITY=/tmp/.docker.xauth \
    --privileged \
    -e ROS_MASTER_URI=http://$IP:11311 \
    -e ROS_IP=$IP \
    --device /dev/dri \
    -v /etc/localtime:/etc/localtime:ro \
    -v $NVIDIA_LIB:/usr/local/nvidia/lib64 \
    -v $NVIDIA_BIN:/usr/local/nvidia/bin \
    -v $NVIDIA_LIB32:/usr/local/nvidia/lib \
    -v /dev/log:/dev/log \
    -v "/tmp/.docker.xauth:/tmp/.docker.xauth" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --ulimit rtprio=99 \
    drcsim:$DUID


#    --runtime=nvidia \
