#!/bin/bash -x
# this is a modification of setup.sh for some debian environment
# you may need to run the presetup-debian13.sh

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
add-apt-repository -y ppa:redislabs/redis
apt-get update
apt-get install -y redis-server
curl -OL https://go.dev/dl/go1.17.8.linux-amd64.tar.gz
tar -C /usr/local -xvf go1.17.8.linux-amd64.tar.gz
rm go1.17.8.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/.bashrc
source $HOME/.bashrc

apt-get install -y build-essential cmake mosh htop zip libssl-dev pkg-config net-tools zlib1g-dev tmux
cd $HOME
git clone --recurse-submodules https://github.com/ut-osa/nightcore.git
cd $HOME/nightcore/deps/abseil-cpp
git checkout lts_2022_06_23
cd $HOME/nightcore
sed -i 's/-Werror//g' Makefile
./build_deps.sh
make -j4

cargo install oha
ulimit -n 8000
cd $HOME

PB_REL="https://github.com/protocolbuffers/protobuf/releases"
curl -LO $PB_REL/download/v3.15.8/protoc-3.15.8-linux-x86_64.zip
unzip protoc-3.15.8-linux-x86_64.zip -d /usr/local
rm protoc-3.15.8-linux-x86_64.zip

chmod 777 -R /usr/local/

git clone https://github.com/giltene/wrk2.git
cd wrk2
make -j4
cd ..

cd ccmesh
cargo build --release
cd ..

usermod -s /bin/bash $USER