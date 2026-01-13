terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# AWS Provider - only used when cloud_provider = "aws"
provider "aws" {
  region = var.cloud_provider == "aws" ? var.region : "us-east-1"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# Azure Provider - only used when cloud_provider = "azure"
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# GCP Provider - only used when cloud_provider = "gcp"
provider "google" {
  project = var.gcp_project_id
  region  = var.cloud_provider == "gcp" ? var.region : "us-central1"
}