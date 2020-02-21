#i /bin/bash

rm -rf ~/drcsim_docker
cd ~ && git clone https://github.com/WPI-Humanoid-Robotics-Lab/drcsim_docker.git

cd drcsim_docker 
git fetch && git checkout rbe-595

cd ~/kinetic_ws/src
wget https://github.com/WPI-Humanoid-Robotics-Lab/atlas_workspace/raw/master/atlas_gazebo_rbe595_ws.yaml
vcs import < atlas_gazebo_rbe595_ws.yaml
source /opt/ros/kinetic/setup.bash 
cd ~/kinetic_ws && catkin_make install

source ~/.bashrc
