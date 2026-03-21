variable "enabled" {
  description = "Whether to deploy the SNS module resources."
  type        = bool
  default     = true
}

variable "sns_name" {
  description = "The name of the SNS topic."
  type        = string
  default     = ""
}

variable "sns_display_name" {
  description = "The display name for the SNS topic."
  type        = string
  default     = ""
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
  description = "Whether to create a FIFO topic."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO topics."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    "Name" = "demo-sns"
  }
}

variable "sns_topic_policy_enabled" {
  description = "Whether to attach a policy to the SNS topic to allow CloudWatch Events."
  type        = bool
  default     = true
}

variable "subscribers" {
  description = "A map of subscribers to the SNS topic."
  type = map(object({
    protocol               = string
    endpoint               = string
    endpoint_auto_confirms = bool
    raw_message_delivery   = bool
  }))
  default = {}
}
