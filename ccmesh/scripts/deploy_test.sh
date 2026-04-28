#!/bin/bash

if [ $# -lt 2 ]; then
	echo "usage: $0 <WS_DIR> <KEY_FILE>"
	exit 2
fi

ws_dir=$1
key_file=$2

echo "WS_DIR   -> $ws_dir"
echo "KEY_FILE -> $key_file"
# deploy the VMs
oarsub -t deploy -l /nodes=5,walltime=5:00:00 -p "host like 'big%'" \
'kadeploy3 -f /tmp/deploynodes.${OAR_JOBID} --env-name debian12 -k /home/leon/.ssh/id_rsa.pub && while true; do sleep 1; done'

# recover VMs info
vms=$(oarstat -u -f | grep assigned_hostnames | cut -d "=" -f 2)
vms="${vms#[[:space:]]}"
vms="${vms%[[:space:]]}"

echo "Waiting for hostnames ..."

while [[ ${#vms} -lt 2 ]]; do
	sleep 37
	vms=$(oarstat -u -f | grep assigned_hostnames | cut -d "=" -f 2)
	vms="${vms#[[:space:]]}"
	vms="${vms%[[:space:]]}"
done

echo "Hostnames: $vms"
echo "Waiting for hostnames to boot..."
sleep 33
vms=$(echo $vms | sed s/\+/,\ /g)

# wait for ssh
while [[ $gtfo -lt 5 ]]; do
	echo "attempting to connect with $vms..."
	gtfo=0
	declare -A ready

	for vm in ${vms//,/}; do
		echo -n "Trying $vm... "

		if nc -z $vm 22; then
			ready[$vm]=1
			echo "ok!"
		else
			ready[$vm]=0
			echo "error"
		fi
	done

	for vm in ${vms//,/}; do
		gtfo=$(( gtfo + ${ready[$vm]} ))
	done

	if [[ $gtfo -lt 5 ]]; then
		echo "servers are not ready."
		echo "Sleepping..."
		sleep 37
	else
		echo "server ready"
		continue
	fi

	echo "Retrying..."
	vms=$(oarstat -u -f | grep assigned_hostnames | cut -d "=" -f 2)
	vms="${vms#[[:space:]]}"
	vms="${vms%[[:space:]]}"
	vms=$(echo $vms | sed s/\+/,\ /g)
done

echo "Saving hosts in vms.tmp"
echo $vms > vms.tmp

# craft the common.py
echo "crafting common.py and config/cloud.json..."
cp common.py.base common.py
sed -i "s/WS_DIR_LOC/${ws_dir//\//\\/}/g" common.py
sed -i "s/KEY_FILE_LOC/${key_file//\//\\/}/g" common.py
sed -i "s/SUPERSERVERS/'${vms//, /\', \'}'/g" common.py

# craft the json file
cp $ws_dir/ccmesh/config/cloud.json.old $ws_dir/ccmesh/config/cloud.json
sed -i "s/SUPERSERVERS/\"${vms//, /\", \"}\"/g" $ws_dir/ccmesh/config/cloud.json
rsrvr=$(echo $vms | cut -d "," -f 1)
sed -i "s/REDISSERVER/$rsrvr/g" $ws_dir/ccmesh/config/cloud.json
cp $ws_dir/ccmesh-go/pkg/base/client.go.old $ws_dir/ccmesh-go/pkg/base/client.go
sed -i "s/REDISSERVER/$rsrvr/g" $ws_dir/ccmesh-go/pkg/base/client.go
rm $HOME/.ssh/known_hosts # fuck it

# presetup script
for vm in ${vms//,/}; do
	echo "running presetup script in $vm"
	ssh -o StrictHostKeyChecking=no root@$vm 'bash -s' < $ws_dir/ccmesh/scripts/presetup-debian12.sh
done

echo "everything is ready. Get a node and execute 'bash finish_setup.sh'" 

