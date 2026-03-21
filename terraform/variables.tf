variable "enabled" {
  description = "Whether to build the architecture."
  type        = bool
  default     = true
}

variable "sns_topic_policy_enabled" {
  description = "Whether to add an SNS topic policy to allow CloudWatch publishing."
  type        = bool
  default     = true
}

variable "lambda_function_name" {
  description = "Name of the Lambda function."
  type        = string
  default     = "demo"
}

variable "lambda_function_runtime" {
  description = "Runtime for the Lambda function."
  type        = string
  default     = "python3.12"
}

variable "sns_display_name" {
  description = "Display name for the SNS topic."
  type        = string
  default     = ""
}

variable "cloudwatch_event_rule_name" {
  description = "Name for the CloudWatch event rule."
  type        = string
  default     = "app"
}

variable "description" {
  description = "The description for the CloudWatch rule."
  type        = string
  default     = ""
}

variable "role_arn" {
  description = "The Amazon Resource Name (ARN) associated with the role that is used for target invocation."
  type        = string
  default     = ""
}

variable "target_id" {
  description = "The Amazon Resource Name (ARN) associated with the role that is used for target invocation."
  type        = string
  default     = "SendToSNS"
}

variable "input_path" {
  description = "The value of the JSONPath that is used for extracting part of the matched event when passing it to the target."
  type        = string
  default     = ""
}

variable "target_role_arn" {
  description = "The Amazon Resource Name (ARN) of the IAM role to be used for this target when the rule is triggered."
  type        = string
  default     = ""
}

variable "sns_name" {
  description = "Name for the SNS topic."
  type        = string
  default     = ""
}

variable "subscribers" {
  description = "Subscribers for the SNS topic. If endpoint is left empty, the Lambda function ARN will be used."
  type = map(object({
    protocol               = string
    endpoint               = string
    endpoint_auto_confirms = bool
    raw_message_delivery   = bool
  }))
  default = {
    default_lambda = {
      protocol               = "lambda"
      endpoint               = ""
      endpoint_auto_confirms = false
      raw_message_delivery   = false
    }
  }
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK."
  type        = string
  default     = "alias/aws/sns"
}

variable "delivery_policy" {
  description = "The SNS delivery policy as JSON."
  type        = string
  default     = ""
}

variable "fifo_topic" {
  description = "Whether or not to create a FIFO (first-in-first-out) topic."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO topics."
  type        = bool
  default     = false
}
