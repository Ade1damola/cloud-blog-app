# Cloud-Native Blog Application

A production-grade, two-tier blog application deployed on AWS with complete CI/CD automation and security scanning.


## 🎨 Architecture Diagram
```
┌─────────────────────────────────────────────────────────┐
│                        Internet                          │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                     │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │         Public Subnets (10.0.1.0/24)              │ │
│  │                                                     │ │
│  │    ┌──────────────────────────────────┐           │ │
│  │    │  Application Load Balancer       │           │ │
│  │    │  (Port 80)                       │           │ │
│  │    └────────────┬─────────────────────┘           │ │
│  └─────────────────┼───────────────────────────────────┘ │
│                    │                                   │
│  ┌─────────────────┼───────────────────────────────────┐ │
│  │         Private Subnets (10.0.10.0/24)            │ │
│  │                 ↓                                  │ │
│  │    ┌──────────────────────────────────┐           │ │
│  │    │      EC2 Instance (t2.micro)     │           │ │
│  │    │                                   │           │ │
│  │    │  ┌─────────────────────────────┐ │           │ │
│  │    │  │ Frontend (Port 8080)        │ │           │ │
│  │    │  └─────────────────────────────┘ │           │ │
│  │    │  ┌─────────────────────────────┐ │           │ │
│  │    │  │ Backend (Port 5000)         │ │           │ │
│  │    │  └──────────┬──────────────────┘ │           │ │
│  │    └─────────────┼─────────────────────┘           │ │
│  └──────────────────┼───────────────────────────────────┘ │
│                     │                                   │
│  ┌──────────────────┼───────────────────────────────────┐ │
│  │         Private Subnets (10.0.11.0/24)            │ │
│  │                  ↓                                 │ │
│  │    ┌──────────────────────────────────┐           │ │
│  │    │  RDS PostgreSQL (db.t3.micro)    │           │ │
│  │    │  (Port 5432)                     │           │ │
│  │    └──────────────────────────────────┘           │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 📓 Architecture Overview

- **Frontend Tier**: Flask web application serving HTML/CSS interface
- **Backend Tier**: REST API handling business logic
- **Database**: AWS RDS PostgreSQL (managed database service)
- **Load Balancer**: Application Load Balancer for high availability
- **Network**: Custom VPC with public and private subnets
- **Deployment**: Fully automated CI/CD pipeline with security scanning

## 🎯 Network Architecture
```
Internet
   │
   ↓
Application Load Balancer (Public Subnet)
   │
   ↓
EC2 Instance (Private Subnet)
   ├── Frontend Container (Port 8080)
   └── Backend Container (Port 5000)
       │
       ↓
RDS PostgreSQL (Private Subnet)
```

## 🍎 Live Application
[Live URL](http://cloud-blog-alb-1490947172.us-east-1.elb.amazonaws.com/)

## 📌 Features
- Create, read, update, and delete blog posts
- Responsive web interface
- Secure database storage
- Automated deployments
- Security scanning (Terraform & Docker images)
- High availability with load balancing

## 💻 Technology Stack
- **Frontend**: Python Flask, HTML, CSS
- **Backend**: Python Flask, REST API
- **Database**: PostgreSQL 15 (AWS RDS)
- **Infrastructure**: Terraform, AWS (VPC, EC2, RDS, ALB)
- **Containerization**: Docker, Docker Compose
- **CI/CD**: GitHub Actions
- **Security**: tfsec, Trivy

## 🍁 Prerequisites
- Docker Desktop
- AWS Account
- Docker Hub Account
- GitHub Account

## 🏃🏽‍♀️ Running Locally

1. Clone the repository:
```bash
    git clone https://github.com/ade1damola/cloud-blog-app.git
   cd cloud-blog-app
```

2. Start the application
```bash
    docker-compose up --build
```

3. Access the application:
- Open browser to [http://localhost:8080](http://localhost:8080)
- Backend API: [http://localhost:5000](http://localhost:5000)

4. Stop the application
```bash
    docker-compose down
```


## 🕸 Network Security
- **Private Subnets**: Application and database are isolated in private subnets with no direct internet access
- **NAT Gateway**: Enables private resources to access internet for updates without exposing them
- **Public Subnet**: Only the load balancer is internet-facing

## 🧱 Security Groups (Firewall Rules)
- **ALB Security Group**: Accepts HTTP (port 80) from anywhere, forwards to EC2
- **EC2 Security Group**: Only accepts traffic from ALB on port 8080, SSH from anywhere for deployment
- **RDS Security Group**: Only accepts PostgreSQL (port 5432) connections from EC2 instance

## ✒ Application Security
- Environment variables for sensitive data (no hardcoded credentials)
- Database password managed through GitHub Secrets
- Automated security scanning in CI/CD pipeline:
  - **tfsec**: Scans Terraform code for misconfigurations
  - **Trivy**: Scans Docker images for vulnerabilities

## 🚫 Data Protection
- RDS encryption at rest
- Terraform state stored encrypted in S3
- Private subnets prevent direct database access

## 📁 Project Structure
```
cloud-blog-app/
├── frontend/              # Frontend Flask application
├── backend/               # Backend REST API
├── terraform/             # Infrastructure as Code
├── .github/workflows/     # CI/CD pipeline
├── docker-compose.yml     # Local development setup
└── README.md             # This file
```

## 📨 CI/CD Pipeline
The pipeline runs automatically on every push to main:
- **Test**: Runs syntax checks on Python code
- **Security Scan**:
    - Scans Terraform code with tfsec
    - Scans Docker images with Trivy
- **Build**: Builds and pushes Docker images to Docker Hub
- **Deploy**:
    - Provisions/updates AWS infrastructure with Terraform
    - Deploys containers to EC2 instance


## 🏢 Infrastructure Details
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24
- **EC2 Instance**: t2.micro (free tier)
- **RDS Instance**: db.t3.micro PostgreSQL 15.4
- **Region**: us-east-1

## 🛹 Monitoring
- ALB Health Checks every 30 seconds
- Target considered healthy after 2 successful checks
- Target considered unhealthy after 2 failed checks

## 🧹 Cleanup
To destroy all AWS resources:
```bash
cd terraform
terraform destroy \
```

**Warning**: This will permanently delete all data.

## 💡 Reflection

### What inspired this project?
This project was created as part of the AWAKE 7.0 Cloud Engineering Bootcamp capstone to demonstrate mastery of cloud-native application development, infrastructure as code, and DevOps best practices.

### Biggest challenge
Implementing secure networking architecture with proper subnet isolation while maintaining connectivity between tiers. Understanding VPC routing, security groups, and the interaction between public/private subnets required careful planning.

### Key learnings
- Importance of security-first design (private subnets, security groups)
- Value of infrastructure as code for reproducibility
- Benefits of automated security scanning in CI/CD
- How to structure a production-grade cloud application

## 📝 License

This project is part of the AWAKE 7.0 Bootcamp capstone project.

## 👤 Author

- GitHub: [ade1damola](https://github.com/ade1damola)