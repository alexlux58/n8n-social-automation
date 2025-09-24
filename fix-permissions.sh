#!/bin/bash

# n8n Social Automation - Fix Permissions Script
# This script fixes Docker permission issues and starts the services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔧 n8n Social Automation - Fix Permissions"
echo "=========================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

# Get current user
CURRENT_USER=$(whoami)
print_status "Current user: $CURRENT_USER"

# Check if user is in docker group
if groups $CURRENT_USER | grep -q docker; then
    print_success "User $CURRENT_USER is already in docker group"
else
    print_warning "User $CURRENT_USER is not in docker group"
    print_status "Adding user to docker group..."
    
    # Add user to docker group
    sudo usermod -aG docker $CURRENT_USER
    
    print_success "User added to docker group"
    print_warning "You need to log out and back in for group changes to take effect"
    print_status "Or run: newgrp docker"
fi

# Check Docker daemon status
print_status "Checking Docker daemon status..."
if sudo systemctl is-active --quiet docker; then
    print_success "Docker daemon is running"
else
    print_warning "Docker daemon is not running. Starting it..."
    sudo systemctl start docker
    sudo systemctl enable docker
    print_success "Docker daemon started and enabled"
fi

# Test Docker access
print_status "Testing Docker access..."
if docker ps &> /dev/null; then
    print_success "Docker access is working"
else
    print_error "Docker access is not working. Try:"
    echo "1. Log out and back in"
    echo "2. Or run: newgrp docker"
    echo "3. Or run: sudo chmod 666 /var/run/docker.sock"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from .env.example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success ".env file created"
        print_warning "Please edit .env file with your actual API keys"
    else
        print_error ".env.example file not found"
        exit 1
    fi
fi

# Start services
print_status "Starting n8n services..."
python3 scripts/manage.py start

if [ $? -eq 0 ]; then
    print_success "Services started successfully!"
    print_status "n8n UI available at: http://192.168.4.210:5678"
    print_status "Check status with: python3 scripts/manage.py status"
else
    print_error "Failed to start services"
    print_status "Check logs with: python3 scripts/manage.py logs"
    exit 1
fi
