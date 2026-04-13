#!/bin/bash
python3 -m venv venv
source venv/bin/activate
pip3 install fabric
python3 upload.py
python3 setup.py

rsvr=$(cat vms.tmp | cut -d "," -f 1)
ssh -o StrictHostKeyChecking=no root@$rsvr 'bash -s' < redis_setup.sh

echo "Setup is normally done in all the topology."