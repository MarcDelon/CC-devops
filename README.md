# CC DevOps - Vagrant, Docker, GitHub Actions, Prometheus, Grafana

Projet de contrôle continu DevOps (Bachelor 3 IA & Big Data - Keyce Informatique).

## Objectif

- Créer une machine virtuelle Ubuntu 22.04 (Jammy) avec **Vagrant**.
- Déployer une application web qui tourne dans **Docker** dans la VM.
- Exposer l'application : accessible en tapant l'adresse IP (`http://<IP>:5111`).
- Mettre en place un processus **CI/CD avec GitHub Actions** : à chaque modification du code,
  l'application est reconstruite et le conteneur local est mis à jour automatiquement.
- Ajouter l'**observabilité** avec **Prometheus** et **Grafana**.

## Structure

```
.
|-- Vagrantfile              # définition de la VM et des provisioners
|-- provision.sh             # installe Docker et lance l'application (port 5111)
|-- app/                     # l'application : page HTML/CSS servie par Nginx
|   |-- Dockerfile
|   |-- index.html
|   `-- style.css
`-- ansible/                 # Ansible (lancé par Vagrant) : Minikube, Jenkins, Prometheus, Grafana
    |-- playbook.yml
    `-- files/
```

## Démarrer

```powershell
vagrant up          # crée la VM et installe tout
vagrant ssh         # se connecter à la VM
```

## Accès à l'application par adresse IP

Le `Vagrantfile` redirige le port 5111 de la VM vers le port 5111 de l'hôte, sur **toutes** ses
cartes réseau (`host_ip: "0.0.0.0"`) :

```ruby
config.vm.network "forwarded_port", guest: 5111, host: 5111, host_ip: "0.0.0.0"
```

L'application est donc accessible depuis n'importe quel appareil du même réseau en tapant
l'adresse IP du PC hôte : **http://192.168.1.175:5111** (adresse obtenue avec `ipconfig`).

## Observabilité (Prometheus + Grafana)

| Collecteur        | Ce qu'il mesure                                              | Job Prometheus |
|-------------------|--------------------------------------------------------------|----------------|
| blackbox-exporter | L'application : en ligne ?, code HTTP, temps de réponse      | `site`         |
| node-exporter     | La VM : CPU, RAM, disque, réseau                             | `node`         |
| cAdvisor          | Chaque conteneur Docker : CPU, RAM                           | `conteneurs`   |

Grafana charge automatiquement le tableau de bord **CC DevOps - Application et VM**
(`ansible/files/dashboard-cc-devops.json`, dossier « CC DevOps »).

Relancer uniquement la partie supervision dans la VM :

```bash
cd /vagrant/ansible && ansible-playbook -i localhost, -c local playbook.yml --tags monitoring
```

| Service     | Adresse                  |
|-------------|--------------------------|
| Application | http://localhost:5111 ou http://192.168.1.175:5111 |
| Prometheus  | http://localhost:9090    |
| Grafana     | http://localhost:3000    |
| Jenkins     | http://localhost:8080    |
