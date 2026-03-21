output "cloudwatch_event_rule_arn" {
  description = "The ARN of the Cloudwatch Event Rule."
  value       = var.enabled ? aws_cloudwatch_event_rule.default[0].arn : ""
}
