#!/bin/bash
set -euo pipefail

# Skip si Docker ya está instalado (evitar reinstalar en cada boot)
if command -v docker &>/dev/null && docker ps &>/dev/null; then
  echo "Docker ya instalado — skip"
else
  set -x
  exec > >(tee /var/log/docker-install.log) 2>&1
  echo "=== Instalando Docker ==="

  apt-get update -y
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git make jq

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io

  %{ if install_docker_compose ~}
  curl -L "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -sfn /usr/local/bin/docker-compose /usr/bin/docker-compose
  %{ endif ~}

  if id "ubuntu" &>/dev/null; then
    usermod -aG docker ubuntu || true
  fi

  # Permitir que cualquier usuario se agregue al grupo docker
  echo "%users ALL=(root) NOPASSWD: /usr/sbin/usermod -aG docker *" \
    > /etc/sudoers.d/docker-group
  chmod 440 /etc/sudoers.d/docker-group

  # Agregar usuarios de OS Login al grupo docker automaticamente
  cat > /etc/profile.d/docker-group.sh << 'PROFILE'
if groups 2>/dev/null | grep -qv docker; then
  if getent group docker >/dev/null 2>&1; then
    sudo usermod -aG docker "$(whoami)" 2>/dev/null || true
    if ! groups | grep -q docker; then
      exec sg docker -c "$SHELL --login"
    fi
  fi
fi
PROFILE
  chmod 644 /etc/profile.d/docker-group.sh

  systemctl enable docker
  systemctl start docker
  sleep 5

  docker --version
  echo "=== Docker instalado ==="
  set +x
fi
