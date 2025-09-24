#!/bin/bash

# n8n Social Automation - Cleanup Script
# This script completely removes all n8n containers, volumes, and data

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

echo "🧹 n8n Social Automation - Cleanup Script"
echo "=========================================="
echo ""
print_warning "This script will completely remove:"
echo "  - All n8n containers"
echo "  - All n8n volumes and data"
echo "  - All n8n images"
echo "  - Backup files (optional)"
echo ""

# Confirmation prompt
read -p "Are you sure you want to proceed? This action cannot be undone! (yes/no): " confirm
if [[ $confirm != "yes" ]]; then
    print_status "Cleanup cancelled."
    exit 0
fi

echo ""
print_status "Starting cleanup process..."

# Stop and remove containers
print_status "Stopping and removing containers..."
if docker compose ps -q &> /dev/null; then
    docker compose down --volumes --remove-orphans
    print_success "Containers stopped and removed"
else
    print_status "No containers found to remove"
fi

# Remove n8n-specific containers (in case they exist outside compose)
print_status "Removing any remaining n8n containers..."
docker ps -a --filter "name=n8n" --format "{{.Names}}" | xargs -r docker rm -f
docker ps -a --filter "name=postgres" --filter "label=com.docker.compose.project" --format "{{.Names}}" | xargs -r docker rm -f

# Remove volumes
print_status "Removing n8n volumes..."
docker volume ls -q | grep -E "(n8n|postgres)" | xargs -r docker volume rm
print_success "Volumes removed"

# Remove images
print_status "Removing n8n images..."
docker images --filter "reference=n8nio/n8n" --format "{{.Repository}}:{{.Tag}}" | xargs -r docker rmi -f
docker images --filter "reference=postgres" --filter "label=com.docker.compose.project" --format "{{.Repository}}:{{.Tag}}" | xargs -r docker rmi -f
print_success "Images removed"

# Clean up Docker system (optional)
print_status "Cleaning up Docker system..."
docker system prune -f
print_success "Docker system cleaned"

# Remove backup files (optional)
if [ -d "backups" ] && [ "$(ls -A backups 2>/dev/null)" ]; then
    echo ""
    read -p "Remove backup files in backups/ directory? (yes/no): " remove_backups
    if [[ $remove_backups == "yes" ]]; then
        print_status "Removing backup files..."
        rm -rf backups/*
        print_success "Backup files removed"
    else
        print_status "Backup files preserved"
    fi
fi

# Remove .env file (optional)
if [ -f ".env" ]; then
    echo ""
    read -p "Remove .env configuration file? (yes/no): " remove_env
    if [[ $remove_env == "yes" ]]; then
        print_status "Removing .env file..."
        rm -f .env
        print_success ".env file removed"
    else
        print_status ".env file preserved"
    fi
fi

# Final cleanup
print_status "Performing final cleanup..."
docker network prune -f
print_success "Network cleanup completed"

echo ""
print_success "🎉 Cleanup completed successfully!"
echo ""
print_status "Summary of what was removed:"
echo "  ✅ All n8n containers"
echo "  ✅ All n8n volumes and data"
echo "  ✅ All n8n images"
echo "  ✅ Docker system cleanup"
echo ""
print_status "To start fresh:"
echo "  1. Run: ./setup.sh"
echo "  2. Edit .env with your configuration"
echo "  3. Run: python3 scripts/manage.py start"
echo ""
print_warning "Note: All n8n workflows and data have been permanently deleted."
