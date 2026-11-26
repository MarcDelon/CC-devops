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

| Service     | Adresse                  |
|-------------|--------------------------|
| Application | http://localhost:5111    |
| Prometheus  | http://localhost:9090    |
| Grafana     | http://localhost:3000    |
| Jenkins     | http://localhost:8080    |
