#!/usr/bin/env python3
import os
import sys
import subprocess
import platform
import shutil
from datetime import datetime

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKUP_DIR = os.path.join(PROJECT_ROOT, "backups")
os.makedirs(BACKUP_DIR, exist_ok=True)

def run(cmd, check=True):
    print(f"> {cmd}")
    result = subprocess.call(cmd, shell=True, cwd=PROJECT_ROOT)
    if check and result != 0:
        print(f"Command failed with exit code {result}")
        sys.exit(result)
    return result

def check_command(cmd):
    """Check if a command exists in PATH"""
    return shutil.which(cmd) is not None

def install_docker_ubuntu():
    """Install Docker and Docker Compose on Ubuntu/Debian systems"""
    print("Installing Docker and Docker Compose on Ubuntu...")
    
    # Update package list
    run("sudo apt-get update")
    
    # Install prerequisites
    run("sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release")
    
    # Add Docker's official GPG key
    run("curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg")
    
    # Add Docker repository
    run('echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null')
    
    # Update package list again
    run("sudo apt-get update")
    
    # Install Docker Engine
    run("sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin")
    
    # Add current user to docker group
    run("sudo usermod -aG docker $USER")
    
    # Start and enable Docker service
    run("sudo systemctl start docker")
    run("sudo systemctl enable docker")
    
    print("Docker installation completed. You may need to log out and back in for group changes to take effect.")

def install_docker_macos():
    """Install Docker Desktop on macOS"""
    print("Installing Docker Desktop on macOS...")
    
    if check_command("brew"):
        run("brew install --cask docker")
        print("Docker Desktop installed via Homebrew. Please start Docker Desktop from Applications.")
    else:
        print("Homebrew not found. Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop/")
        print("Or install Homebrew first: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")

def check_dependencies():
    """Check and install required dependencies"""
    print("Checking dependencies...")
    
    # Check for .env file
    env_file = os.path.join(PROJECT_ROOT, ".env")
    if not os.path.exists(env_file):
        env_example = os.path.join(PROJECT_ROOT, ".env.example")
        if os.path.exists(env_example):
            print("Creating .env file from .env.example...")
            run(f"cp {env_example} {env_file}")
            print("Please edit .env file with your actual values before starting the services.")
            return False
        else:
            print("No .env.example file found. Please create a .env file with required environment variables.")
            return False
    
    # Check for Docker
    if not check_command("docker"):
        print("Docker not found. Installing Docker...")
        system = platform.system().lower()
        if system == "linux":
            # Check if it's Ubuntu/Debian
            try:
                with open("/etc/os-release", "r") as f:
                    if "ubuntu" in f.read().lower() or "debian" in f.read().lower():
                        install_docker_ubuntu()
                    else:
                        print("Unsupported Linux distribution. Please install Docker manually.")
                        return False
            except:
                print("Cannot determine Linux distribution. Please install Docker manually.")
                return False
        elif system == "darwin":
            install_docker_macos()
        else:
            print(f"Unsupported operating system: {system}. Please install Docker manually.")
            return False
        
        print("Docker installation completed. Please restart your terminal or log out and back in.")
        return False
    
    # Check for Docker Compose
    if not check_command("docker") or run("docker compose version", check=False) != 0:
        print("Docker Compose not found or not working properly.")
        if platform.system().lower() == "linux":
            print("Installing Docker Compose plugin...")
            run("sudo apt-get update")
            run("sudo apt-get install -y docker-compose-plugin")
        else:
            print("Please ensure Docker Desktop is installed and running.")
            return False
    
    print("All dependencies are satisfied.")
    return True

def setup():
    """Setup the project by checking and installing dependencies"""
    print("Setting up n8n Social Automation...")
    
    if not check_dependencies():
        print("\nSetup incomplete. Please address the issues above and run 'python3 scripts/manage.py setup' again.")
        return False
    
    print("\nSetup completed successfully!")
    print("Next steps:")
    print("1. Edit .env file with your actual API keys and configuration")
    print("2. Run 'python3 scripts/manage.py start' to start the services")
    print("3. Open http://localhost:5678 in your browser")
    print("4. Import the workflow.json file into n8n")
    return True

def start():
    """Start the n8n services"""
    print("Starting n8n Social Automation services...")
    
    # Check dependencies first
    if not check_dependencies():
        print("Dependencies not satisfied. Run 'python3 scripts/manage.py setup' first.")
        return False
    
    # Check if services are already running
    result = run("docker compose ps --format json", check=False)
    if result == 0:
        print("Services are already running. Use 'restart' to restart them.")
        return True
    
    run("docker compose up -d")
    print("Services started successfully!")
    print("n8n UI available at: http://localhost:5678")
    return True

def stop():
    """Stop the n8n services"""
    print("Stopping n8n Social Automation services...")
    run("docker compose down")
    print("Services stopped.")

def restart():
    """Restart the n8n services"""
    print("Restarting n8n Social Automation services...")
    stop()
    start()

def status():
    """Show status of n8n services"""
    print("n8n Social Automation Status:")
    run("docker compose ps")

def logs():
    """Show logs from n8n services"""
    print("Showing n8n logs (press Ctrl+C to exit):")
    run("docker compose logs -f")

def backup():
    """Create backup of n8n data"""
    print("Creating backup...")
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    sql_file = os.path.join(BACKUP_DIR, f"n8n_{ts}.sql")
    tar_file = os.path.join(BACKUP_DIR, f"n8n_volumes_{ts}.tar.gz")

    print("Dumping Postgres DB...")
    run(f"docker compose exec -T postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > {sql_file}")

    print("Archiving volumes...")
    run(f"tar czf {tar_file} -C /var/lib/docker/volumes $(docker volume ls -q | grep n8n)")

    print(f"Backup complete: {sql_file}, {tar_file}")

def usage():
    print("n8n Social Automation Management Script")
    print("Usage: python3 scripts/manage.py [command]")
    print("\nCommands:")
    print("  setup   - Check and install dependencies")
    print("  start   - Start the n8n services")
    print("  stop    - Stop the n8n services")
    print("  restart - Restart the n8n services")
    print("  status  - Show status of services")
    print("  logs    - Show logs from services")
    print("  backup  - Create backup of n8n data")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    cmd = sys.argv[1].lower()
    if cmd == "setup":
        setup()
    elif cmd == "start":
        start()
    elif cmd == "stop":
        stop()
    elif cmd == "restart":
        restart()
    elif cmd == "status":
        status()
    elif cmd == "logs":
        logs()
    elif cmd == "backup":
        backup()
    else:
        usage()
        sys.exit(1)
