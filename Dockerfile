FROM nvidia/cuda:8.0-runtime-ubuntu16.04
#FROM ros:kinetic-ros-base
# osrf/ros:kinetic-desktop-full
LABEL maintainer "vvjagtap@wpi.edu"

SHELL ["/bin/bash", "-c"]
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN cat /etc/resolv.conf
RUN apt-get -y update && apt-get install -y sudo apt-utils

# Create a user
RUN export uid=1000 gid=1000 && \
  mkdir -p /home/whrl && \
  echo "whrl:x:${uid}:${gid}:Whrl,,,:/home/whrl:/bin/bash" >> /etc/passwd && \
  echo "whrl:x:${uid}:" >> /etc/group && \
  echo "whrl ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/whrl && \
  chmod 0440 /etc/sudoers.d/whrl && \
  chown ${uid}:${gid} -R /home/whrl

USER whrl
ENV HOME /home/whrl

# Installing general required packages




# Install drcsim 
RUN /bin/bash -c "sudo chown -R whrl:whrl /home/whrl"
RUN /bin/bash -c "echo 'source /opt/ros/kinetic/setup.bash' >> ~/.bashrc"
RUN sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu xenial main" > /etc/apt/sources.list.d/ros-latest.list'
RUN sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116

# Install Dependencies 
RUN  sudo apt-get -y update && sudo apt-get install -y git \
  g++ vim nano wget  ca-certificates  ssh ros-kinetic-pcl-ros \
  x11vnc xvfb icewm lxpanel iperf xz-utils cmake screen terminator konsole\ 
  ros-kinetic-pcl-conversions ros-kinetic-moveit \
  ros-kinetic-trac-ik ros-kinetic-footstep-planner \
  ros-kinetic-humanoid-localization ros-kinetic-multisense-ros \
  ros-kinetic-laser-assembler ros-kinetic-robot-self-filter \
  ros-kinetic-tf2-geometry-msgs ros-kinetic-joint-state-publisher \
  ros-kinetic-octomap-server ros-kinetic-octomap \
  ros-kinetic-joint-trajectory-controller \
  ros-kinetic-image-transport \
  ros-kinetic-joint-state-controller ros-kinetic-position-controllers \
  ros-kinetic-sbpl \
  ros-kinetic-humanoid-nav-msgs ros-kinetic-map-server ros-kinetic-trac-ik* \
  ros-kinetic-multisense-ros ros-kinetic-robot-self-filter ros-kinetic-octomap \
  ros-kinetic-octomap-msgs ros-kinetic-octomap-ros ros-kinetic-gridmap-2d \
  software-properties-common python-software-properties debconf-i18n \
  ros-kinetic-stereo-image-proc python-vcstool python-catkin-tools ros-kinetic-ros-base 

RUN sudo rosdep init
RUN rosdep update 

# Create a catkin workspace
RUN /bin/bash -c "source /opt/ros/kinetic/setup.bash && \
  mkdir ~/kinetic_ws"
RUN /bin/bash -c "source /opt/ros/kinetic/setup.bash && \
  cd ~/kinetic_ws && catkin config --init --mkdirs && \
  cd src && \
  wget https://raw.githubusercontent.com/WPI-Humanoid-Robotics-Lab/atlas_workspace/master/atlas_gazebo_ws.yaml && \
  vcs import < atlas_gazebo_ws.yaml && cd .. && \
  rm -r ~/kinetic_ws/src/tough && \
  rosdep install --from-paths src --ignore-src -r -y"

#Install jdk8 with javafx support
RUN sudo add-apt-repository -y ppa:webupd8team/java
RUN sudo apt-get update
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
RUN sudo apt-get install -y oracle-java8-installer && sudo rm -rf /var/lib/apt/lists/
#
##set default java to version 8
RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-8-oracle/' >> ~/.bashrc
#RUN sudo rm /usr/lib/jvm/default-java
RUN sudo ln -s /usr/lib/jvm/java-8-oracle /usr/lib/jvm/default-java


RUN /bin/bash -c "echo 'source ~/kinetic_ws/install/share/drcsim/setup.sh' >> ~/.bashrc"
RUN /bin/bash -c "echo 'source ~/kinetic_ws/devel/setup.bash' >> ~/.bashrc"
RUN /bin/bash -c "echo 'ulimit -s unlimited' >> ~/.bashrc"
RUN /bin/bash -c "echo 'ulimit -c unlimited'>> ~/.bashrc"
RUN /bin/bash -c "echo 'export JAVA_HOME=/usr/lib/jvm/java-8-oracle' >> ~/.bashrc"
RUN /bin/bash -c "echo 'export IHMC_SOURCE_LOCATION=$HOME/repository-group/ihmc-open-robotics-software'>> ~/.bashrc"

RUN /bin/bash -c "source /opt/ros/kinetic/setup.bash && \
  cd ~/kinetic_ws && catkin_make install"

RUN /bin/bash -c "source ~/.bashrc"


RUN sudo bash -c 'echo "@ros - rtprio 99" > /etc/security/limits.d/ros-rtprio.conf'
RUN sudo groupadd ros
RUN sudo usermod -a -G ros whrl

RUN cd && git clone https://github.com/ihmcrobotics/repository-group.git
RUN cd ~/repository-group && git clone https://github.com/WPI-Humanoid-Robotics-Lab/ihmc-open-robotics-software.git
RUN cd ~/repository-group/ihmc-open-robotics-software && git checkout gazebo_devel && ./gradlew

RUN /bin/bash -c 'source ~/.bashrc && export ROS_MASTER_URI=http://localhost:11311 && \
  export ROS_IP=127.0.0.1 && roslaunch ihmc_atlas_ros atlas_warmup_gradle_cache.launch'

RUN sudo bash -c "touch /etc/ld.so.conf.d/nvidia.conf"

RUN sudo bash -c 'echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf'
RUN sudo bash -c 'echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf'

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

#nvidia-384 installs lightdm that requires a keyboard input. To avoid that popup, copy an existing keyboard layout file
COPY ./keyboard /etc/default/keyboard
RUN sudo mkdir -p /usr/lib/nvidia/
RUN sudo apt-get -y update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y install nvidia-384

RUN sudo bash -c 'echo "org.gradle.jvmargs=-Xms4096m -Xmx4096m" > ~/.gradle/gradle.properties'
RUN sudo rm -rf /var/lib/apt/lists/
ARG ip
ENV IP=$ip
RUN echo "IP is ${IP}"
RUN /bin/bash -c "echo 'export ROS_MASTER_URI=http://${IP}:11311' >> ~/.bashrc"
RUN /bin/bash -c "echo 'export ROS_IP=${IP}' >> ~/.bashrc"                 

CMD /bin/bash -c 'source ~/.bashrc && roslaunch ihmc_atlas_ros ihmc_atlas_gazebo.launch gzname:="gzserver" '
