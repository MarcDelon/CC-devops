#!/usr/bin/env bash
# Expose l'application Kubernetes sur le port 5112 de la VM (puis de Windows via Vagrant).
#   navigateur -> Windows:5112 -> VM:5112 -> socat -> Minikube (NodePort 30080) -> pods
# A lancer dans la VM :  sudo bash /vagrant/k8s/expose-app.sh
set -euo pipefail

command -v socat >/dev/null || { apt-get update -y && apt-get install -y socat; }

cat > /etc/systemd/system/k8s-app-proxy.service <<'EOF'
[Unit]
Description=Expose l'application Kubernetes (NodePort 30080) sur le port 5112
After=docker.service
Wants=docker.service

[Service]
User=vagrant
Environment=HOME=/home/vagrant
# l'IP de Minikube est relue a chaque demarrage
ExecStart=/bin/bash -c 'exec socat TCP-LISTEN:5112,fork,reuseaddr TCP:$(minikube ip):30080'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now k8s-app-proxy
systemctl --no-pager status k8s-app-proxy | sed -n 1,4p
