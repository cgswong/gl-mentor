variable "lambda_function_name" {
  description = "Name of the Lambda function."
  type        = string
  default     = "demo"
}

variable "lambda_function_runtime" {
  description = "The runtime for the Lambda function."
  type        = string
  default     = "python3.12"
}

variable "lambda_handler" {
  description = "Handler name for the Lambda function."
  type        = string
  default     = "index.lambda_handler"
}
