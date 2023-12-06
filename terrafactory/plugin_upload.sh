#!/bin/bash

if [ ! -e delphix-k8s-plugin.json ]; then
	wget https://artifactory.delphix.com:443/artifactory/HUBS/KUBERNETES_CSI_GATE/release/v1.0.0/delphix-k8s-plugin.json
fi

python3.8 -m pip install virtualenv
python3.8 -m virtualenv virtual

source virtual/bin/activate
pip install dvp==4.0.5
pip uninstall urllib3
pip install urllib3==1.26.6
dvp upload -e $1 -u admin --password delphix -a delphix-k8s-plugin.json

# DCT credentials 
rm -rf virtual
