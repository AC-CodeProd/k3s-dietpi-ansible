# K3s DietPi Ansible - High Availability Kubernetes Cluster

[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![K3s](https://img.shields.io/badge/K3s-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![DietPi](https://img.shields.io/badge/DietPi-FF6B35?style=flat&logo=raspberrypi&logoColor=white)](https://dietpi.com/)

🇬🇧 **English version** | [🇫🇷 Version française](README_FR.md)

Automated deployment of a high-availability K3s cluster on DietPi with IPv4/IPv6 dual-stack support, external load balancer and dedicated etcd.

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration](#️-configuration)
- [Deployment](#-deployment)
- [Cluster Management](#️-cluster-management)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## 🏗️ Architecture

```
                    ┌─────────────────────┐
                    │   Load Balancer     │
                    │  (keepalived VIP)   │
                    │    172.18.0.2      │
                    │   HAProxy + etcd    │
                    └─────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
    ┌─────────▼─────────┐ ┌───▼────┐ ┌───────▼─────────┐
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

### Components

- **Load Balancer**: HAProxy + keepalived with VIP for high availability
- **External etcd**: Distributed database hosted on the load balancer
- **K3s Servers**: 3 control plane nodes in HA mode
- **K3s Agents**: 2+ worker nodes for workloads
- **Dual-stack Network**: Native IPv4/IPv6 support
- **PureLB**: Integrated load balancer for LoadBalancer services
- **Traefik**: Ingress controller (optional)

## 🔧 Prerequisites

### Infrastructure

- **Machines**: 6+ DietPi machines (Raspberry Pi recommended)
- **Network**: Local network with static IPs configured
- **Storage**: SD card/SSD for each node (32GB+ recommended)

### Software

```bash
# On the control machine
sudo apt update && sudo apt install -y python3-pip git
pip3 install ansible kubernetes

# Clone the project
git clone <your-repo>
cd k3s-dietpi-ansible
```

### Ansible Collections

```bash
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install -r collections/requirements.yml
```

## 🚀 Quick Start

### 1. Secrets Configuration

```bash
# Create the secrets file
cp .secret.example .secret
vi .secret

# Generate encrypted secrets
echo "your-vault-password" > .vault
./scripts/setup_secrets.sh
```

### 2. Inventory Configuration

Edit `inventory.yml` with your IPs and MAC addresses:

```yml
all:
  vars:
    gateway_address: 192.168.10.2  # Your gateway
  children:
    loadbalancer:
      children:
        loadbalancers:
          hosts:
            k3s-loadbalancer-01:
              ansible_host: 192.168.10.2
              # ... other parameters
```

### 3. Deployment

```bash
# Connectivity test
ansible all -m ping

# Full deployment
ansible-playbook playbooks/run.yml
```

## ⚙️ Configuration

### Main Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `k3s_version` | K3s version | `v1.28.x` |
| `keepalived_vip` | Load balancer VIP | `172.18.0.2` |
| `cluster_cidr` | Pod CIDR | `10.42.0.0/16` |
| `service_cidr` | Service CIDR | `10.43.0.0/16` |
| `api_port` | Kubernetes API port | `6443` |

### Network Configuration

The project natively supports:
- **IPv4**: `172.18.0.0/16` (customizable)
- **IPv6**: `fd42:f3f5:fe50::/56` (customizable)
- **Dual-stack**: Automatic configuration

### Required Secrets

Create a `.secret` file with:

```bash
# Authentication
export ANSIBLE_USER="your-user"
export ANSIBLE_PASSWORD="password"

# K3s Configuration
export K3S_VERSION="v1.28.8+k3s1"
export K3S_TOKEN="$(openssl rand -base64 64)"
export K3S_API_PORT="6443"

# Other parameters
export TZ="Europe/Paris"
export KEEPALIVED_PASSWORD="keepalived-password"
```

## 🚀 Deployment

### Available Playbooks

```bash
# Full deployment
ansible-playbook playbooks/run.yml -i inventory.yml

# Cluster upgrade
ansible-playbook playbooks/upgrade.yml -i inventory.yml

# Complete reset
ansible-playbook playbooks/reset.yml -i inventory.yml

# Cluster synchronization
ansible-playbook playbooks/sync.yml -i inventory.yml
```

### Step-by-step Deployment

```bash
# 1. DietPi nodes preparation
ansible-playbook playbooks/run.yml --tags dietpi -i inventory.yml

# 2. Load balancer configuration
ansible-playbook playbooks/run.yml --tags loadbalancer -i inventory.yml

# 3. K3s servers deployment
ansible-playbook playbooks/run.yml --tags k3s_server -i inventory.yml

# 4. Agents addition
ansible-playbook playbooks/run.yml --tags k3s_agent -i inventory.yml

# 5. Helm and charts installation
ansible-playbook playbooks/run.yml --tags helm -i inventory.yml
```

## 🛠️ Cluster Management

### Cluster Access

```bash
# Retrieve kubeconfig
scp k3s-server-01:~/.kube/config ~/.kube/config

# Connectivity test
kubectl get nodes
kubectl get pods -A
```

### Useful Commands

```bash
# Cluster status
kubectl cluster-info
kubectl get nodes -o wide

# LoadBalancer services (PureLB)
kubectl get svc -A

# LoadBalancer deployment example
kubectl apply -f https://k8s.io/examples/application/deployment.yaml
kubectl expose deployment nginx-deployment --port=80 --type=LoadBalancer --name=nginx
kubectl annotate service nginx purelb.io/service-group=ipv4-routed
```

### Monitoring

```bash
# System service logs
sudo journalctl -u k3s -f
sudo journalctl -u k3s-agent -f

# Node status
kubectl describe nodes
kubectl top nodes
```

## 🔧 Troubleshooting

### Common Issues

#### Cluster won't start

```bash
# Check logs
sudo journalctl -u k3s -f

# Check etcd connectivity
sudo systemctl status etcd
curl -k https://172.18.0.2:2379/health
```

#### Network problems

```bash
# Check keepalived VIP
ip addr show eth0
ping 172.18.0.2

# Test HAProxy
curl -k https://172.18.0.2:6443/version
```

#### Node reset

```bash
# On the failing node
sudo /usr/local/bin/k3s-uninstall.sh  # or k3s-agent-uninstall.sh

# Then redeploy
ansible-playbook playbooks/run.yml --limit failing-node
```

### Diagnostic Commands

```bash
# Network connectivity test
ansible all -m ping

# Service verification
ansible all -m service -a "name=k3s state=started" -b

# Certificate status
ansible loadbalancer -m shell -a "ls -la /etc/etcd/ssl/" -b
```

## 📁 Project Structure

```
k3s-dietpi-ansible/
├── ansible.cfg              # Ansible configuration
├── inventory.yml           # Machines inventory
├── requirements.yml        # Required Ansible collections
├── playbooks/
│   ├── run.yml            # Main deployment
│   ├── upgrade.yml        # Upgrade
│   ├── reset.yml          # Reset
│   ├── sync.yml           # Cluster synchronization
│   └── test.yml           # Tests
├── roles/
│   ├── dietpi/             # DietPi configuration
│   ├── load_balancer/      # HAProxy + keepalived
│   ├── etcd/               # etcd database
│   ├── k3s_server/         # K3s servers
│   ├── k3s_agent/          # K3s agents
│   └── helm/               # Package manager
├── group_vars/
│   ├── all/                # Global variables
│   ├── servers.yml        # Server variables
│   └── agents.yml         # Agent variables
├── host_vars/              # Per-machine variables
└── scripts/
    ├── setup_secrets.sh    # Secrets configuration
    └── clean.sh            # Cleanup
```

## 🔐 Security

- **Ansible Vault encryption** for all secrets
- **TLS certificates** for etcd and K3s
- **Automatic SSH hardening**
- **Private network** isolated for the cluster

## 🚀 Advanced Features

### IPv6 dual-stack support

The cluster is natively configured in IPv4/IPv6 dual-stack:

```yml
cluster_cidr: "10.42.0.0/16"
cluster_cidr_ipv6: "2001:db8:42::/56"
service_cidr: "10.43.0.0/16"
service_cidr_ipv6: "2001:db8:43::/112"
```

### Scalability

Easy addition of new nodes:

1. Add the new node to `inventory.yml` under the appropriate group (servers or agents)
2. Deploy the new node: `ansible-playbook playbooks/run.yml --limit new-node-name -i inventory.yml`
3. Synchronize cluster configuration: `ansible-playbook playbooks/sync.yml` -i inventory.yml

Example for adding a new agent:
```yml
# In inventory.yml, add under agents group
agents:
  hosts:
    k3s-agent-03:  # Your new node name
      ansible_host: 172.18.0.47
      # ... other parameters
```

Then deploy:
```bash
# Deploy new node
ansible-playbook playbooks/run.yml --limit k3s-agent-03 -i inventory.yml

# Synchronize cluster configuration
ansible-playbook playbooks/sync.yml -i inventory.yml
```

### Advanced Usage Examples

#### Selective synchronization
```bash
# Update HAProxy only
ansible-playbook playbooks/sync.yml --tags update_haproxy -i inventory.yml

# Update hosts files only
ansible-playbook playbooks/sync.yml --tags update_hosts -i inventory.yml

# Display cluster information only
ansible-playbook playbooks/sync.yml --tags cluster_info -i inventory.yml

# Update keepalived only
ansible-playbook playbooks/sync.yml --tags update_keepalived -i inventory.yml
```

#### Component-based deployment
```bash
# DietPi setup only
ansible-playbook playbooks/run.yml --tags dietpi -i inventory.yml

# Network configuration only
ansible-playbook playbooks/run.yml --tags network -i inventory.yml

# Helm installation only
ansible-playbook playbooks/run.yml --tags helm -i inventory.yml
```

#### Group-based management
```bash
# Restart all servers
ansible-playbook playbooks/run.yml --limit servers --tags restart -i inventory.yml

# Update agents only
ansible-playbook playbooks/run.yml --limit agents -i inventory.yml

# Load balancer configuration only
ansible-playbook playbooks/run.yml --limit loadbalancer -i inventory.yml
```

#### Diagnostics and maintenance
```bash
# Check all nodes status
ansible all -m ping

# Check K3s services
ansible servers -m shell -a "systemctl status k3s" -b
ansible agents -m shell -a "systemctl status k3s-agent" -b

# Check disk usage
ansible all -m shell -a "df -h" -b

# Restart HAProxy on load balancer
ansible loadbalancer -m systemd -a "name=haproxy state=restarted" -b
```

### High Availability

- **External etcd**: Prevents data corruption
- **keepalived VIP**: Automatic failover
- **HAProxy**: API servers load balancing
- **3 control planes**: Fault tolerance

### Monitoring and Observability

The cluster includes built-in monitoring capabilities:

- **Node Exporter**: Hardware and OS metrics (port 9796)
- **HAProxy Stats**: Load balancer monitoring (port 8404)
- **Calico metrics**: Network performance monitoring
- **K3s built-in metrics**: Cluster health monitoring

### Security Features

- **TLS everywhere**: End-to-end encryption
- **Network isolation**: Private cluster network
- **Vault encryption**: All secrets protected
- **SSH hardening**: Automatic security configuration

## 📖 Additional Documentation

- [K3s Advanced Configuration](https://docs.k3s.io/)
- [HAProxy Documentation](https://www.haproxy.org/download/2.4/doc/configuration.txt)
- [keepalived Guide](https://www.keepalived.org/doc/)
- [PureLB Load Balancer](https://purelb.gitlab.io/docs/)

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -am 'Add feature'`)
4. Push the branch (`git push origin feature/improvement`)
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## 👥 Authors

- **[Alain CAJUSTE](https://github.com/AC-CodeProd)** - *Initial development*

## 🙏 Acknowledgments

- [K3s](https://k3s.io/) team for this fantastic project
- [DietPi](https://dietpi.com/) community for the lightweight OS
- [Ansible](https://www.ansible.com/) team at Red Hat for automation tools
- [Calico](https://www.projectcalico.org/) team for networking
- [HAProxy](https://www.haproxy.org/) and [keepalived](https://www.keepalived.org/) communities

## 📊 Project Stats

- **Infrastructure**: Production-ready HA cluster
- **Security**: Enterprise-grade with TLS encryption
- **Monitoring**: Built-in observability stack
- **Networking**: Dual-stack IPv4/IPv6 support
- **Automation**: 100% Infrastructure as Code

---

⭐ **Please star this project if it helps you!**
