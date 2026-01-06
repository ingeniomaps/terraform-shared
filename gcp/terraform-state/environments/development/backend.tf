terraform {
  backend "gcs" {
    bucket = "roax-terraform-state"
    prefix = "dev"
  }
}

