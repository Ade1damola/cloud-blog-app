# This file defines all configurable values

# AWS region
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# Project name (used for naming resources)
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloud-blog"
}

# Environment (dev, staging, prod)
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# Database password (will be provided securely)
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  # sensitive = true: Terraform won't show this in logs
}

# Docker Hub username
variable "docker_username" {
  description = "Docker Hub username"
  type        = string
}

# SSH key for EC2 access
variable "ssh_public_key" {
  description = "SSH public key for EC2 instance"
  type        = string
}