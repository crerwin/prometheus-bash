#!/bin/bash

sudo useradd prometheus
sudo useradd grafana

sudo mkdir /var/prometheus
sudo mkdir /opt/prometheus
sudo mkdir /opt/alertmanager
sudo mkdir /opt/grafana

sudo yum install -y wget

wget -nc https://github.com/prometheus/prometheus/releases/download/v2.3.1/prometheus-2.3.1.linux-amd64.tar.gz
wget -nc https://github.com/prometheus/alertmanager/releases/download/v0.15.0/alertmanager-0.15.0.linux-amd64.tar.gz
wget -nc https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.1.4.linux-x64.tar.gz

sudo tar xvfz prometheus-2.3.1.linux-amd64.tar.gz -C /opt/prometheus --strip-components=1
sudo tar xvfz alertmanager-0.15.0.linux-amd64.tar.gz -C /opt/alertmanager --strip-components=1
sudo tar xvfz grafana-5.1.4.linux-x64.tar.gz -C /opt/grafana --strip-components=1


sudo chown -R prometheus:prometheus /var/prometheus /opt/prometheus /opt/alertmanager
sudo chown -R grafana:grafana /opt/grafana

sudo tee /etc/systemd/system/prometheus.service <<- EOF
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target
[Service]
User=prometheus
Restart=on-failure
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/var/prometheus
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/alertmanager.service <<- EOF
[Unit]
Description=AlertManager
After=network-online.target
[Service]
User=prometheus
Restart=on-failure
ExecStart=/opt/alertmanager/alertmanager --config.file=/opt/alertmanager/alertmanager.yml
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/grafana.service <<- EOF
[Unit]
Description=Grafana Server
After=network-online.target
[Service]
User=grafana
Restart=on-failure
WorkingDirectory=/opt/grafana
ExecStart=/opt/grafana/bin/grafana-server web
[Install]
WantedBy=multi-user.target
EOF

sudo tee /opt/prometheus/prometheus.yml <<- EOF
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.

rule_files:
  - "prometheusalerts.yml"
  - "dcosalerts.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']
  - job_name: 'dcos'
    file_sd_configs:
      - files:
        - dcostargets.json
EOF

sudo tee /opt/alertmanager/alertmanager.yml <<- EOF
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF

sudo tee /opt/prometheus/dcostargets.json <<- EOF
[
  {
    "targets": ["masterips:61091", "nodeips:61091"],
    "labels": {
      "job": "dcos-metrics"
    }
  },
  {
    "targets": [ "masterips:9105", "nodeips:9105" ],
    "labels": {
      "job": "mesos-metrics"
    }
  },
  {
    "targets": [ "masterips:9088" ],
    "labels": {
      "job": "marathon-metrics"
    }
  }
]
EOF

sudo tee /opt/prometheus/prometheusalerts.yml <<- EOF
groups:
 - name: Prometheus
   rules:
   - alert: TargetDown
     expr: avg(up) BY (job) < 1
     for: 1m
     labels:
       severity: warning
     annotations:
       description: '{{$labels.job}} target down'
       summary: 'target down'
EOF
sudo touch /opt/prometheus/dcosalerts.yml

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl start alertmanager
sudo systemctl enable alertmanager
sudo systemctl start grafana
sudo systemctl enable grafana
