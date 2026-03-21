resource "aws_cloudwatch_event_rule" "default" {
  count = var.enabled ? 1 : 0

  name          = var.cloudwatch_event_rule_name
  description   = var.description
  event_pattern = <<EOF
{
  "detail-type": [
    "AWS Console Sign In via CloudTrail"
  ]
}
EOF
  role_arn      = var.role_arn != "" ? var.role_arn : null
  state         = "ENABLED"
}

resource "aws_cloudwatch_event_target" "default" {
  count = var.enabled ? 1 : 0

  rule       = aws_cloudwatch_event_rule.default[count.index].name
  target_id  = var.target_id
  arn        = var.sns_topic_arn
  input_path = var.input_path != "" ? var.input_path : null
  role_arn   = var.target_role_arn != "" ? var.target_role_arn : null
}
