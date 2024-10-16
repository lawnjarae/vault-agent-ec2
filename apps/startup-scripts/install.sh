#!/bin/bash

wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt install -y openjdk-21-jre
apt install -y vault
chmod +x /home/ubuntu/startup-scripts/run-demo.sh

cat <<EOM >/etc/systemd/system/brownfield-app.service
[Unit]
Description=Brownfield App
After=network.target
[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/startup-scripts
EnvironmentFile=/etc/profile
ExecStart=/home/ubuntu/startup-scripts/run-demo.sh
[Install]
WantedBy=multi-user.target
EOM

systemctl daemon-reload
systemctl enable brownfield-app.service
# systemctl start brownfield-app.service