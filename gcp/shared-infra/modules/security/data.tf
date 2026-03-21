locals {
  account_name = "${var.workspace}-${var.env}-sa"

  common_labels = {
    environment = var.env
    workspace   = var.workspace
    managed_by  = "terraform"
    security    = "high"
  }

  is_production = var.env == "prod"
}

data "google_project" "current" {
  project_id = var.project_id # ID del proyecto de GCP a consultar
}