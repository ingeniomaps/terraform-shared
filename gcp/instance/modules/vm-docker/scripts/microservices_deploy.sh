#!/bin/bash
set -euo pipefail

chown -R ubuntu:ubuntu /home/ubuntu 2>/dev/null || true
cd /home/ubuntu

%{ for service in microservices ~}
echo "========================================"
echo "Desplegando: ${service.name}"
echo "========================================"

PROJECT="${service.name}"

# Guardar .env en temporal (antes del clone para no ensuciar el directorio)
cat > "/tmp/$${PROJECT}.env" <<'ENVEOF'
${service.env_file}
ENVEOF

# Clonar repo (obtiene compose files, scripts, configs)
cd /home/ubuntu
rm -rf "$PROJECT"
git clone ${service.repo_url} -b ${service.branch} --depth=1 "$PROJECT"
cd "/home/ubuntu/$PROJECT"

# Copiar .env al directorio del proyecto
cp "/tmp/$${PROJECT}.env" .env
rm -f "/tmp/$${PROJECT}.env"

%{ if service.image_url != "" ~}
# Autenticar con Artifact Registry y descargar imagen
REGISTRY_HOST=$(echo "${service.image_url}" | cut -d'/' -f1)
gcloud auth configure-docker "$REGISTRY_HOST" --quiet 2>/dev/null || true
echo "==> Descargando imagen ${service.image_url}..."
docker pull "${service.image_url}" || {
  echo "⚠️  No se pudo descargar ${service.image_url} (puede no existir aún)"
}
%{ endif ~}

# Crear red Docker si no existe
set -a && source .env && set +a
docker network create --subnet=192.160.0.0/16 "$${NETWORK_NAME:-cubiko}" 2>/dev/null || true

# Levantar servicio: launch_command > installer.sh > docker-compose
%{ if service.launch_command != "" ~}
echo "==> Ejecutando: ${service.launch_command}"
${service.launch_command}
%{ else ~}
if [ -f "installer.sh" ]; then
  bash installer.sh
%{ if service.compose_file != "" ~}
elif [ -f "${service.compose_file}" ]; then
  docker compose --env-file .env -f "${service.compose_file}" up -d
%{ endif ~}
elif [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
  docker compose up -d 2>/dev/null || docker-compose up -d
fi
%{ endif ~}

cd /home/ubuntu
chown -R ubuntu:ubuntu "$PROJECT" 2>/dev/null || true
echo "✅ ${service.name} desplegado"
echo ""
%{ endfor ~}

echo "========================================"
echo "Despliegue completado"
echo "========================================"
