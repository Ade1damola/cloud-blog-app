# This file defines values to display after deployment

# Load Balancer URL
output "load_balancer_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

# EC2 Instance Private IP
output "ec2_private_ip" {
  description = "Private IP of EC2 instance"
  value       = aws_instance.app.private_ip
}

# Database Endpoint
output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
  # Mark as sensitive (won't show in logs)
}

# Database Name
output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}