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
  credentials = var.credentials_file != null ? file("${path.root}/../../${var.credentials_file}") : null
}

module "terraform_state_bucket" {
  source                = "../modules/gcs_bucket"
  bucket_name           = var.bucket_name
  region                = var.region
  prevent_destroy       = true # Proteger bucket global
  retention_period_days = 90   # 90 días de retención para bucket global
  retention_locked      = true # Bloquear política para bucket global
}