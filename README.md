##  Installation

### 1. Cloner le projet et ouvrir un Codespace

Forkez ce repository puis ouvrez un **GitHub Codespace** depuis l'onglet `[CODE]`.

### 2. Installer les dépendances

```bash
# Ansible
sudo apt-get update -y && sudo apt-get install -y ansible

# Packer
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update -y && sudo apt-get install -y packer
```

---

##  Séquence 1 & 2 : Cluster K3d

### Installer K3d et créer le cluster

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

k3d cluster create lab \
  --servers 1 \
  --agents 2
```

### Vérifier le cluster

```bash
kubectl get nodes
```

---

##  Séquence 3 : Build et déploiement

### Étape 1 — Build de l'image avec Packer

Packer va prendre l'image de base `nginx:alpine`, y copier le fichier `index.html` et créer une nouvelle image Docker `nginx-custom:latest`.

```bash
packer init packer/nginx.pkr.hcl
packer build packer/nginx.pkr.hcl
```

### Étape 2 — Import de l'image dans K3d

K3d tourne dans Docker, il faut donc importer l'image localement dans le cluster :

```bash
k3d image import nginx-custom:latest -c lab
```

### Étape 3 — Déploiement via Ansible

Le playbook Ansible applique les manifests Kubernetes et attend que le déploiement soit prêt :

```bash
ansible-playbook ansible/playbook.yml
```

### Étape 4 — Accès à l'application

```bash
kubectl port-forward svc/nginx-custom 8081:80 >/tmp/nginx-custom.log 2>&1 &
```

Puis dans l'onglet **PORTS** de votre Codespace, rendez le port **8081** public et ouvrez l'URL.

---

##  Automatisation avec le Makefile

Toutes les étapes peuvent être exécutées en une seule commande :

```bash
make all
```

Ou étape par étape :

| Commande | Description |
|---|---|
| `make build` | Build l'image Docker avec Packer |
| `make import` | Importe l'image dans K3d |
| `make deploy` | Déploie via Ansible |
| `make forward` | Expose le port 8081 |


---

##  Structure du projet
Image_to_Cluster/
├── packer/
│   └── nginx.pkr.hcl       # Configuration Packer
├── ansible/
│   └── playbook.yml         # Playbook de déploiement
├── k8s/
│   ├── deployment.yml       # Deployment Kubernetes
│   └── service.yml          # Service Kubernetes
├── index.html               # Page web déployée
├── Makefile                 # Automatisation
└── README.md                # Documentation

---
