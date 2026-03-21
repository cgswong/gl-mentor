output "sns_topic_arn" {
  description = "The ARN of the generated SNS topic."
  value       = var.enabled ? aws_sns_topic.this[0].arn : ""
}
