# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# These outputs allow querying of the created infrastructure after deployment.
# ---------------------------------------------------------------------------------------------------------------------

output "instance_id" {
  description = "The unique ID of the created EC2 instance."
  value       = aws_instance.app_server.id
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable."
  value       = aws_instance.app_server.public_ip
}

output "private_ip" {
  description = "The private IP address assigned to the instance."
  value       = aws_instance.app_server.private_ip
}
