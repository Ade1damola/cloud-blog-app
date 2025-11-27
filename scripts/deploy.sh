#!/bin/bash
set -e

# This script runs on EC2 to deploy the application

cd /home/ec2-user/app

# Stop existing containers
docker-compose down 2>/dev/null || true

# Create docker-compose.yml from environment variables
cat > docker-compose.yml << EOF
version: '3.8'
services:
  backend:
    image: ${DOCKER_USERNAME}/cloud-blog-backend:latest
    ports:
      - "5000:5000"
    environment:
      DB_HOST: ${DB_HOST}
      DB_NAME: blogdb
      DB_USER: postgres
      DB_PASSWORD: ${DB_PASSWORD}
    restart: always
  
  frontend:
    image: ${DOCKER_USERNAME}/cloud-blog-frontend:latest
    ports:
      - "8080:8080"
    environment:
      BACKEND_URL: http://backend:5000
    depends_on:
      - backend
    restart: always
EOF

# Pull and start
docker-compose pull
docker-compose up -d

echo "Deployment complete"
docker-compose ps