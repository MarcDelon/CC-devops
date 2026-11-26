#!/usr/bin/env bash
# Installe l'agent Jenkins dans la VM (service systemd "jenkins-agent").
# A lancer dans la VM :  sudo bash /vagrant/jenkins/install-agent.sh
set -euo pipefail

AGENT=vm-vagrant
WORKDIR=/home/vagrant/jenkins-agent
JENKINS_URL=http://localhost:8080

command -v java >/dev/null || { apt-get update -y && apt-get install -y openjdk-17-jre-headless; }

# 1. Script d'initialisation copie dans Jenkins, puis redemarrage de Jenkins
docker cp /vagrant/jenkins/init-cc-devops.groovy jenkins:/tmp/init-cc-devops.groovy
docker exec -u root jenkins sh -c 'mkdir -p /var/jenkins_home/init.groovy.d \
  && cp /tmp/init-cc-devops.groovy /var/jenkins_home/init.groovy.d/ \
  && chown -R jenkins:jenkins /var/jenkins_home/init.groovy.d'
docker restart jenkins
echo "Attente du redemarrage de Jenkins..."
until curl -fsS -o /dev/null "$JENKINS_URL/login"; do sleep 5; done
until docker exec jenkins test -s /var/jenkins_home/${AGENT}.secret; do sleep 3; done

# 2. Agent : agent.jar + secret
mkdir -p "$WORKDIR"
curl -fsSL "$JENKINS_URL/jnlpJars/agent.jar" -o "$WORKDIR/agent.jar"
docker exec jenkins cat /var/jenkins_home/${AGENT}.secret > "$WORKDIR/secret"
chmod 600 "$WORKDIR/secret"
chown -R vagrant:vagrant "$WORKDIR"

# 3. Service systemd (demarre avec la VM, redemarre en cas d'arret)
cat > /etc/systemd/system/jenkins-agent.service <<EOF
[Unit]
Description=Agent Jenkins ${AGENT} (Docker + Minikube + kubectl)
After=network-online.target docker.service
Wants=network-online.target

[Service]
User=vagrant
Group=vagrant
Environment=HOME=/home/vagrant
WorkingDirectory=${WORKDIR}
ExecStart=/usr/bin/java -jar ${WORKDIR}/agent.jar -url ${JENKINS_URL}/ -name ${AGENT} -secret @${WORKDIR}/secret -webSocket -workDir ${WORKDIR}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now jenkins-agent
sleep 10
systemctl --no-pager --lines=5 status jenkins-agent | sed -n 1,12p
