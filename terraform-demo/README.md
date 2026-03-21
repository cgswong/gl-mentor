<!-- BEGIN_TF_DOCS -->
# Basic EC2 Instance Deployment

This configuration demonstrates how to deploy a basic Amazon EC2 instance using Terraform.
It is designed to be used as a simple, foundational example for classes covering Terraform basics.

It serves the following purposes:
- Demonstrates provider configuration
- Shows how to use variables for flexible inputs
- Implements standard resource tagging
- Provides usable outputs for post-deployment verification

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.app_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ami.al2023](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | The ID of the AMI to use for the EC2 instance. If left blank, it defaults to the latest Amazon Linux 2023 AMI. | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The type of EC2 instance to run (e.g., t3.micro, t3.small). Determines the amount of CPU and memory. | `string` | `"t3.small"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | The unique ID of the created EC2 instance. |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | The private IP address assigned to the instance. |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | The public IP address assigned to the instance, if applicable. |
<!-- END_TF_DOCS -->