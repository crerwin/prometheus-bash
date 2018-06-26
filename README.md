wget -nc https://github.com/prometheus/prometheus/releases/download/v2.3.1/prometheus-2.3.1.linux-amd64.tar.gz
wget -nc https://github.com/prometheus/alertmanager/releases/download/v0.15.0/alertmanager-0.15.0.linux-amd64.tar.gz
wget -nc https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.1.4.linux-x64.tar.gz

set IPs in alertmanager.service and prometheus.yml overrides

`scp -r ./setup prometheus1:/tmp`
`ssh prometheus1`
`cd /tmp/setup`
`cp overrides/* configuration_files/`
`chmod u+x prometheus.sh`
`./prometheus.sh`
