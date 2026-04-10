#!/bin/bash -x
# this is a modification of setup.sh for some debian environment

# make sure it's up to date and install git, curl and rsync
apt-get update
apt-get install -y build-essential
apt-get install -y curl git rsync