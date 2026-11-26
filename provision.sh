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

# DNS des conteneurs : celui de la box Wi-Fi (192.168.1.1) n'est pas joignable depuis
# la VM, on utilise le DNS de VirtualBox (10.0.2.3) et un DNS public.
# live-restore : les conteneurs continuent de tourner pendant un redemarrage de Docker.
if ! grep -q '"live-restore"' /etc/docker/daemon.json 2>/dev/null; then
  echo '{"dns": ["10.0.2.3", "1.1.1.1"], "live-restore": true}' > /etc/docker/daemon.json
  systemctl restart docker
fi

# 2. Nettoyage de l'ancienne todo app ou anciens conteneurs
docker rm -f todo-app >/dev/null 2>&1 || true
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

# 3. Construction de l'image Docker de l'application (app/Dockerfile)
#    Meme methode que le job CD de GitHub Actions : l'image est figee,
#    une modification du code n'est visible qu'apres un nouveau deploiement.
docker build -t cc-devops-app:latest "$APP_DIR"

# 4. Lancement du conteneur
docker run -d   --name "$CONTAINER"   --restart unless-stopped   -p "$PUBLIC_PORT:8000"   cc-devops-app:latest

docker ps --filter "name=$CONTAINER"

echo "============================================="
echo " Application Web HTML/CSS demarree"
echo "  - Mises a jour automatiques : git push -> GitHub Actions"
echo "  - URL : http://localhost:$PUBLIC_PORT"
echo "============================================="
