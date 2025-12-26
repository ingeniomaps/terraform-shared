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
  project = var.project_id
  region  = var.region
}

module "terraform_state_bucket" {
  source      = "../modules/gcs_bucket"
  bucket_name = var.bucket_name
  region      = var.region
}