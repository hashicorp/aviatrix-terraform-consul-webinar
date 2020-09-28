#!/bin/bash

#metadata
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

#update packages
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update -y

#install consul
sudo apt install consul -y

#config
cat <<EOF> /etc/consul.d/consul.json
{
  "datacenter": "aws-us-east-1",
  "primary_datacenter": "aws-us-east-1",
  "advertise_addr": "$${local_ipv4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "retry_join": ["provider=aws tag_key=Env tag_value=consul-${env}"],
  "ui": true,
  "connect": {
    "enabled": true
  }
}
EOF

cat <<-EOF > /etc/consul.d/jaeger_service.json
{
  "service": {
    "name": "jaeger",
    "port": 16686,
    "tags": [
      "monitoring"
    ],
    "check": {
      "id": "jaeger",
      "name": "Jaeger TCP on port 16686",
      "tcp": "localhost:16686",
      "interval": "5s",
      "timeout": "3s"
    }
  }
}
EOF

sudo systemctl enable consul.service
sudo systemctl start consul.service
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
#
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

cat <<-EOF > /docker-compose.yml
version: '3'
services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    network_mode: "host"
    environment:
     - COLLECTOR_ZIPKIN_HTTP_PORT=9411
EOF
/usr/local/bin/docker-compose up -d

sudo systemctl enable consul.service
sudo systemctl start consul.service

exit 0
