/**
 * # Terraform AWS Demo Architecture
 * This module demonstrates Terraform basics for a class.
 * It provisions an event-driven architecture using CloudWatch Events, SNS, and Lambda.
 *
 * ## Architecture
 * - **CloudWatch Event Rule**: Detects AWS Console Sign In via CloudTrail.
 * - **SNS Topic**: Receives events from CloudWatch and fans them out.
 * - **Lambda Function**: Subscribed to the SNS topic to process events.
 */

module "lambda" {
  source                  = "./modules/lambda"
  lambda_function_name    = var.lambda_function_name
  lambda_function_runtime = var.lambda_function_runtime
}

module "sns" {
  source                      = "./modules/sns"
  enabled                     = var.enabled
  sns_name                    = var.sns_name
  sns_display_name            = var.sns_display_name
  kms_master_key_id           = var.kms_master_key_id
  delivery_policy             = var.delivery_policy
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.content_based_deduplication
  sns_topic_policy_enabled    = var.sns_topic_policy_enabled

  subscribers = {
    for k, v in var.subscribers : k => {
      protocol               = v.protocol
      endpoint               = v.endpoint == "" ? module.lambda.lambda_function_arn : v.endpoint
      endpoint_auto_confirms = v.endpoint_auto_confirms
      raw_message_delivery   = v.raw_message_delivery
    }
  }
}

module "cloudwatch" {
  source                     = "./modules/cloudwatch"
  enabled                    = var.enabled
  cloudwatch_event_rule_name = var.cloudwatch_event_rule_name
  description                = var.description
  role_arn                   = var.role_arn
  target_id                  = var.target_id
  sns_topic_arn              = module.sns.sns_topic_arn
  input_path                 = var.input_path
  target_role_arn            = var.target_role_arn
}
