from pyramid.view import view_config
import subprocess
import re

@view_config(route_name='home', renderer='templates/mytemplate.pt')
def my_view(request):
    return {'project': 'virtapi'}

def get_containers_id():
    res = subprocess.check_output(['lxc-ls'])
    #return only the ID of containers named 'containerID'
    return [int(el.replace("container", "")) for el in res.split() if "container" in el]

@view_config(route_name='api_container_list', renderer='json')
def api_container_list(request):
    return {"containers_id":get_containers_id()}

@view_config(route_name='api_container_info', renderer='json')
def api_container_info(request):
    res = subprocess.check_output(['lxc-info', '-n', 'container'+request.matchdict['id']])
    #res = subprocess.check_output(['cat', 'test'])
    return dict([map(lambda x: x.strip(), line.split(":", 1)) for line in res.split("\n") if line != ''])


@view_config(route_name='api_container_create', renderer='json')
def api_container_create(request):

    if request.method != "POST":
        request.response.status = 500
        return{"errors":"This should have been a POST request"}

    #check all args are in POST request
    required_args = ['id', 'vlan', 'ip']
    if not all([arg in required_args for arg in request.POST.keys()]):
        request.response.status = 500
        return{"errors":"All arguments are not supplied", "required_args": required_args, "supplied_args": request.POST.keys()}

    cont_id = int(request.POST['id'])
    if cont_id in get_containers_id():
        request.response.status = 500
        return {'errors': 'This ID cannot be allocated. Please chose another one.'}

    cont_vlan = int(request.POST['vlan'])
    valid_vlans = [1,2,3]
    if not cont_vlan in valid_vlans:
        request.response.status = 500
        return {'errors': 'This is not a valid VLAN id.', "valid_vlans": valid_vlans, "supplied_vlan":request.POST['vlan']}
    
    cont_ip = request.POST['ip']
    #ex. 192.168.1.1/24
    # will not allow things like 999.999.999/42 
    valid_pattern = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/(3[0-2]|[12][0-9]|0?[1-9])$"
    if not re.match(valid_pattern, cont_ip):
        request.response.status = 500
        return{'errors': 'This is not a valid IP pattern.', 'valid_pattern':valid_pattern}

    container_create(cont_id, cont_vlan, cont_ip)
    return{'result':True, 'id':cont_id, 'vlan':cont_vlan, 'ip':cont_ip}

def container_create(cont_id, cont_vlan, cont_ip):
    res = subprocess.check_output(['./create_container.sh', str(cont_id), cont_ip, str(cont_vlan)])

