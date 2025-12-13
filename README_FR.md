# K3s DietPi Ansible - Cluster Kubernetes Haute Disponibilité

[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![K3s](https://img.shields.io/badge/K3s-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![DietPi](https://img.shields.io/badge/DietPi-FF6B35?style=flat&logo=raspberrypi&logoColor=white)](https://dietpi.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

🇫🇷 **Version française** | [🇬🇧 English version](README.md)

Déploiement automatisé d'un cluster K3s haute disponibilité sur DietPi avec support IPv4/IPv6 dual-stack, load balancer externe, etcd dédié et solution de stockage intégrée avec Longhorn.

## 📋 Table des matières

- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Installation rapide](#-installation-rapide)
- [Configuration](#️-configuration)
- [Déploiement](#-déploiement)
- [Gestion du cluster](#️-gestion-du-cluster)
- [Dépannage](#-dépannage)
- [Contribuer](#-contribuer)

## 🏗️ Architecture

```
                    ┌─────────────────────┐
                    │   Load Balancer     │
                    │  (keepalived VIP)   │
                    │    172.18.0.2       │
                    │   HAProxy + etcd    │
                    └─────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
    ┌─────────▼─────────┐ ┌───▼────┐ ┌────────▼────────┐
    │   K3s Server 1    │ │Server 2│ │   K3s Server 3  │
    │  172.18.0.42      │ │.43     │ │  172.18.0.44    │
    │   (Control Plane) │ │        │ │                 │
    └───────────────────┘ └────────┘ └─────────────────┘
              │               │               │
              └───────────────┼───────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
          ┌─────────▼─────────┐ ┌───────▼─────────┐
          │   K3s Agent 1     │ │   K3s Agent 2   │
          │  172.18.0.45      │ │  172.18.0.46    │
          │    (Worker)       │ │    (Worker)     │
          └───────────────────┘ └─────────────────┘
```

### Composants

- **Load Balancer** : HAProxy + keepalived avec VIP pour haute disponibilité
- **etcd externe** : Base de données distribuée hébergée sur le load balancer
- **Serveurs K3s** : 3 nœuds control plane en mode HA
- **Agents K3s** : 2+ nœuds workers pour les workloads
- **Réseau dual-stack** : Support natif IPv4/IPv6
- **PureLB** : Load balancer intégré pour les services LoadBalancer
- **Traefik** : Contrôleur d'ingress (par défaut)
- **Longhorn** : Stockage distribué par bloc pour les volumes persistants

## 🔧 Prérequis

### Infrastructure

- **Machines** : 6+ machines DietPi (Raspberry Pi recommandé)
- **Réseau** : Réseau local avec IPs statiques configurées
- **Stockage** : Carte SD/SSD pour chaque nœud (32GB+ recommandé)

### Logiciels

```bash
# Sur la machine de contrôle
sudo apt update && sudo apt install -y python3-pip git
pip3 install ansible kubernetes

# Cloner le projet
git clone <votre-repo>
cd k3s-dietpi-ansible
```

### Collections Ansible

```bash
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install -r collections/requirements.yml
```

## 🚀 Installation rapide

### 1. Configuration des secrets

```bash
# Créer le fichier de secrets
cp .secret.example .secret
vi .secret

# Générer les secrets chiffrés
echo "votre-mot-de-passe-vault" > .vault
./scripts/setup_secrets.sh
```

### 2. Configuration de l'inventaire

Éditez `inventory.yml` avec vos IPs et adresses MAC :

```yaml
all:
  vars:
    gateway_address: 192.168.10.2  # Votre passerelle
  children:
    loadbalancer:
      children:
        loadbalancers:
          hosts:
            k3s-loadbalancer-01:
              ansible_host: 192.168.10.2
              # ... autres paramètres
```

### 3. Déploiement

```bash
# Test de connectivité
ansible all -m ping

# Déploiement complet
ansible-playbook playbooks/run.yml -i inventory.yml
```

## ⚙️ Configuration

### Variables principales

| Variable | Description | Défaut |
|----------|-------------|---------|
| `k3s_version` | Version de K3s | `v1.31.x+k3s1` |
| `keepalived_vip` | VIP du load balancer | `172.18.0.2` |
| `cluster_cidr` | CIDR des pods | `10.42.0.0/16` |
| `service_cidr` | CIDR des services | `10.43.0.0/16` |
| `api_port` | Port API Kubernetes | `6443` |

### Configuration réseau

Le projet supporte nativement :
- **IPv4** : `172.18.0.0/16` (personnalisable)
- **IPv6** : `fd42:f3f5:fe50::/56` (personnalisable)
- **Dual-stack** : Configuration automatique

### Secrets requis

Créez un fichier `.secret` avec :

```bash
# Authentification
export ANSIBLE_USER="votre-utilisateur"
export ANSIBLE_PASSWORD="mot-de-passe"

# Configuration K3s
export K3S_VERSION="v1.31.2+k3s1"
export K3S_TOKEN="$(openssl rand -base64 64)"
export K3S_API_PORT="6443"

# Autres paramètres
export TZ="Europe/Paris"
export KEEPALIVED_PASSWORD="mot-de-passe-keepalived"
```

## 🚀 Déploiement

### Playbooks disponibles

```bash
# Déploiement complet
ansible-playbook playbooks/run.yml -i inventory.yml

# Mise à jour du cluster k3s
ansible-playbook playbooks/upgrade.yml -i inventory.yml --tags k3s

# Mise à jour du cluster storage
ansible-playbook playbooks/upgrade.yml -i inventory.yml --tags storage

# Réinitialisation complète
ansible-playbook playbooks/reset.yml -i inventory.yml

# Synchronisation du cluster
ansible-playbook playbooks/sync.yml -i inventory.yml
```

### Déploiement par étapes

```bash
# 1. Préparation des nœuds DietPi
ansible-playbook playbooks/run.yml --tags dietpi -i inventory.yml

# 2. Configuration du load balancer
ansible-playbook playbooks/run.yml --tags loadbalancer -i inventory.yml

# 3. Déploiement des serveurs K3s
ansible-playbook playbooks/run.yml --tags k3s_server -i inventory.yml

# 4. Ajout des agents
ansible-playbook playbooks/run.yml --tags k3s_agent -i inventory.yml

# 5. Installation Helm et charts
ansible-playbook playbooks/run.yml --tags helm -i inventory.yml
```

## 🛠️ Gestion du cluster

### Accès au cluster

```bash
# Récupération du kubeconfig
scp k3s-server-01:~/.kube/config ~/.kube/config

# Test de connectivité
kubectl get nodes
kubectl get pods -A
```

### Commandes utiles

```bash
# Statut du cluster
kubectl cluster-info
kubectl get nodes -o wide

# Services LoadBalancer (PureLB)
kubectl get svc -A

# Exemple de déploiement avec LoadBalancer
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
kubectl expose deployment nginx-deployment --port=80 --type=LoadBalancer --name=nginx
kubectl annotate service nginx purelb.io/service-group=ipv4-routed
```

### Surveillance

```bash
# Logs des services système
sudo journalctl -u k3s -f
sudo journalctl -u k3s-agent -f

# Statut des nœuds
kubectl describe nodes
kubectl top nodes
```

## 🔧 Dépannage

### Problèmes courants

#### Le cluster ne démarre pas

```bash
# Vérifier les logs
sudo journalctl -u k3s -f

# Vérifier la connectivité etcd
sudo systemctl status etcd
curl -k https://172.18.0.2:2379/health
```

#### Problèmes réseau

```bash
# Vérifier la VIP keepalived
ip addr show eth0
ping 172.18.0.2

# Tester HAProxy
curl -k https://172.18.0.2:6443/version
```

#### Réinitialisation d'un nœud

```bash
# Sur le nœud défaillant
sudo /usr/local/bin/k3s-uninstall.sh  # ou k3s-agent-uninstall.sh

# Puis redéployer
ansible-playbook playbooks/run.yml --limit nœud-défaillant -i inventory.yml
```

### Commandes de diagnostic

```bash
# Test de connectivité réseau
ansible all -m ping

# Vérification des services
ansible all -m service -a "name=k3s state=started" -b

# Statut des certificats
ansible loadbalancer -m shell -a "ls -la /etc/etcd/ssl/" -b
```

## 📁 Structure du projet

```
k3s-dietpi-ansible/
├── ansible.cfg              # Configuration Ansible
├── inventory.yml           # Inventaire des machines
├── requirements.yml        # Collections Ansible requises
├── playbooks/
│   ├── run.yml            # Déploiement principal
│   ├── deployment.yml     # Déploiement de composants supplémentaires
│   ├── upgrade.yml        # Mise à jour
│   ├── reset.yml          # Réinitialisation
│   ├── sync.yml           # Synchronisation du cluster
│   └── test.yml           # Tests
├── roles/
│   ├── dietpi/             # Configuration DietPi
│   ├── load_balancer/      # HAProxy + keepalived
│   ├── etcd/               # Base de données etcd
│   ├── k3s_server/         # Serveurs K3s
│   ├── k3s_agent/          # Agents K3s
│   ├── k3s_upgrade/        # Procédures de mise à jour K3s
│   ├── deployment/         # Composants supplémentaires
│   └── helm/               # Gestionnaire de packages
├── group_vars/
│   ├── all/                # Variables globales
│   ├── servers.yml        # Variables serveurs
│   └── agents.yml         # Variables agents
├── host_vars/              # Variables par machine
└── scripts/
    ├── setup_secrets.sh    # Configuration des secrets
    └── clean.sh            # Nettoyage
```

## 🔐 Sécurité

- **Chiffrement Ansible Vault** pour tous les secrets
- **Certificats TLS** pour etcd et K3s
- **Durcissement SSH** automatique
- **Réseau privé** isolé pour le cluster

## � Scripts et utilitaires

### Scripts disponibles

Le projet inclut plusieurs scripts utilitaires dans le répertoire `scripts/` :

```bash
# Configuration des secrets et du vault
./scripts/setup_secrets.sh
```

### Gestion de la configuration

```bash
# Visualiser la configuration actuelle (chiffrée)
ansible-vault view group_vars/all/vault

# Éditer la configuration chiffrée
ansible-vault edit group_vars/all/vault

# Déchiffrer la configuration pour le débogage
ansible-vault decrypt group_vars/all/vault --output=-
```

## �🚀 Fonctionnalités avancées

### Stockage distribué Longhorn

Le cluster est livré avec Longhorn v1.9.1 pré-installé comme stockage distribué par bloc :

```bash
# Vérifier l'état de Longhorn
kubectl get pods -n longhorn-system

# Créer une revendication de volume persistant
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: longhorn
EOF

# Vérifier l'état du PVC
kubectl get pvc
```

### Déploiement de composants supplémentaires

Le playbook `deployment.yml` inclut des composants supplémentaires :

```bash
# Déployer les composants supplémentaires (PureLB, Traefik, Registry)
ansible-playbook playbooks/deployment.yml -i inventory.yml

# Déployer seulement des composants spécifiques
ansible-playbook playbooks/deployment.yml --tags purelb -i inventory.yml
ansible-playbook playbooks/deployment.yml --tags traefik -i inventory.yml
ansible-playbook playbooks/deployment.yml --tags registry -i inventory.yml
```

### Support IPv6 dual-stack

Le cluster est configuré nativement en dual-stack IPv4/IPv6 :

```yml
cluster_cidr: "10.42.0.0/16"
cluster_cidr_ipv6: "2001:db8:42::/56"
service_cidr: "10.43.0.0/16"
service_cidr_ipv6: "2001:db8:43::/112"
```

### Évolutivité

Ajout facile de nouveaux nœuds :

1. Ajouter le nouveau nœud dans `inventory.yml` sous le groupe approprié (servers ou agents)
2. Déployer le nouveau nœud : `ansible-playbook playbooks/run.yml --limit nom-nouveau-nœud -i inventory.yml`
3. Synchroniser la configuration du cluster : `ansible-playbook playbooks/sync.yml -i inventory.yml`

Exemple pour ajouter un nouvel agent :
```yaml
# Dans inventory.yml, ajouter sous le groupe agents
agents:
  hosts:
    k3s-agent-03:  # Nom de votre nouveau nœud
      ansible_host: 172.18.0.47
      # ... autres paramètres
```

Puis déployer :
```bash
# Déployer le nouveau nœud
ansible-playbook playbooks/run.yml --limit k3s-agent-03 -i inventory.yml

# Synchroniser la configuration du cluster
ansible-playbook playbooks/sync.yml -i inventory.yml
```

### Exemples d'utilisation avancée

#### Synchronisation sélective
```bash
# Mise à jour HAProxy seulement
ansible-playbook playbooks/sync.yml --tags update_haproxy -i inventory.yml

# Mise à jour des fichiers hosts seulement
ansible-playbook playbooks/sync.yml --tags update_hosts -i inventory.yml

# Affichage des informations du cluster seulement
ansible-playbook playbooks/sync.yml --tags cluster_info -i inventory.yml

# Mise à jour keepalived seulement
ansible-playbook playbooks/sync.yml --tags update_keepalived -i inventory.yml
```

#### Déploiement par composants
```bash
# Déploiement DietPi uniquement
ansible-playbook playbooks/run.yml --tags dietpi -i inventory.yml

# Configuration réseau uniquement
ansible-playbook playbooks/run.yml --tags network -i inventory.yml

# Installation Helm uniquement
ansible-playbook playbooks/run.yml --tags helm -i inventory.yml
```

#### Gestion par groupes
```bash
# Redémarrer tous les serveurs
ansible-playbook playbooks/run.yml --limit servers --tags restart -i inventory.yml

# Mettre à jour seulement les agents
ansible-playbook playbooks/run.yml --limit agents -i inventory.yml

# Configuration du load balancer uniquement
ansible-playbook playbooks/run.yml --limit loadbalancer -i inventory.yml
```

#### Diagnostic et maintenance
```bash
# Vérifier l'état de tous les nœuds
ansible all -m ping

# Vérifier les services K3s
ansible servers -m shell -a "systemctl status k3s" -b
ansible agents -m shell -a "systemctl status k3s-agent" -b

# Vérifier l'utilisation disque
ansible all -m shell -a "df -h" -b

# Redémarrer HAProxy sur le load balancer
ansible loadbalancer -m systemd -a "name=haproxy state=restarted" -b
```

### Surveillance et observabilité

Le cluster inclut des capacités de surveillance intégrées :

- **Node Exporter** : Métriques matériel et OS (port 9796)
- **Statistiques HAProxy** : Surveillance du load balancer (port 8404)
- **Métriques Calico** : Surveillance des performances réseau
- **Métriques K3s intégrées** : Surveillance de la santé du cluster

### Fonctionnalités de sécurité

- **TLS partout** : Chiffrement de bout en bout
- **Isolation réseau** : Réseau privé pour le cluster
- **Chiffrement Vault** : Tous les secrets protégés
- **Durcissement SSH** : Configuration de sécurité automatique

## 📖 Documentation supplémentaire

- [Configuration avancée de K3s](https://docs.k3s.io/)
- [Documentation HAProxy](https://www.haproxy.org/download/2.4/doc/configuration.txt)
- [Guide keepalived](https://www.keepalived.org/doc/)
- [PureLB Load Balancer](https://purelb.gitlab.io/docs/)

## 🤝 Contribuer

1. Forker le projet
2. Créer une branche feature (`git checkout -b feature/amelioration`)
3. Committer les changements (`git commit -am 'Ajout fonctionnalité'`)
4. Pusher la branche (`git push origin feature/amelioration`)
5. Créer une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👥 Auteurs

- **[Alain CAJUSTE](https://github.com/AC-CodeProd)** - *Développement initial*

## 🙏 Remerciements

- Équipe [K3s](https://k3s.io/) pour ce fantastique projet
- Communauté [DietPi](https://dietpi.com/) pour l'OS léger
- Équipe [Ansible](https://www.ansible.com/) chez Red Hat pour les outils d'automatisation
- Équipe [Calico](https://www.projectcalico.org/) pour le réseau
- Communautés [HAProxy](https://www.haproxy.org/) et [keepalived](https://www.keepalived.org/)

## 📊 Statistiques du projet

- **Infrastructure** : Cluster HA prêt pour la production
- **Sécurité** : Niveau entreprise avec chiffrement TLS
- **Surveillance** : Stack d'observabilité intégrée
- **Réseau** : Support dual-stack IPv4/IPv6
- **Automatisation** : 100% Infrastructure as Code
- **Stockage** : Stockage distribué par bloc avec Longhorn
- **Load Balancing** : PureLB intégré pour les services LoadBalancer

---

⭐ **N'hésitez pas à mettre une étoile si ce projet vous aide !**

*Dernière mise à jour : 2 septembre 2024*
