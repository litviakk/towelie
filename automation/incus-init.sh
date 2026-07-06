#!/usr/bin/env bash
set -euo pipefail

DEV=$(readlink -f /dev/zfs-pool)
PUBLIC_IP=$(curl -sf http://169.254.169.254/hetzner/v1/metadata/public-ipv4)

wipefs -a "$DEV"
blockdev --rereadpt "$DEV"
sleep 1

sed -e "s|/dev/zfs-pool-dev|$DEV|" -e "s|HETZNER_PUBLIC_IPV4|$PUBLIC_IP|" \
  /etc/incus-init-preseed.yml | incus admin init --preseed
