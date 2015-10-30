#curl -H "Content-Type application/json" \
#    -X POST -d '{"id":"1","vlan":"8","ip":"192.1968.1.1/24"}'\
#    http://datamancer/api/container/create 

curl --data "id=2&vlan=2&ip=255.168.1.252/21" \
    http://datamancer/api/container/create 
