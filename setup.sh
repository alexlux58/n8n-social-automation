#!/bin/bash

# n8n Social Automation Setup Script
# This script sets up the complete environment for n8n Social Automation

set -e  # Exit on any error

echo "🚀 n8n Social Automation Setup"
echo "================================"

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

# Detect operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    print_error "Unsupported operating system: $OSTYPE"
    exit 1
fi

print_status "Detected OS: $OS ($DISTRO)"

# Function to install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    print_status "Installing Docker on Ubuntu/Debian..."
    
    # Update package list
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package list
    sudo apt-get update
    
    # Install Docker Engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker installed successfully"
}

# Function to install Docker on macOS
install_docker_macos() {
    print_status "Installing Docker on macOS..."
    
    if command -v brew &> /dev/null; then
        print_status "Installing Docker Desktop via Homebrew..."
        brew install --cask docker
        print_success "Docker Desktop installed via Homebrew"
        print_warning "Please start Docker Desktop from Applications folder"
    else
        print_warning "Homebrew not found. Please install Docker Desktop manually:"
        print_warning "1. Download from https://www.docker.com/products/docker-desktop/"
        print_warning "2. Or install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
}

# Function to check if Docker is running
check_docker_running() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker and try again."
        if [[ "$OS" == "macos" ]]; then
            print_warning "On macOS, please start Docker Desktop from Applications"
        else
            print_warning "On Linux, try: sudo systemctl start docker"
        fi
        exit 1
    fi
}

# Function to create .env file
setup_env_file() {
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            print_status "Creating .env file from .env.example..."
            cp .env.example .env
            print_success ".env file created"
            print_warning "Please edit .env file with your actual API keys and configuration"
        else
            print_error ".env.example file not found"
            exit 1
        fi
    else
        print_status ".env file already exists"
    fi
}

# Function to generate encryption key
generate_encryption_key() {
    if command -v openssl &> /dev/null; then
        echo $(openssl rand -hex 16)
    else
        # Fallback to Python
        python3 -c "import secrets; print(secrets.token_hex(16))"
    fi
}

# Function to update .env with generated values
update_env_file() {
    print_status "Updating .env file with generated values..."
    
    # Generate encryption key if not set
    if ! grep -q "N8N_ENCRYPTION_KEY=" .env || grep -q "your-32-character-encryption-key-here" .env; then
        ENCRYPTION_KEY=$(generate_encryption_key)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/your-32-character-encryption-key-here/$ENCRYPTION_KEY/" .env
        else
            sed -i "s/your-32-character-encryption-key-here/$ENCRYPTION_KEY/" .env
        fi
        print_success "Generated N8N_ENCRYPTION_KEY"
    fi
    
    # Generate secure password if not set
    if ! grep -q "POSTGRES_PASSWORD=" .env || grep -q "your-secure-password-here" .env; then
        DB_PASSWORD=$(generate_encryption_key)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/your-secure-password-here/$DB_PASSWORD/" .env
        else
            sed -i "s/your-secure-password-here/$DB_PASSWORD/" .env
        fi
        print_success "Generated secure database password"
    fi
}

# Main setup process
main() {
    print_status "Starting setup process..."
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        print_status "Docker not found. Installing Docker..."
        if [[ "$OS" == "linux" ]]; then
            if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
                install_docker_ubuntu
            else
                print_error "Unsupported Linux distribution: $DISTRO"
                print_error "Please install Docker manually for your distribution"
                exit 1
            fi
        elif [[ "$OS" == "macos" ]]; then
            install_docker_macos
        fi
    else
        print_success "Docker is already installed"
    fi
    
    # Check if Docker is running
    check_docker_running
    
    # Setup environment file
    setup_env_file
    update_env_file
    
    print_success "Setup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. Edit .env file with your actual API keys:"
    echo "   - OPENAI_API_KEY: Get from https://platform.openai.com/api-keys"
    echo "   - Update other configuration as needed"
    echo ""
    echo "2. Start the services:"
    echo "   python3 scripts/manage.py start"
    echo ""
    echo "3. Open n8n UI:"
    echo "   http://localhost:5678"
    echo ""
    echo "4. Import workflow:"
    echo "   - Import the workflow.json file into n8n"
    echo "   - Configure your API credentials in n8n"
    echo ""
    print_warning "Note: You may need to log out and back in for Docker group changes to take effect on Linux"
}

# Run main function
main "$@"
