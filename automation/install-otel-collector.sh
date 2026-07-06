#!/bin/bash
set -euo pipefail

OTEL_VERSION="0.154.0"
ARCH="$(dpkg --print-architecture)"

apt-get update -q
apt-get install -y -q --no-install-recommends curl ca-certificates

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL \
  "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_${ARCH}.deb" \
  -o "$TMPDIR/otelcol-contrib.deb"

dpkg -i "$TMPDIR/otelcol-contrib.deb"

mkdir -p /etc/otelcol-contrib
chmod 755 /etc/otelcol-contrib

# Wait for Incus before starting so the otel LXC is up and DNS resolves
mkdir -p /etc/systemd/system/otelcol-contrib.service.d
cat > /etc/systemd/system/otelcol-contrib.service.d/override.conf <<'EOF'
[Unit]
After=incus.service
Wants=incus.service

[Service]
Restart=on-failure
RestartSec=10s
EOF

systemctl enable otelcol-contrib

apt-get clean
rm -rf /var/lib/apt/lists/*
