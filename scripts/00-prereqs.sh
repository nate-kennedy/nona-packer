#! /bin/bash -ex

## Create user and group
addgroup --system minecraft
adduser --system \
    --home /opt/minecraft \
    --ingroup minecraft \
    --disabled-password \
    minecraft

## Get list of packages
add-apt-repository ppa:webupd8team/java
apt-get update && apt-get upgrade -y


## Install packages
sudo apt-get install -y wget gcc git python-pip openjdk-8-jdk

## Install python requirements
pip install boto3 mcstatus requests

# Get the latest Minecraft Server Artifact
if [ ! -e $SERVER_VERSION ]; then
  echo "Downloading spigot-$SERVER_VERSION.jar ..."
  wget -q https://cdn.getbukkit.org/spigot/spigot-$SERVER_VERSION.jar
fi

## Compile mcrcon
git clone https://github.com/Tiiffi/mcrcon.git
cd mcrcon
gcc -std=gnu11 -pedantic -Wall -Wextra -O2 -s -o mcrcon mcrcon.c
mv mcrcon /usr/bin
cd ..
rm -rf ./mcrcon

## Install BATS
git clone https://github.com/sstephenson/bats.git
cd bats
./install.sh /usr/local