locals {

  docker_install_script = trimspace(templatefile(
    "${path.module}/scripts/docker_install.sh",
    {
      install_docker_compose = var.install_docker_compose && var.use_ubuntu_image
      docker_compose_version = var.docker_compose_version
    }
  ))

  certbot_install_script = (
    var.install_certbot && var.use_ubuntu_image
    ) ? trimspace(templatefile(
      "${path.module}/scripts/certbot_install.sh",
      {}
  )) : ""

  # Procesar microservicios: si env_file es una ruta a archivo, leer su contenido
  # Si parece una ruta (contiene "/" o empieza con "./" o "../") y el archivo existe, leerlo
  # De lo contrario, se trata como contenido directo
  processed_microservices = [
    for service in var.microservices : {
      name           = service.name
      repo_url       = service.repo_url
      branch         = service.branch
      image_url      = service.image_url
      launch_command = service.launch_command
      compose_file   = service.compose_file
      secret_id      = service.secret_id
      env_file_name  = service.env_file_name
      env_file = (
        (can(regex("^[./]", service.env_file)) || can(regex("/", service.env_file))) &&
        fileexists("${path.root}/${service.env_file}")
      ) ? file("${path.root}/${service.env_file}") : service.env_file
    }
  ]

  # Antes del deploy: los clones de abajo ya usan el helper.
  git_credential_script = var.git_token_secret_id != "" ? trimspace(templatefile(
    "${path.module}/scripts/git_credential.sh",
    { git_token_secret_id = var.git_token_secret_id }
  )) : ""

  microservices_deploy_script = length(var.microservices) > 0 ? trimspace(templatefile(
    "${path.module}/scripts/microservices_deploy.sh",
    {
      microservices = local.processed_microservices
    }
  )) : ""

  # Lo que lee watch_metadata.sh en la VM. Con secret_id el .env no viaja en la metadata.
  microservices_json = jsonencode([
    for service in local.processed_microservices : merge(
      {
        name          = service.name
        repo_url      = service.repo_url
        branch        = service.branch
        env_file_name = service.env_file_name
      },
      service.secret_id != "" ? { secret_id = service.secret_id } : { env_file = service.env_file },
      service.launch_command != "" ? { launch_command = service.launch_command } : {},
      service.image_url != "" ? { image_url = service.image_url } : {},
      service.compose_file != "" ? { compose_file = service.compose_file } : {},
    )
  ])

  # Va después del deploy inicial: el primer tick del timer (2 min) ve los servicios
  # ya clonados y no los toca.
  hot_update_script = var.enable_hot_update ? join("\n", [
    "echo 'Instalando actualización en caliente de microservicios...'",
    "mkdir -p /opt/scripts",
    "cat > /opt/scripts/update_microservices.sh <<'UPDATE_SCRIPT_EOF'",
    file("${path.module}/scripts/update_microservices.sh"),
    "UPDATE_SCRIPT_EOF",
    "cat > /opt/scripts/helper_update_services.sh <<'HELPER_SCRIPT_EOF'",
    file("${path.module}/scripts/helper_update_services.sh"),
    "HELPER_SCRIPT_EOF",
    "cat > /opt/scripts/watch_metadata.sh <<'WATCH_SCRIPT_EOF'",
    file("${path.module}/scripts/watch_metadata.sh"),
    "WATCH_SCRIPT_EOF",
    "cat > /opt/scripts/diagnose_update.sh <<'DIAGNOSE_SCRIPT_EOF'",
    file("${path.module}/scripts/diagnose_update.sh"),
    "DIAGNOSE_SCRIPT_EOF",
    "chmod +x /opt/scripts/*.sh",
    "chown -R ubuntu:ubuntu /opt/scripts || true",
    "touch /var/log/watch-metadata.log",
    "chown ubuntu:ubuntu /var/log/watch-metadata.log || true",
    "chmod 664 /var/log/watch-metadata.log || true",
    "cat > /etc/systemd/system/watch-metadata.service <<'SERVICE_EOF'",
    "[Unit]",
    "Description=Monitor metadata changes and update microservices",
    "After=network-online.target docker.service",
    "",
    "[Service]",
    "Type=oneshot",
    "User=ubuntu",
    "Group=ubuntu",
    "WorkingDirectory=/home/ubuntu",
    "ExecStart=/opt/scripts/watch_metadata.sh",
    "StandardOutput=journal",
    "StandardError=journal",
    "SERVICE_EOF",
    "cat > /etc/systemd/system/watch-metadata.timer <<'TIMER_EOF'",
    "[Unit]",
    "Description=Timer for metadata monitoring",
    "",
    "[Timer]",
    "OnBootSec=2min",
    "OnUnitActiveSec=1min",
    "AccuracySec=5s",
    "",
    "[Install]",
    "WantedBy=timers.target",
    "TIMER_EOF",
    "systemctl daemon-reload",
    "systemctl enable --now watch-metadata.timer",
    "echo 'Actualización en caliente activa (watch-metadata.timer)'",
  ]) : ""

  combined_startup_script = join("\n\n", compact([
    "#!/bin/bash",
    "set -euo pipefail",
    "exec > >(tee /var/log/startup-script.log) 2>&1",
    "",
    "# Variables de colores (definidas una sola vez, no readonly)",
    "export GREEN='\\033[0;32m'",
    "export RED='\\033[0;31m'",
    "export YELLOW='\\033[1;33m'",
    "export BLUE='\\033[0;34m'",
    "export NC='\\033[0m'",
    "",
    local.docker_install_script,
    local.certbot_install_script,
    local.git_credential_script,
    local.microservices_deploy_script,
    local.hot_update_script
  ]))

  startup_script = var.metadata_startup_script != "" ? join("\n\n", [
    local.combined_startup_script,
    "# Script personalizado adicional",
    trimspace(var.metadata_startup_script)
  ]) : local.combined_startup_script

  vm_image = (
    var.use_ubuntu_image
    ? "projects/ubuntu-os-cloud/global/images/family/${var.ubuntu_image_family}"
    : "projects/cos-cloud/global/images/family/cos-stable"
  )

}
