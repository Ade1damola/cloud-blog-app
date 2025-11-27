# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  # Use region from variables
}

# ====================
# NETWORKING (VPC)
# ====================

# Create Virtual Private Cloud (VPC)
# A VPC is your own private network in AWS
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  # IP range: 10.0.0.0 to 10.0.255.255 (65,536 addresses)
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  # Enable DNS so resources can resolve domain names
  
  tags = {
    Name = "${var.project_name}-vpc"
    # Tag for identification
  }
}

# Create Internet Gateway
# This allows VPC to connect to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create Public Subnet 1 (for Load Balancer)
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  # IP range: 10.0.1.0 to 10.0.1.255 (256 addresses)
  
  availability_zone = "${var.aws_region}a"
  # First availability zone in region
  
  map_public_ip_on_launch = true
  # Auto-assign public IPs to resources
  
  tags = {
    Name = "${var.project_name}-public-subnet-1"
  }
}

# Create Public Subnet 2 (for high availability)
resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  # Second availability zone
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet-2"
  }
}

# Create Private Subnet 1 (for EC2 instance)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"
  
  tags = {
        Name = "${var.project_name}-private-subnet-1"
    }
}

# Create Private Subnet 2 (for database)
resource "aws_subnet" "private_2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.11.0/24"
    availability_zone = "${var.aws_region}b"
    tags = {
        Name = "${var.project_name}-private-subnet-2"
    }
}

# Create Elastic IP for NAT Gateway
# Static public IP address
resource "aws_eip" "nat" {
    domain = "vpc"
    tags = {
        Name = "${var.project_name}-nat-eip"
    }
}

# Create NAT Gateway
# Allows private subnets to access internet (for updates)
resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public_1.id
    # NAT Gateway must be in public subnet
    tags = {
        Name = "${var.project_name}-nat"
    }
    depends_on = [aws_internet_gateway.main]
    # Wait for Internet Gateway first
}

# Create Route Table for Public Subnets
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        # All internet traffic (0.0.0.0/0)
        gateway_id = aws_internet_gateway.main.id
        # Route through Internet Gateway
    }
    tags = {
        Name = "${var.project_name}-public-rt"
    }
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public_1" {
    subnet_id      = aws_subnet.public_1.id
    route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_2" {
    subnet_id      = aws_subnet.public_2.id
    route_table_id = aws_route_table.public.id
}

# Create Route Table for Private Subnets
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    # Route through NAT Gateway (not Internet Gateway)
    }
    tags = {
        Name = "${var.project_name}-private-rt"
    }
}

# Associate Private Route Table with Private Subnets
resource "aws_route_table_association" "private_1" {
    subnet_id      = aws_subnet.private_1.id
    route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_2" {
    subnet_id      = aws_subnet.private_2.id
    route_table_id = aws_route_table.private.id
}

# ====================
# SECURITY GROUPS (Firewalls)
# ====================

# Security Group for Load Balancer
resource "aws_security_group" "alb" {
    name        = "${var.project_name}-alb-sg"
    description = "Security group for Application Load Balancer"
    vpc_id      = aws_vpc.main.id

    # Allow inbound HTTP from anywhere
    ingress {
        description = "HTTP from internet"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        # 0.0.0.0/0 = anywhere on the internet
    }

    # Allow all outbound traffic
    egress {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        # -1 = all protocols
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "${var.project_name}-alb-sg"
    }
}

# Security Group for EC2 Instance
resource "aws_security_group" "ec2" {
    name        = "${var.project_name}-ec2-sg"
    description = "Security group for EC2 instance"
    vpc_id      = aws_vpc.main.id

    # Allow traffic from Load Balancer only
    ingress {
        description     = "Frontend from ALB"
        from_port       = 8080
        to_port         = 8080
        protocol        = "tcp"
        security_groups = [aws_security_group.alb.id]
        # Only from ALB security group
    }

    # Allow SSH from anywhere (for deployment)
    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound
    egress {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-ec2-sg"
    }
}

# Security Group for RDS Database
resource "aws_security_group" "rds" {
    name        = "${var.project_name}-rds-sg"
    description = "Security group for RDS database"
    vpc_id      = aws_vpc.main.id
    # Allow PostgreSQL from EC2 only
    ingress {
        description     = "PostgreSQL from EC2"
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        security_groups = [aws_security_group.ec2.id]
        # Only from EC2 security group
    }
    egress {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "${var.project_name}-rds-sg"
    }
}

# ====================
# DATABASE (RDS)
# ====================

# Create DB Subnet Group
# RDS needs at least 2 subnets in different availability zones
resource "aws_db_subnet_group" "main" {
    name       = "${var.project_name}-db-subnet-group"
    subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    tags = {
        Name = "${var.project_name}-db-subnet-group"
    }
}

# Create RDS PostgreSQL Database
resource "aws_db_instance" "main" {
    identifier = "${var.project_name}-db"

    # Database engine
    engine         = "postgres"
    engine_version = "15.15"

    # Instance size
    instance_class = "db.t3.micro"
    # t3.micro: Small, free-tier eligible instance

    # Storage
    allocated_storage = 20
    # 20 GB storage
    storage_type = "gp3"
    # gp3: General purpose SSD (faster and cheaper than gp2)

    # Database credentials
    db_name  = "blogdb"
    username = "postgres"
    password = var.db_password
    # Password from variable (provided securely)

    # Networking
    db_subnet_group_name   = aws_db_subnet_group.main.name
    vpc_security_group_ids = [aws_security_group.rds.id]
    publicly_accessible    = false
    # NOT accessible from internet

    # Backup configuration
    backup_retention_period = 7
    # Keep backups for 7 days
    skip_final_snapshot = true
    # Don't create snapshot when deleting (for testing)
    tags = {
        Name = "${var.project_name}-db"
    }
}

# ====================
# COMPUTE (EC2)
# ====================

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
    most_recent = true
    owners      = ["amazon"]
    filter {
        name   = "name"
        values = ["al2023-ami-*-x86_64"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# Create SSH Key Pair
resource "aws_key_pair" "deployer" {
    key_name   = "${var.project_name}-key"
    public_key = var.ssh_public_key
}

# Create EC2 Instance
resource "aws_instance" "app" {
    ami = data.aws_ami.amazon_linux_2023.id
    instance_type = "t2.micro"
    # t2.micro: Free tier eligible
    subnet_id                   = aws_subnet.private_1.id
    vpc_security_group_ids      = [aws_security_group.ec2.id]
    key_name                    = aws_key_pair.deployer.key_name
    associate_public_ip_address = false
    # No public IP (in private subnet)

    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    
    # User data script (runs on first boot)
    user_data = <<-EOF
        #!/bin/bash
        # Update system
        yum update -y
        # Install Docker
        yum install -y docker
        systemctl start docker
        systemctl enable docker
          
        # Add ec2-user to docker group
        usermod -a -G docker ec2-user
          
        # Install Docker Compose
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
          
        # Create app directory
        mkdir -p /home/ec2-user/app
        chown ec2-user:ec2-user /home/ec2-user/app
        EOF
    tags = {
        Name = "${var.project_name}-instance"
    }
}

# Create IAM role for EC2 to use SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-ssm-role"
  }
}

# Attach SSM policy to role
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ====================
# LOAD BALANCER
# ====================

# Create Application Load Balancer
resource "aws_lb" "main" {
    name               = "${var.project_name}-alb"
    internal           = false
    # external (internet-facing)
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb.id]
    subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    # Must be in at least 2 public subnets
    tags = {
        Name = "${var.project_name}-alb"
    }
}

# Create Target Group
# Target group defines which instances receive traffic
resource "aws_lb_target_group" "app" {
    name     = "${var.project_name}-tg"
    port     = 8080
    protocol = "HTTP"
    vpc_id   = aws_vpc.main.id

    # Health check configuration
    health_check {
        enabled             = true
        healthy_threshold   = 2
        # Consider healthy after 2 successful checks

        interval            = 30
        # Check every 30 seconds

        matcher             = "200"
        # HTTP 200 = healthy

        path                = "/"
        # Check root path

        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
        # Consider unhealthy after 2 failed checks
    }

    tags = {
        Name = "${var.project_name}-tg"
    }
}

# Attach EC2 instance to Target Group
resource "aws_lb_target_group_attachment" "app" {
    target_group_arn = aws_lb_target_group.app.arn
    target_id        = aws_instance.app.id
    port             = 8080
}

# Create Load Balancer Listener
# Listener defines how ALB receives traffic
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.main.arn
    port              = "80"
    protocol          = "HTTP"
    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.app.arn
        # Forward traffic to target group
    }
}