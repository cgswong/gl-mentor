# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # It is a best practice to pin the Terraform version to ensure consistent behavior across runs.
  required_version = ">= 1.2.0"

  # Define required provider constraints to prevent accidental upgrades breaking the configuration.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# Initialize the AWS provider in the specific region
provider "aws" {
  region = "us-east-1"
}
