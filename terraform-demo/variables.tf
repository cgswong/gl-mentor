variable "instance_type" {
  type        = string
  default     = "t2.small"
  description = "Instance type"
}

variable "ami_id" {
  type        = string
  default     = "ami-0ac664bd64e1dcc6b"
  description = "AMI ID to use"
}
