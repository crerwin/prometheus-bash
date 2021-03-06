#!/bin/bash

sudo useradd prometheus
sudo useradd grafana

sudo mkdir /var/prometheus
sudo mkdir /opt/prometheus
sudo mkdir /opt/alertmanager
sudo mkdir /opt/grafana

sudo tar xkvfz tars/prometheus-2.3.1.linux-amd64.tar.gz -C /opt/prometheus --strip-components=1
sudo tar xkvfz tars/alertmanager-0.15.0.linux-amd64.tar.gz -C /opt/alertmanager --strip-components=1
sudo tar xkvfz tars/grafana-5.1.4.linux-x64.tar.gz -C /opt/grafana --strip-components=1

sudo chown -R prometheus:prometheus /var/prometheus /opt/prometheus /opt/alertmanager
sudo chown -R grafana:grafana /opt/grafana

sudo cp /tmp/setup/configuration_files/prometheus.service /etc/systemd/system/prometheus.service
sudo cp /tmp/setup/configuration_files/alertmanager.service /etc/systemd/system/alertmanager.service
sudo cp /tmp/setup/configuration_files/grafana.service /etc/systemd/system/grafana.service
sudo cp /tmp/setup/configuration_files/prometheus.yml /opt/prometheus/prometheus.yml
sudo cp /tmp/setup/configuration_files/prometheusalerts.yml /opt/prometheus/prometheusalerts.yml
sudo cp /tmp/setup/configuration_files/dcostargets.json /opt/prometheus/dcostargets.json
sudo cp /tmp/setup/configuration_files/alertmanager.yml /opt/alertmanager/alertmanager.yml
sudo cp /tmp/setup/configuration_files/dcosalerts.yml /opt/prometheus/dcosalerts.yml

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl start alertmanager
sudo systemctl enable alertmanager
sudo systemctl start grafana
sudo systemctl enable grafana
