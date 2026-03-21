variable "enabled" {
  description = "Whether to deploy the Cloudwatch event rule and target."
  type        = bool
  default     = true
}

variable "cloudwatch_event_rule_name" {
  description = "Name for the Cloudwatch event rule."
  type        = string
  default     = "app"
}

variable "description" {
  description = "The description for the Cloudwatch event rule."
  type        = string
  default     = "Cloudwatch event detecting console sign-in."
}

variable "role_arn" {
  description = "The Amazon Resource Name (ARN) associated with the role that is used for target invocation."
  type        = string
  default     = ""
}

variable "target_id" {
  description = "The unique target ID."
  type        = string
  default     = "SendToSNS"
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic to send events to."
  type        = string
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
