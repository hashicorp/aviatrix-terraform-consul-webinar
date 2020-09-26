#!/bin/bash

#metadata
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

#update packages
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update -y

#install consul
sudo apt install consul dnsmasq -y

sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
sudo echo "server=/consul/127.0.0.1#8600" > /etc/dnsmasq.d/10-consul
sudo service dnsmasq restart

#config
cat <<EOF> /etc/consul.d/consul.json
{
  "datacenter": "aws-us-east-1",
  "primary_datacenter": "aws-us-east-1",
  "advertise_addr": "$${local_ipv4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "join": ["provider=aws tag_key=Env tag_value=consul-${env}"]
  "ui": true,
  "connect": {
    "enabled": true
  }
}
EOF

cat <<-EOF > /etc/consul.d/grafana_service.json
{
  "service": {
    "name": "grafana",
    "port": 3000,
    "tags": [
      "monitoring"
    ],
    "check": {
      "id": "grafana",
      "name": "Grafana TCP on port 3000",
      "tcp": "localhost:3000",
      "interval": "5s",
      "timeout": "3s"
    }
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

sudo mkdir -p  /etc/prometheus/
cat <<-'EOF' > /etc/prometheus/prometheus.yml
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'
    scrape_interval: 15s

    honor_labels: true
    metrics_path: '/federate'

    params:
      'match[]':
        - '{job="kubernetes-pods"}'

    static_configs:
    - targets:
      - prometheus-server-default.service.azure-us-west.consul:9090
      - prometheus-server-default.service.aws-us-east-1.consul:9090
EOF

cat <<-EOF > /docker-compose.yml
version: '3'
services:
  grafana:
    network_mode: "host"
    image: "grafana/grafana"
    restart: always
  jaeger:
    image: jaegertracing/all-in-one:latest
    network_mode: "host"
    environment:
     - COLLECTOR_ZIPKIN_HTTP_PORT=9411
  prometheus:
    image: prom/prometheus:v2.6.1
    network_mode: "host"
    volumes:
      - /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - /etc/resolv.conf:/etc/resolv.conf
EOF

/usr/local/bin/docker-compose up -d


exit 0
