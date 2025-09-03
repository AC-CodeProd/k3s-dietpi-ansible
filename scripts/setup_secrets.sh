#!/bin/bash

# Require a file with a plaintext password called '.vault'

# Contains the exported secret values
source .secret
touch group_vars/all/vault
rm group_vars/all/vault
cat >> "group_vars/all/vault" <<EOF
EOF
[[ -z "$ANSIBLE_USER" ]] || ansible-vault encrypt_string --name ansible_user "$ANSIBLE_USER" >> "group_vars/all/vault"
[[ -z "$ANSIBLE_PASSWORD" ]] || ansible-vault encrypt_string --name ansible_password "$ANSIBLE_PASSWORD" >> "group_vars/all/vault"
[[ -z "$ANSIBLE_SSH_PASS" ]] || ansible-vault encrypt_string --name ansible_ssh_pass "$ANSIBLE_SSH_PASS" >> "group_vars/all/vault"
[[ -z "$RPI_USER" ]] || ansible-vault encrypt_string --name rpi_user "$RPI_USER" >> "group_vars/all/vault"
[[ -z "$RPI_PASSWORD" ]] || ansible-vault encrypt_string --name rpi_password "$RPI_PASSWORD" >> "group_vars/all/vault"
[[ -z "$RPI_CIDR" ]] || ansible-vault encrypt_string --name rpi_cidr "$RPI_CIDR" >> "group_vars/all/vault"
[[ -z "$RPI_IPV6_NETMASK" ]] || ansible-vault encrypt_string --name rpi_ipv6_netmask "$RPI_IPV6_NETMASK" >> "group_vars/all/vault"
[[ -z "$RPI_IPV6_GATEWAY" ]] || ansible-vault encrypt_string --name rpi_ipv6_gateway "$RPI_IPV6_GATEWAY" >> "group_vars/all/vault"
[[ -z "$TZ" ]] || ansible-vault encrypt_string --name tz "$TZ" >> "group_vars/all/vault"
[[ -z "$KEEPALIVED_PASSWORD" ]] || ansible-vault encrypt_string --name keepalived_password "$KEEPALIVED_PASSWORD" >> "group_vars/all/vault"
[[ -z "$KEEPALIVED_VIP" ]] || ansible-vault encrypt_string --name keepalived_vip "$KEEPALIVED_VIP" >> "group_vars/all/vault"
[[ -z "$KEEPALIVED_INTERFACE" ]] || ansible-vault encrypt_string --name keepalived_interface "$KEEPALIVED_INTERFACE" >> "group_vars/all/vault"
[[ -z "$KEEPALIVED_CIDR" ]] || ansible-vault encrypt_string --name keepalived_cidr "$KEEPALIVED_CIDR" >> "group_vars/all/vault"
[[ -z "$KEEPALIVED_BROADCAST_ADDRESS" ]] || ansible-vault encrypt_string --name keepalived_broadcast_address "$KEEPALIVED_BROADCAST_ADDRESS" >> "group_vars/all/vault"
[[ -z "$K3S_VERSION" ]] || ansible-vault encrypt_string --name k3s_version "$K3S_VERSION" >> "group_vars/all/vault"
[[ -z "$K3S_CLUSTER_LOADBALANCER_CIDR_IPV4" ]] || ansible-vault encrypt_string --name k3s_cluster_loadbalancer_cidr_ipv4 "$K3S_CLUSTER_LOADBALANCER_CIDR_IPV4" >> "group_vars/all/vault"
[[ -z "$K3S_CLUSTER_LOADBALANCER_POOL_IPV4" ]] || ansible-vault encrypt_string --name k3s_cluster_loadbalancer_pool_ipv4 "$K3S_CLUSTER_LOADBALANCER_POOL_IPV4" >> "group_vars/all/vault"
# - openssl rand -base64 64
[[ -z "$K3S_TOKEN" ]] || ansible-vault encrypt_string --name k3s_token "$K3S_TOKEN" >> "group_vars/all/vault"
[[ -z "$K3S_API_PORT" ]] || ansible-vault encrypt_string --name k3s_api_port "$K3S_API_PORT" >> "group_vars/all/vault"
[[ -z "$K3S_DNS_DOMAIN_NAME" ]] || ansible-vault encrypt_string --name k3s_dns_domain_name "$K3S_DNS_DOMAIN_NAME" >> "group_vars/all/vault"
[[ -z "${K3S_CLUSTER_CONTEXT:-'k3s-ansible'}" ]] || ansible-vault encrypt_string --name k3s_cluster_context "${K3S_CLUSTER_CONTEXT:-'k3s-ansible'}" >> "group_vars/all/vault"
[[ -z "${K3S_CLUSTER_USER:-'admin'}" ]] || ansible-vault encrypt_string --name k3s_cluster_user "${K3S_CLUSTER_USER:-'admin'}" >> "group_vars/all/vault"
[[ -z "${K3S_CLUSTER_NAME:-'k3s-ansible-cluster'}" ]] || ansible-vault encrypt_string --name k3s_cluster_name "${K3S_CLUSTER_NAME:-'k3s-ansible-cluster'}" >> "group_vars/all/vault"
[[ -z "${K3S_EXTRA_SERVER_ARGS:-'--disable=traefik,servicelb,local-storage --flannel-backend=none --disable-network-policy'}" ]] || ansible-vault encrypt_string --name k3s_extra_server_args "${K3S_EXTRA_SERVER_ARGS:-''}" >> "group_vars/all/vault"
[[ -z "${K3S_EXTRA_AGENT_ARGS:-''}" ]] || ansible-vault encrypt_string --name k3s_extra_agent_args "${K3S_EXTRA_AGENT_ARGS:-''}" >> "group_vars/all/vault"
[[ -z "$K3S_EXTRA_SERVICE_ENVS" ]] || ansible-vault encrypt_string --name k3s_extra_service_envs "$K3S_EXTRA_SERVICE_ENVS" >> "group_vars/all/vault"
[[ -z "${K3S_KUBECONFIG:-'~/.kube/config.new'}" ]] || ansible-vault encrypt_string --name k3s_kubeconfig "${K3S_KUBECONFIG:-'~/.kube/config.new'}" >> "group_vars/all/vault"
[[ -z "${K3S_RESOLV_NAMESERVERS:-'8.8.8.8,9.9.9.9'}" ]] || ansible-vault encrypt_string --name k3s_resolv_nameservers "${K3S_RESOLV_NAMESERVERS:-'8.8.8.8,9.9.9.9'}" >> "group_vars/all/vault"
[[ -z "$LONGHORN_BACKUP_TARGET" ]] || ansible-vault encrypt_string --name longhorn_backup_target "$LONGHORN_BACKUP_TARGET" >> "group_vars/all/vault"

[[ -z "$DOCKER_REGISTRY_ADMIN" ]] || ansible-vault encrypt_string --name docker_registry_admin "$DOCKER_REGISTRY_ADMIN" >> "group_vars/all/vault"
[[ -z "$DOCKER_REGISTRY_PASSWORD" ]] || ansible-vault encrypt_string --name docker_registry_password "$DOCKER_REGISTRY_PASSWORD" >> "group_vars/all/vault"
[[ -z "$DOCKER_REGISTRY_AUTH" ]] || ansible-vault encrypt_string --name docker_registry_auth "$DOCKER_REGISTRY_AUTH" >> "group_vars/all/vault"
[[ -z "$DOCKER_REGISTRY_HTTP_SECRET" ]] || ansible-vault encrypt_string --name docker_registry_http_secret "$DOCKER_REGISTRY_HTTP_SECRET" >> "group_vars/all/vault"
[[ -z "$DOCKER_REGISTRY_VERSION" ]] || ansible-vault encrypt_string --name docker_registry_version "$DOCKER_REGISTRY_VERSION" >> "group_vars/all/vault"
[[ -z "$DOCKER_REGISTRY_UI_VERSION" ]] || ansible-vault encrypt_string --name docker_registry_ui_version "$DOCKER_REGISTRY_UI_VERSION" >> "group_vars/all/vault"

[[ -z "$TRAEFIK_DASHBOARD_HTPASSWD_BCRYPT" ]] || ansible-vault encrypt_string --name traefik_dashboard_htpasswd_bcrypt "$TRAEFIK_DASHBOARD_HTPASSWD_BCRYPT" >> "group_vars/all/vault"