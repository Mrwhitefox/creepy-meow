#! /bin/bash


# This script creates the UPPER PART of the funny network architecture as described below :
#
# LXC CONTAINER (CONTAINER ID X)
# +------------------------------------------+
# |containerX                                |
# |                                          |
# |   +---------------------+                |
# |   |brY                  |                |
# |   |      +-----------+  |  +---------+   |
# |   |      | vethcbr_X +-----+ vethc_X |   |
# |   |      +-----------+  |  +---------+   |
# |   |                     |                |         UPPER PART (without brY)
# +------------------------------------------+   ================================
#     |                     |                          LOWER PART (with brY)
#     |         +--------+  |  +------+
#     |         | VxlanY +-----+ eth1 |
#     |         +--------+  |  +------+
#     |brY                  |
#     +---------------------+
#      BRIDGE (VLAN ID Y)
#


if [ "$#" -ne 3 ]; then
  echo ""
  echo "Usage: $(basename $0) CONTAINER_ID CONTAINER_IP VXLAN_ID"
  echo "Creates a new container in a specific VXLAN."
  echo ""
  echo "CONTAINER_ID"
  echo "An unique ID for the created container"
  echo ""
  echo "CONTAINER_IP the IP address of eth0 inside the container"
  echo "e.g. 192.168.0.1/24"
  echo ""
  echo "VXLAN_ID the VXLAN ID."
  echo "Default : 2"
  echo ""
  exit 1
fi


CONTAINER_ID=$1
CONTAINER_IP=$2
VXLAN_ID=$3



echo "Create the container and run it"
lxc-create -n container$CONTAINER_ID -t ubuntu
lxc-start -n container$CONTAINER_ID -d

pid=$(lxc-info -pHn container$CONTAINER_ID)

ip link add name vethc_$CONTAINER_ID type veth peer name vethc_br$CONTAINER_ID #create a veth pair
brctl addif br$VXLAN_ID vethc_br$CONTAINER_ID #add vethc_br inside the bridge
ip link set up dev vethc_br$CONTAINER_ID

lxc-attach -n container$CONTAINER_ID -- sudo ip link del dev eth0 #remove default eth0 inside container

ip link set dev vethc_$CONTAINER_ID netns $pid name eth0 #create new eth0 inside container
lxc-attach -n container$CONTAINER_ID -- sudo ip link set up dev eth0

lxc-attach -n container$CONTAINER_ID -- sudo ip addr add $CONTAINER_IP dev eth0 #configure this new interface
