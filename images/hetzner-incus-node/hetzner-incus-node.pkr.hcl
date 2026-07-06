packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

source "hcloud" "incus-node" {
  token       = var.hcloud_token
  image       = "debian-13"
  location    = "hel1"
  server_type = "cx23"
  snapshot_name = "hetzner-incus-node"
  snapshot_labels = {
    project = "tok-kombuha"
  }

  ssh_username = "root"
}

build {
  sources = ["source.hcloud.incus-node"]

  provisioner "shell" {
    script = "../../automation/install-incus-node.sh"
  }

  provisioner "file" {
    source      = pathexpand("~/.ssh/id_rsa.pub")
    destination = "/home/kombucha-admin/.ssh/authorized_keys"
  }

  provisioner "shell" {
    inline = [
      "chown -R kombucha-admin:kombucha-admin /home/kombucha-admin/.ssh",
      "chmod 600 /home/kombucha-admin/.ssh/authorized_keys",
    ]
  }

  provisioner "shell" {
    script = "../../automation/harden-ssh.sh"
  }

  provisioner "file" {
    source      = "../../automation/incus-init.sh"
    destination = "/tmp/incus-init.sh"
  }

  provisioner "file" {
    source      = "../../automation/incus-init.service"
    destination = "/tmp/incus-init.service"
  }

  provisioner "shell" {
    script = "../../automation/install-incus.sh"
  }

  provisioner "file" {
    source      = "../../automation/install-otel-collector.sh"
    destination = "/tmp/install-otel-collector.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/install-otel-collector.sh",
      "/tmp/install-otel-collector.sh",
      "rm /tmp/install-otel-collector.sh",
    ]
  }

  provisioner "file" {
    source      = "../../telemetry/otel-collector-host.yml"
    destination = "/etc/otelcol-contrib/config.yaml"
  }

  provisioner "shell" {
    inline = [
      "apt-get clean",
      "rm -rf /var/lib/apt/lists/*",
      "rm -rf /tmp/* /var/tmp/*",
      "rm -rf /var/log/*.log /var/log/*.gz /var/log/journal/* /var/log/syslog* /var/log/auth.log* /var/log/kern.log*",
      "truncate -s 0 /var/log/btmp /var/log/lastlog /var/log/utmp /var/log/wtmp 2>/dev/null || true",
      "rm -rf /root/.bash_history /home/kombucha-admin/.bash_history",
      "sync",
    ]
  }
}
