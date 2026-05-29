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
  # Catálogo de servicios — definido por el proyecto consumidor
  # --------------------------------------------------------------------------
  # var.service_catalog viene del proyecto (no hardcodeado aquí).
  # var.service_overrides permite cambiar campos sin tocar el catálogo.
  # --------------------------------------------------------------------------

  service_catalog_base = var.service_catalog

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
      secret_id      = lookup(lookup(var.service_overrides, name, {}), "secret_id", base.secret_id)
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
