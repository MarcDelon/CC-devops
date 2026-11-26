#!/usr/bin/env bash
# Provisioning : Docker + application web statique (HTML/CSS) servie par Nginx.
# L'application est publiée sur le port 5111 de la VM.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

APP_DIR=/vagrant/app
CONTAINER=static-web-app
PUBLIC_PORT=5111

# 1. Docker Engine si absent
if ! command -v docker >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg git
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
  usermod -aG docker vagrant
fi

# 2. Nettoyage de l'ancienne todo app ou anciens conteneurs
docker rm -f todo-app >/dev/null 2>&1 || true
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

# 3. Lancement du conteneur Nginx avec montage direct du dossier /vagrant/app (Live Reload)
docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p "$PUBLIC_PORT:80" \
  -v "$APP_DIR:/usr/share/nginx/html:ro" \
  nginx:alpine

docker ps --filter "name=$CONTAINER"

echo "============================================="
echo " Application Web HTML/CSS demarree (Live Reload actif)"
echo "  - Vos modifications dans app/ sont directes !"
echo "  - URL : http://localhost:$PUBLIC_PORT"
echo "============================================="
