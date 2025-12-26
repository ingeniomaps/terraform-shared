locals {
  corporate_ip_valid        = !var.enable_restricted_http || length(var.corporate_ip_ranges) > 0
  vpc_peering_project_valid = !var.enable_vpc_peering || var.peer_project_id != null
  vpc_peering_name_valid    = !var.enable_vpc_peering || var.peer_vpc_name != null
}


resource "null_resource" "validate_corporate_ip_ranges" {
  count = local.corporate_ip_valid ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'ERROR: corporate_ip_ranges es requerido cuando enable_restricted_http = true' && exit 1"
  }
}

resource "null_resource" "validate_peer_project_id" {
  count = local.vpc_peering_project_valid ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'ERROR: peer_project_id es requerido cuando enable_vpc_peering = true' && exit 1"
  }
}

resource "null_resource" "validate_peer_vpc_name" {
  count = local.vpc_peering_name_valid ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'ERROR: peer_vpc_name es requerido cuando enable_vpc_peering = true' && exit 1"
  }
}
