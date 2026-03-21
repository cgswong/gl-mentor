# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance. If left blank, it defaults to the latest Amazon Linux 2023 AMI."
  type        = string
  default     = ""
  
  # Basic validation to ensure the AMI ID looks like a standard AWS AMI or is left blank.
  validation {
    condition     = var.ami_id == "" || can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "The ami_id value must be a valid AMI ID, starting with \"ami-\", or left blank."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_type" {
  description = "The type of EC2 instance to run (e.g., t3.micro, t3.small). Determines the amount of CPU and memory."
  type        = string
  default     = "t3.small"
}
