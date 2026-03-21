output "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.terraform_lambda_func.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.terraform_lambda_func.function_name
}
