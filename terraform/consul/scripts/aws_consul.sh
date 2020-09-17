#!/bin/bash

#metadata
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

#update packages
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

#install consul
sudo apt install consul -y

#config
cat <<EOF> /etc/consul.d/consul.json
{
  "datacenter": "aws-us-east-1",
  "primary_datacenter": "aws-us-east-1",
  "server": true,
  "bootstrap_expect": 1,
  "leave_on_terminate": true,
  "advertise_addr": "$${local_ipv4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "connect": {
    "enabled": true
  }
}
EOF

sudo systemctl enable consul.service
sudo systemctl start consul.service

exit 0
