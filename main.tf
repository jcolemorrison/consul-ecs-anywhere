terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.49.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.67.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "=3.75.0"
    }
  }
}
