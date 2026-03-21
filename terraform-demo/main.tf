/**
 * # Basic EC2 Instance Deployment
 *
 * This configuration demonstrates how to deploy a basic Amazon EC2 instance using Terraform.
 * It is designed to be used as a simple, foundational example for classes covering Terraform basics.
 *
 * It serves the following purposes:
 * - Demonstrates provider configuration
 * - Shows how to use variables for flexible inputs
 * - Implements standard resource tagging
 * - Provides usable outputs for post-deployment verification
 */

# Define the local variables for tagging or common settings if needed
locals {
  common_tags = {
    Name        = "ExampleAppServerInstance"
    Environment = "test"
    Version     = "1.2.0"
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A SINGLE EC2 INSTANCE
# This resource creates an Amazon Linux 2023 EC2 instance (by default) or uses the provided AMI ID.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app_server" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023.id
  instance_type = var.instance_type

  # Merge standard localized tags to the instance
  tags = local.common_tags
}
