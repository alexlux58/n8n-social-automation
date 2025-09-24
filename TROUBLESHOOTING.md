# n8n Social Automation - Troubleshooting Guide

## Common Issues and Solutions

### 1. Docker Permission Issues

#### Problem: `permission denied while trying to connect to the Docker daemon socket`

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker daemon
sudo systemctl start docker
sudo systemctl enable docker

# Log out and back in, or run:
newgrp docker

# Test Docker access
docker ps
```

**Alternative (temporary fix):**
```bash
sudo chmod 666 /var/run/docker.sock
```

### 2. Services Not Starting

#### Problem: Services show as "already running" but `docker ps` shows no containers

**Solution:**
```bash
# Force cleanup and restart
python3 scripts/manage.py stop
docker system prune -f
python3 scripts/manage.py start
```

#### Problem: Docker Compose version warning

**Solution:** Fixed in latest version - the `version: "3.9"` line has been removed from docker-compose.yml

### 3. Network Access Issues

#### Problem: Cannot access n8n from other machines in network

**Check:**
```bash
# Verify port binding
docker ps
# Should show: 0.0.0.0:5678->5678/tcp

# Check firewall
sudo ufw status
# Should allow: 5678/tcp

# Test connectivity
telnet 192.168.4.210 5678
```

**Solution:**
```bash
# Allow port in firewall
sudo ufw allow from 192.168.4.0/22 to any port 5678

# Restart services
python3 scripts/manage.py restart
```

### 4. Environment Configuration Issues

#### Problem: Missing .env file

**Solution:**
```bash
# Create from template
cp .env.example .env

# Edit with your values
nano .env
```

#### Problem: Wrong IP configuration

**Check .env file:**
```bash
cat .env | grep -E "(N8N_HOST|WEBHOOK_URL)"
# Should show:
# N8N_HOST=192.168.4.210
# WEBHOOK_URL=http://192.168.4.210:5678/
```

### 5. Service Status Issues

#### Check service status:
```bash
python3 scripts/manage.py status
docker ps
docker compose ps
```

#### View logs:
```bash
python3 scripts/manage.py logs
docker compose logs
```

#### Restart services:
```bash
python3 scripts/manage.py restart
```

### 6. Complete Reset

#### If everything is broken:
```bash
# Complete cleanup
python3 scripts/manage.py cleanup

# Or use the script
./cleanup.sh

# Fresh setup
./setup.sh
python3 scripts/manage.py start
```

### 7. Docker Daemon Issues

#### Check Docker daemon status:
```bash
sudo systemctl status docker
```

#### Start Docker daemon:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

#### Check Docker daemon logs:
```bash
sudo journalctl -u docker.service
```

### 8. Port Conflicts

#### Check if port 5678 is in use:
```bash
sudo netstat -tlnp | grep 5678
sudo lsof -i :5678
```

#### Kill process using port:
```bash
sudo kill -9 <PID>
```

### 9. Volume Issues

#### Check Docker volumes:
```bash
docker volume ls
```

#### Remove specific volumes:
```bash
docker volume rm <volume_name>
```

#### Clean all volumes:
```bash
docker volume prune -f
```

### 10. Image Issues

#### Check Docker images:
```bash
docker images
```

#### Remove specific images:
```bash
docker rmi <image_name>
```

#### Clean all images:
```bash
docker image prune -a -f
```

## Quick Fix Scripts

### Fix Permissions and Start Services
```bash
./fix-permissions.sh
```

### Complete Reset
```bash
./cleanup.sh
./setup.sh
python3 scripts/manage.py start
```

### Check Everything
```bash
python3 scripts/manage.py status
python3 scripts/manage.py logs
docker ps
docker volume ls
```

## Diagnostic Commands

### System Information
```bash
# OS version
cat /etc/os-release

# Docker version
docker --version
docker compose version

# User groups
groups $USER

# Docker daemon status
sudo systemctl status docker
```

### Network Information
```bash
# IP address
ip addr show

# Port binding
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Firewall status
sudo ufw status verbose
```

### Service Information
```bash
# Container status
docker ps -a

# Service logs
docker compose logs

# Resource usage
docker stats
```

## Getting Help

### Check Logs
```bash
# Application logs
python3 scripts/manage.py logs

# Docker logs
docker compose logs

# System logs
sudo journalctl -u docker.service
```

### Verify Configuration
```bash
# Environment variables
cat .env

# Docker Compose configuration
docker compose config

# Service status
python3 scripts/manage.py status
```

### Test Connectivity
```bash
# Local access
curl -I http://localhost:5678

# Network access
curl -I http://192.168.4.210:5678

# Port check
telnet 192.168.4.210 5678
```

## Prevention

### Regular Maintenance
```bash
# Clean up Docker system
docker system prune -f

# Check service health
python3 scripts/manage.py status

# Monitor logs
python3 scripts/manage.py logs | grep -i error
```

### Backup Before Changes
```bash
# Create backup
python3 scripts/manage.py backup

# Before major changes
./cleanup.sh
# (only if you want to start fresh)
```
