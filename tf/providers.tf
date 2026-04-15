terraform {
  required_providers {
    mws = {
      source = "mws-cloud/mws"
    }
  }
  required_version = ">= 1.11"
}

provider "mws" {
  service_account_authorized_key_path = "../secrets/terraform_sa_key.json"
  zone                                = "ru-central1-a"
  project                             = var.project_id
}

variable "project_id" {
  type        = string
  description = "MWS Project ID"
  default     = "mws-sdf"
}