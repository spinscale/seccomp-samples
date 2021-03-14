#!/bin/bash

sudo apt-get update
sudo apt-get install -y curl apt-transport-https

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
# we need curl here, because wget doesn't know the TLS cert
curl -sSL "https://keybase.io/crystal/pgp_keys.asc" | sudo apt-key add -

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
echo "deb https://dist.crystal-lang.org/apt crystal main" | sudo tee /etc/apt/sources.list.d/crystal.list
# backports are required for a newer libseccomp
echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee /etc/apt/sources.list.d/backports.list

sudo apt-get update 

STACK_VERSION=7.11.1

sudo apt-get install -y vim auditbeat=$STACK_VERSION elasticsearch=$STACK_VERSION kibana=$STACK_VERSION filebeat=$STACK_VERSION firejail strace crystal libssl-dev libxml2-dev libyaml-dev libgmp-dev libreadline-dev libz-dev auditd

sudo apt-get -t buster-backports install -y libseccomp2 libseccomp-dev seccomp python3-seccomp

sudo /bin/systemctl daemon-reload

# disable systemd so that auditbeat takes over
sudo systemctl disable auditd.service
sudo systemctl stop auditd.service

sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

echo "server.host: 0.0.0.0" | sudo tee -a /etc/kibana/kibana.yml

sudo systemctl enable kibana
sudo systemctl start kibana

echo "setup.dashboards.enabled: true" | sudo tee -a /etc/auditbeat/auditbeat.yml

sudo systemctl enable auditbeat
sudo systemctl start auditbeat
