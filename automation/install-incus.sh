#!/usr/bin/env bash
set -euo pipefail

INCUS_VERSION="1:7.1-debian13-202605311451"

# Zabbly keyring + repo (not in Hetzner base image)
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc

cat > /etc/apt/sources.list.d/zabbly-incus-stable.sources <<'EOF'
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: trixie
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/zabbly.asc
EOF

apt-get update -q

# zfs-dkms 2.4+ from backports/contrib required for kernel 6.19
# install zfsutils-linux first (pulls 2.3 from trixie), then upgrade via backports
apt-get install -y -q \
  incus="${INCUS_VERSION}" \
  incus-base="${INCUS_VERSION}" \
  incus-client="${INCUS_VERSION}" \
  zfsutils-linux \
  linux-headers-6.19.13+deb13-cloud-amd64

apt-get install -y -q -t trixie-backports zfs-dkms

# pin incus version
cat > /etc/apt/preferences.d/incus-pin <<EOF
Package: incus incus-base incus-client
Pin: version ${INCUS_VERSION}
Pin-Priority: 1001
EOF

usermod -aG incus-admin kombucha-admin

apt-get clean
rm -rf /var/lib/apt/lists/*

install -m 0755 /tmp/incus-init.sh /usr/local/bin/incus-init.sh
install -m 0644 /tmp/incus-init.service /etc/systemd/system/incus-init.service
systemctl daemon-reload

echo "Incus ${INCUS_VERSION} installed"
