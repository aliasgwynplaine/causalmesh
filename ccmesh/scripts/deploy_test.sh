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
'kadeploy3 -f /tmp/deploynodes.${OAR_JOBID} --env-name debian13 -k /home/leon/.ssh/id_rsa.pub && while true; do sleep 1; done'

# recover VMs info
vms=$(oarstat -u -f | grep assigned_hostnames | cut -d "=" -f 2)
vms="${vms#[[:space:]]}"
vms="${vms%[[:space:]]}"

echo "Waiting for hostnames ..."

while [[ ${#vms} -lt 2 ]]; do
	sleep 27
	vms=$(oarstat -u -f | grep assigned_hostnames | cut -d "=" -f 2)
	vms="${vms#[[:space:]]}"
	vms="${vms%[[:space:]]}"
done

echo "done"
vms=$(echo $vms | sed s/\+/,\ /g)
echo $vms > vms.tmp

# craft the common.py
cp common.py.base common.py
sed -i "s/WS_DIR_LOC/${ws_dir//\//\\/}/g" common.py
sed -i "s/KEY_FILE_LOC/${key_file//\//\\/}/g" common.py
sed -i "s/SUPERSERVERS/'${vms//, /\', \'}'/g" common.py

echo "attempting to connect with $vms..."

# wait for ssh
for vm in ${$vms//,/}; do
        while ! nc -z $vm 22; do
                sleep 37
        done

        echo "one more verification..."
        sleep 17

        while ! nc -z $vm 22; do
                sleep 41
        done

        echo "$vm is online"
done

# presetup script
for vm in ${$vms//,/}; do
        echo "running presetup script in $vm"
	ssh -o StrictHostKeyChecking=no root@$vm 'bash -s' < $ws_dir/ccmesh/scripts/presetup-debian13.sh
done

print("everything is ready. Get a node and execute 'python3 finish_setup.py'")

