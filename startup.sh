#! /bin/bash


#This script creates a funny network architecture as described below :
#
# LXC CONTAINER
# +-----------------------------------+
# |container1                         |
# |                                   |
# |   +-----------------+             |
# |   |br0              |             |
# |   |      +-------+  |  +------+   |
# |   |      | Veth0 +-----+ eth0 |   |
# |   |      +-------+  |  +------+   |
# |   |                 |             |
# +-----------------------------------+
#     |                 |
#     |     +--------+  |  +------+
#     |     | Vxlan1 +-----+ eth1 |
#     |     +--------+  |  +------+
#     |br0              |
#     +-----------------+
#      BRIDGE
#


if [ "$#" -ne 1 ]; then
  echo ""
  echo "Usage: $(basename $0) VXLAN_IP"
  echo "Creates the architecture for 3 vlans: vlan2, vlan3 vlan4."
  echo ""
  echo ""
  echo "VXLAN_IP the last byte of the IP address of the vxlan interface inside the host"
  echo "e.g. 192.168.10.XXX/24"
  exit 1
fi

VXLAN_IP=$1


echo "Enabling vxlan module"
modprobe vxlan


apt-get update
echo "Installing lxc"
apt-get install lxc -y

echo "installing bridge-utils"
apt-get install bridge-utils -y


for id in 2 3 4; do

  echo "Create VXLAN"
  ip link add vxlan$id type vxlan id $id group 239.0.0.$id dev eth1
  ip link set up dev vxlan$id
  ip addr add 192.168.${id}.$VXLAN_IP/24 dev vxlan$id

  echo "Create the bridge"
  brctl addbr br$id
  brctl addif br$id vxlan$id
  ip link set up dev br$id

done
