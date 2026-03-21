# Terraform AWS Demo Architecture
This module demonstrates Terraform basics for a class.
It provisions an event-driven architecture using CloudWatch Events, SNS, and Lambda.

## Architecture
- **CloudWatch Event Rule**: Detects AWS Console Sign In via CloudTrail.
- **SNS Topic**: Receives events from CloudWatch and fans them out.
- **Lambda Function**: Subscribed to the SNS topic to process events.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatch"></a> [cloudwatch](#module\_cloudwatch) | ./modules/cloudwatch | n/a |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ./modules/lambda | n/a |
| <a name="module_sns"></a> [sns](#module\_sns) | ./modules/sns | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_event_rule_name"></a> [cloudwatch\_event\_rule\_name](#input\_cloudwatch\_event\_rule\_name) | Name for the CloudWatch event rule. | `string` | `"app"` | no |
| <a name="input_content_based_deduplication"></a> [content\_based\_deduplication](#input\_content\_based\_deduplication) | Enable content-based deduplication for FIFO topics. | `bool` | `false` | no |
| <a name="input_delivery_policy"></a> [delivery\_policy](#input\_delivery\_policy) | The SNS delivery policy as JSON. | `string` | `""` | no |
| <a name="input_description"></a> [description](#input\_description) | The description for the CloudWatch rule. | `string` | `""` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to build the architecture. | `bool` | `true` | no |
| <a name="input_fifo_topic"></a> [fifo\_topic](#input\_fifo\_topic) | Whether or not to create a FIFO (first-in-first-out) topic. | `bool` | `false` | no |
| <a name="input_input_path"></a> [input\_path](#input\_input\_path) | The value of the JSONPath that is used for extracting part of the matched event when passing it to the target. | `string` | `""` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. | `string` | `"alias/aws/sns"` | no |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | Name of the Lambda function. | `string` | `"demo"` | no |
| <a name="input_lambda_function_runtime"></a> [lambda\_function\_runtime](#input\_lambda\_function\_runtime) | Runtime for the Lambda function. | `string` | `"python3.12"` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | The Amazon Resource Name (ARN) associated with the role that is used for target invocation. | `string` | `""` | no |
| <a name="input_sns_display_name"></a> [sns\_display\_name](#input\_sns\_display\_name) | Display name for the SNS topic. | `string` | `""` | no |
| <a name="input_sns_name"></a> [sns\_name](#input\_sns\_name) | Name for the SNS topic. | `string` | `""` | no |
| <a name="input_sns_topic_policy_enabled"></a> [sns\_topic\_policy\_enabled](#input\_sns\_topic\_policy\_enabled) | Whether to add an SNS topic policy to allow CloudWatch publishing. | `bool` | `true` | no |
| <a name="input_subscribers"></a> [subscribers](#input\_subscribers) | Subscribers for the SNS topic. If endpoint is left empty, the Lambda function ARN will be used. | <pre>map(object({<br/>    protocol               = string<br/>    endpoint               = string<br/>    endpoint_auto_confirms = bool<br/>    raw_message_delivery   = bool<br/>  }))</pre> | <pre>{<br/>  "default_lambda": {<br/>    "endpoint": "",<br/>    "endpoint_auto_confirms": false,<br/>    "protocol": "lambda",<br/>    "raw_message_delivery": false<br/>  }<br/>}</pre> | no |
| <a name="input_target_id"></a> [target\_id](#input\_target\_id) | The Amazon Resource Name (ARN) associated with the role that is used for target invocation. | `string` | `"SendToSNS"` | no |
| <a name="input_target_role_arn"></a> [target\_role\_arn](#input\_target\_role\_arn) | The Amazon Resource Name (ARN) of the IAM role to be used for this target when the rule is triggered. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_event_rule_arn"></a> [cloudwatch\_event\_rule\_arn](#output\_cloudwatch\_event\_rule\_arn) | The ARN of the CloudWatch Event Rule. |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | The ARN of the Lambda Function. |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | The name of the Lambda Function. |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | The ARN of the SNS topic. |
