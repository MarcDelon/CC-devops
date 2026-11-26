# -*- mode: ruby -*-
# VM Ubuntu 22.04 (Jammy) : Docker + Web App (HTML/CSS), puis Ansible qui installe
# Minikube (Kubernetes), kubectl, Jenkins, Prometheus et Grafana.

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.hostname = "jammy-docker"

  # IP privée fixe desactivee : le pilote "Host-Only" de VirtualBox n'est pas installe
  # sur ce Windows (erreur "Failed to create the host-only adapter").
  # config.vm.network "private_network", ip: "192.168.56.10"

  # Ports exposés vers Windows
  # Application (0.0.0.0 = accessible depuis le réseau local, par l'IP du PC)
  #   5111 : version déployée par GitHub Actions (conteneur Docker)
  #   5112 : version déployée par Jenkins sur Kubernetes (Minikube)
  config.vm.network "forwarded_port", guest: 5111, host: 5111, host_ip: "0.0.0.0", auto_correct: false
  config.vm.network "forwarded_port", guest: 5112, host: 5112, host_ip: "0.0.0.0", auto_correct: false
  config.vm.network "forwarded_port", guest: 8080, host: 8080   # Jenkins
  config.vm.network "forwarded_port", guest: 9090, host: 9090   # Prometheus
  config.vm.network "forwarded_port", guest: 3000, host: 3000   # Grafana

  # Le dossier du projet est monte dans la VM sur /vagrant
  config.vm.synced_folder ".", "/vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "jammy-docker"
    # 4 Go : Minikube (~2 Go) + Jenkins + Prometheus + Grafana + todo-list
    vb.memory = 4096
    # Ouvre automatiquement la fenetre VirtualBox au "vagrant up" (console texte, pas de bureau)
    vb.gui = true
    # 1 seul CPU : Hyper-V est actif sur l'hote (Docker Desktop/WSL2), VirtualBox
    # tourne alors en mode NEM et bloque au boot avec plusieurs CPU.
    vb.cpus = 1
  end

  # Le mode NEM est plus lent : on laisse plus de temps au premier demarrage
  config.vm.boot_timeout = 900

  # Message de bienvenue lors du premier démarrage (provisioning)
  config.vm.provision "shell", inline: <<-SHELL
    echo "============================================="
    echo " VM Ubuntu prête et accessible via SSH !"
    echo " Système : $(lsb_release -ds 2>/dev/null || uname -s)"
    echo "============================================="
  SHELL

  # 1) Docker + todo-list dans un conteneur (port 5111)
  config.vm.provision "shell", path: "provision.sh"

  # 2) Ansible : Vagrant installe Ansible DANS la VM puis execute le playbook
  #    -> Minikube + kubectl, Jenkins, Prometheus, Grafana
  config.vm.provision "devops", type: "ansible_local" do |ansible|
    ansible.provisioning_path = "/vagrant/ansible"
    ansible.playbook          = "playbook.yml"
    ansible.install_mode      = "default"   # paquet apt (PPA officiel Ansible)
    ansible.verbose           = false
  end
end
