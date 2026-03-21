resource "aws_sns_topic" "this" {
  count = var.enabled ? 1 : 0

  name                        = var.sns_name != "" ? var.sns_name : null
  display_name                = var.sns_display_name != "" ? var.sns_display_name : null
  kms_master_key_id           = var.kms_master_key_id
  delivery_policy             = var.delivery_policy != "" ? var.delivery_policy : null
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.content_based_deduplication

  tags = var.tags
}

resource "aws_sns_topic_subscription" "this" {
  for_each = var.enabled ? var.subscribers : {}

  topic_arn              = aws_sns_topic.this[0].arn
  protocol               = each.value.protocol
  endpoint               = each.value.endpoint
  endpoint_auto_confirms = each.value.endpoint_auto_confirms
  raw_message_delivery   = each.value.raw_message_delivery
}

resource "aws_sns_topic_policy" "default" {
  count = var.sns_topic_policy_enabled && var.enabled ? 1 : 0

  arn    = aws_sns_topic.this[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = var.sns_topic_policy_enabled && var.enabled ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.this[0].arn]
  }
}
