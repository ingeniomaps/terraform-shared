# ==============================================================================
# LOCALS — Resolución de valores y catálogo de servicios
# ==============================================================================

locals {
  # --------------------------------------------------------------------------
  # Resolución desde remote state o variables directas (patrón coalesce)
  # --------------------------------------------------------------------------

  vm_subnet_name = coalesce(
    var.vm_subnet_name,
    try(data.terraform_remote_state.shared_infra[0].outputs.vm_subnet_name, null)
  )

  service_account_email = coalesce(
    var.service_account_email,
    try(data.terraform_remote_state.shared_infra[0].outputs.vm_reader_email, null)
  )

  network_name = try(
    data.terraform_remote_state.shared_infra[0].outputs.network_name,
    try(regex("^(.+)-vm-subnet$", local.vm_subnet_name)[0], "default")
  )

  network_tags = try(
    data.terraform_remote_state.shared_infra[0].outputs.network_tags,
    {
      allow_iap_ssh = "${local.network_name}-allow-iap-ssh"
      allow_ssh     = "${local.network_name}-allow-ssh"
    }
  )

  tags_combined = distinct(concat(
    [local.network_tags.allow_iap_ssh],
    var.tags
  ))

  ssh_keys_combined = concat(
    ["ubuntu:${tls_private_key.vm_ssh_key.public_key_openssh}"],
    var.ssh_keys
  )

  # --------------------------------------------------------------------------
  # Catálogo de servicios — Definición única de todos los servicios
  # --------------------------------------------------------------------------
  # Cada servicio define su configuración base para despliegue con imagen.
  # compose_file: ruta al docker-compose dentro del repo clonado.
  # Los overrides de var.service_overrides se aplican encima.
  # --------------------------------------------------------------------------

  service_catalog_base = {
    # Agregar servicios del proyecto aquí o via var.service_overrides.
    # Cada entry define cómo se despliega un servicio (compose_file, env, imagen).

    gateway = {
      compose_file   = "docker/docker-compose.image.yml"
      env_file_name  = ".env"
      launch_command = "bash scripts/deploy-image.sh"
      image_name     = "gateway"
    }
    backend-auth = {
      compose_file   = "docker/docker-compose.image.yml"
      env_file_name  = ".env"
      launch_command = ""
      image_name     = "backend-auth"
    }
    backend-platform = {
      compose_file   = "docker/docker-compose.image.yml"
      env_file_name  = ".env"
      launch_command = ""
      image_name     = "backend-platform"
    }
    backend-processes = {
      compose_file   = "docker/docker-compose.image.yml"
      env_file_name  = ".env"
      launch_command = ""
      image_name     = "backend-processes"
    }
    frontend-auth = {
      compose_file   = "docker/docker-compose.image.yml"
      env_file_name  = ".env.local"
      launch_command = ""
      image_name     = "frontend-auth"
    }
    frontend-platform = {
      compose_file   = "docker/docker-compose.image.yml"
      env_file_name  = ".env.local"
      launch_command = ""
      image_name     = "frontend-platform"
    }
    admin = {
      compose_file   = "docker/docker-compose.image.yml"
      env_file_name  = ".env"
      launch_command = ""
      image_name     = "admin"
    }
    alerts-service = {
      compose_file   = "docker/docker-compose.image.yml"
      env_file_name  = ".env"
      launch_command = "bash scripts/deploy-image.sh"
      image_name     = "alerts-service"
    }
  }

  # URL de imagen por servicio: registry/image:tag
  # Prioridad tag: service_overrides > default_image_tag
  service_catalog = {
    for name, base in local.service_catalog_base : name => {
      repo_url       = "${var.github_repo_base_url}/${name}"
      branch         = lookup(lookup(var.service_overrides, name, {}), "branch", var.default_branch)
      image_url      = var.artifact_registry_url != null ? "${var.artifact_registry_url}/${base.image_name}:${lookup(lookup(var.service_overrides, name, {}), "image_tag", var.default_image_tag)}" : ""
      compose_file   = lookup(lookup(var.service_overrides, name, {}), "compose_file", base.compose_file)
      env_file_name  = lookup(lookup(var.service_overrides, name, {}), "env_file_name", base.env_file_name)
      launch_command = lookup(lookup(var.service_overrides, name, {}), "launch_command", base.launch_command)
    }
  }

  # --------------------------------------------------------------------------
  # Resolución de microservicios por VM
  # --------------------------------------------------------------------------
  # Para cada VM, resuelve la lista de microservicios desde el catálogo.
  # El repo se clona para obtener el docker-compose.image.yml y scripts,
  # pero el contenedor usa la imagen pre-construida del registry.
  # --------------------------------------------------------------------------

  vm_microservices = {
    for vm_name, vm in var.topology : vm_name => [
      for svc_name in vm.services : merge(
        { name = svc_name },
        local.service_catalog[svc_name],
        {
          env_file = "envs/${svc_name}.env"
        }
      )
    ]
  }

  # --------------------------------------------------------------------------
  # Scheduling — Cron expressions para Cloud Scheduler
  # --------------------------------------------------------------------------

  schedule_days_map = {
    "mon-fri"  = "1-5"
    "mon-sat"  = "1-6"
    "everyday" = "*"
    "weekdays" = "1-5"
  }

  schedule_days_cron = lookup(
    local.schedule_days_map,
    var.schedule.days,
    var.schedule.days # si no está en el map, se usa directo (formato cron)
  )

  start_parts = var.schedule.enabled ? split(":", var.schedule.start) : ["0", "0"]
  stop_parts  = var.schedule.enabled ? split(":", var.schedule.stop) : ["0", "0"]

  start_cron = "${local.start_parts[1]} ${local.start_parts[0]} * * ${local.schedule_days_cron}"
  stop_cron  = "${local.stop_parts[1]} ${local.stop_parts[0]} * * ${local.schedule_days_cron}"
}
