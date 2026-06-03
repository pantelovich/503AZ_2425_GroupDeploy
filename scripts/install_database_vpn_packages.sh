#!/usr/bin/env bash
set -euo pipefail

# Installs package dependencies only.
# It does not configure MongoDB authentication, replica sets, users, data, OpenVPN certificates,
# routing, firewall rules, or client profiles.

ROLE="${1:-all}"

install_mongodb_packages() {
  sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo >/dev/null <<'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF

  sudo dnf install -y mongodb-org awscli
  sudo systemctl disable mongod || true
  echo "MongoDB packages installed. Configure mongod.conf, keyfile, users and rs0 manually."
}

install_openvpn_packages() {
  sudo dnf install -y openvpn iptables-services openssl
  sudo mkdir -p /etc/openvpn/server /etc/openvpn/client-config /etc/openvpn/pki
  echo "OpenVPN packages installed. Configure certificates, server.conf, routing and the client profile manually."
}

case "$ROLE" in
  mongodb)
    install_mongodb_packages
    ;;
  openvpn)
    install_openvpn_packages
    ;;
  all)
    install_mongodb_packages
    install_openvpn_packages
    ;;
  *)
    echo "Usage: $0 [mongodb|openvpn|all]" >&2
    exit 1
    ;;
esac
