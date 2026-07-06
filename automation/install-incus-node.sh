#!/usr/bin/env bash
set -euo pipefail

KERNEL_VERSION="6.19.13+deb13-cloud-amd64"
KERNEL_PKG="linux-image-${KERNEL_VERSION}"

apt-get update -q
apt-get install -y -q openssh-server

apt-get update -q
apt-get install -y -q "${KERNEL_PKG}"

# pin kernel to prevent accidental upgrades
cat > /etc/apt/preferences.d/kernel-pin <<EOF
Package: linux-image-*
Pin: version *
Pin-Priority: -1

Package: ${KERNEL_PKG}
Pin: version *
Pin-Priority: 1001
EOF

# kombucha-admin user
useradd -m kombucha-admin -s /bin/bash
mkdir -p /home/kombucha-admin/.ssh
chmod 700 /home/kombucha-admin/.ssh

# passwordless sudo
echo 'kombucha-admin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/30-kombucha-admin
chmod 0440 /etc/sudoers.d/30-kombucha-admin

# Prepend Incus bridge as first nameserver so container names resolve on the host
echo "nameserver 10.10.1.1" > /etc/resolvconf/resolv.conf.d/head

NODE_EXPORTER_VERSION="1.11.1"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

apt-get install -y -q curl

curl -fsSL "${NODE_EXPORTER_URL}" -o /tmp/node_exporter.tar.gz
tar -xzf /tmp/node_exporter.tar.gz -C /tmp
mv /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/node_exporter
chmod +x /usr/local/bin/node_exporter
rm -rf /tmp/node_exporter*

useradd -r -s /sbin/nologin node_exporter 2>/dev/null || true

cat > /etc/systemd/system/node-exporter.service <<'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --collector.systemd \
  --collector.processes \
  --web.listen-address=127.0.0.1:9100
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node-exporter

apt-get clean
rm -rf /var/lib/apt/lists/*
