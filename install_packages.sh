#! /bin/bash -ex

apt-get update -qq
apt-get install jq python-pip

pip install awscli

if [ -x "$(command -v packer)" ]; then
  echo 'Packer is already installed'
  exit 0
fi

apt-get install jq unzip wget 

packer_url=$(curl https://releases.hashicorp.com/index.json | jq '{packer}' | egrep "linux.*amd64" | sort --version-sort -r | head -1 | awk -F'[\"]' '{print $4}')

echo "Downloading $packer_url."
curl -o packer.zip $packer_url
# Unzip and install
unzip packer.zip
mv packer /usr/local/bin/
