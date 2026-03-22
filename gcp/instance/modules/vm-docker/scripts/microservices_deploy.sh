#!/bin/bash
set -euo pipefail

chown -R ubuntu:ubuntu /home/ubuntu 2>/dev/null || true
cd /home/ubuntu

%{ for service in microservices ~}
echo "========================================"
echo "Desplegando: ${service.name}"
echo "========================================"

PROJECT="${service.name}"
mkdir -p "/home/ubuntu/$PROJECT"
cd "/home/ubuntu/$PROJECT"

cat > .env <<'ENVEOF'
${service.env_file}
ENVEOF

cd /home/ubuntu
git clone ${service.repo_url} -b ${service.branch} --depth=1 "$PROJECT" 2>/dev/null || true
cd "/home/ubuntu/$PROJECT"

cat > .env <<'ENVEOF'
${service.env_file}
ENVEOF

if [ -f "installer.sh" ]; then
  bash installer.sh
elif [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
  docker compose up -d 2>/dev/null || docker-compose up -d
fi

cd /home/ubuntu
chown -R ubuntu:ubuntu "$PROJECT" 2>/dev/null || true
echo "✅ ${service.name} desplegado"
echo ""
%{ endfor ~}

echo "========================================"
echo "Despliegue completado"
echo "========================================"
