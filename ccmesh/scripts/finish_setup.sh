#!/bin/bash
python3 -m venv venv
source venv/bin/activate
pip3 install fabric
python3 upload.py
python3 setup.py

echo "Setup is normally done in all the topology."