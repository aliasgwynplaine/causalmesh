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
oarsub -t deploy # ...

# wait for ssh service

# recover VMs info
vms=$(oarstat -u -f | grep assigned_hostnames | cut -d "=" -f 2)

# craft the common.py
cp common.py.base common.py
sed -i "s/WS_DIR_LOC/$ws_dir/g" common.py
sed -i "s/KEY_FILE_LOC/$key_file/g" common.py
sed -i "s/SUPERSERVERS/$vms/g" common.py

# execute upload.py and setup.py
python3 upload.py
python3 setup.py


