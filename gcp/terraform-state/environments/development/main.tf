terraform {
  required_version = ">= 1.14.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file != null ? file("${path.root}/../../../${var.credentials_file}") : null
}

module "terraform_state_bucket" {
  source                = "../../modules/gcs_bucket"
  bucket_name           = "${var.bucket_prefix}-${var.env}"
  region                = var.region
  prevent_destroy       = false # Desarrollo puede ser destruido si es necesario
  retention_period_days = 7     # 7 días de retención para desarrollo
  retention_locked      = false # No bloquear en desarrollo
}
