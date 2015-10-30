# creepy-meow
No bullshit.


## Core
The core fatures are handled by bash scripts (do not forget to `chmod u+x`).

They must be executed by the root user.
These are :

### startup.sh
This script should be run once on each boot, for instance you can add it on /etc/rc.local script.

It will create 3 vxlans interfaces vxlan2, vxlan3, vxlan4 ; each associated on bridgeX (X = same number as the vxlan ID)
(see the ascii figure inside the script)

All the vxlans are created on eth1.

You must give an unique ID between 1 and 254 (both included), that will be the last byte of the IP address in the eth1 network.
Each server must have its own ID.
	./startup.sh 1 # on server1
	./startup.sh 2 # on server1

### create_container.sh
This script must be called each time you want to create a new ubuntu container.
It will replace its standard eth0, by create a veth pair for the container, and link it to the correct bridge (according to the vxlan ID).
(see the ascii figure inside the script)
Example :
	./create_container.sh 66 192.168.0.1/24 2

All the containers will be named `containerX`, with X the container ID.


## The API
The API is made with Pyramid (a Python framework).

### Installation

The script "startup.sh" should be copied into /root folder ; and must be started on each boot.
This can be done by adding it into /etc/rc.local

Note : The installation with easy_install may fail with IPv6 only. It might need an IPv4 address. Though, IPv4 is not required once everything is installed.

	sudo easy_install virtualenv
	virtualenv env
	cd env
	source bin/activate
	bin/easy_install pyramid
	bin/easy_install waitress
	git clone https://github.com/Mrwhitefox/creepy-meow.git virtapi
	cd virtapi
	source ../bin/activate
	../bin/python setup.py develop
	sudo su
	source ../bin/activate
	pserve production.ini #this will run the API

How to run the API once it has been stopped:
	sudo su
	cd env/virtapi
	source ../bin/activate
	pserve production.ini

*Note:* This is important to run the API **with root privileges**, because the script `create_container.sh` needs superuser privileges in order to create the network interfaces. Even if it's quite dirty...

You can also use `pserve development.ini` for an integrated debugger. It is **highly** discouraged to use the development.ini on production servers, because of security implications.


#### Usage

**BONUS!** Get a list of all running containers / GET method:

`http://server-address/api/container/list`

**BONUS!** Get info about a specific container (with ID = X) / GET method:

`http://server-address/api/container/info/X`

Create a new container / POST method:

`http://server-address/api/container/create`

You must specify these variables (in the POST method) to create the container :
	id: the id of the container. This ID must not be already in use (even with a stopped container)
	ip: the IP address of the container, with the subnet. e.g. 192.168.1.1/24
	vlan: the VLAN ID. You can choose among : 2, 3, 4
	
Here is a curl command to test it:

	curl --data "id=5&vlan=2&ip=192.168.2.5/24" http://server-address/api/container/create 

This will try to create the container ID 5 on VLAN 2 with IP 192.168.2.5/24.


