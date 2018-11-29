# drcsim_docker
Docker images for gazebo simulation of Atlas using IHMC controllers version 0.11

### Prerequisites
* Ubuntu 16.04
* Nvidia GPU > Fermi2.1
* Nvidia Drivers >= 384

### Instructions
1. Install [docker-ce](https://docs.docker.com/install/linux/docker-ce/ubuntu/) using the instructions given below.
```bash
sudo apt-get update

# to uninstall older versions of docker
sudo apt-get remove docker docker-engine docker.io

sudo apt-get update
	
sudo apt-get install \
     apt-transport-https \
     ca-certificates \
     curl \
     software-properties-common
 	
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
 	
sudo apt-key fingerprint 0EBFCD88
#Verify that you now have the key with the fingerprint 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88, by searching 	  	   the last 8 characters of the fingerprint.
 	
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
	
sudo apt-get update
	
sudo apt-get install docker-ce
```
3. Install [nvidia-docker plugin](https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)). Please refer to prerequisites in that link.  
```bash

docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
sudo apt-get purge nvidia-docker

sudo apt-get install nvidia-docker2
sudo pkill -SIGHUP dockerd
```

4. Run the script to build docker image and run the container. Docker needs sudo access by default. If you see an error while running the docker image, use sudo. Refer to [this](https://askubuntu.com/questions/477551/how-can-i-use-docker-without-sudo) if you wish to allow docker commands without sudo.
```bash
# clone the repository if you have not done that already
git clone https://github.com/WPI-Humanoid-Robotics-Lab/drcsim_docker.git  -b master --single-branch
	
# Go the drcsim_docker directory
cd drcsim_docker/
	
# When running it for the first time, it might take around 30m minutes or more depending on your internet speed
# The scripts have IHMC controller version number in the name
bash runDrcsimDocker.sh
```

5. Connect gazebo client on host machine (in a new terminal)
```bash
GAZEBO_MASTER_URI=http://201.1.1.10:11345 gzclient
```
6. To run code on docker image export the following variables. You can add these to ~/.bashrc for ease of use.
```bash
export ROS_MASTER_URI=http://201.1.1.10:11311
export ROS_IP=201.1.0.1 # Confirm this from ifconfig results
```

7. To stop the docker run `docker stop drcsim`
