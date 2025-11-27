# This file configures where Terraform stores its state

# Terraform settings
terraform {
  required_version = ">= 1.0"
  # Requires Terraform version 1.0 or higher
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # Use AWS provider version 5.x
    }
  }
  
  # Remote state backend (created manually first)
  backend "s3" {
    bucket = "cloud-blog-terraform-state-adedamola-2711"
    
    key    = "terraform.tfstate"
    # File name for state
    
    region = "us-east-1"
    # AWS region
    
    encrypt = true
    # Encrypt state file
  }
}