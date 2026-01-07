terraform {
  backend "gcs" {
    bucket = "workspace-terraform-state"
    prefix = "dev"
  }
}
