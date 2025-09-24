# n8n Social Automation - Deployment Guide

## Network Configuration for 192.168.4.210

This guide covers deploying n8n Social Automation on `192.168.4.210` with access from the `192.168.4.0/22` network.

## Quick Deployment

### 1. Automated Setup
```bash
# On the server (192.168.4.210)
./setup.sh
```

### 2. Configure for Network Access
The system is already configured to:
- Bind to all interfaces (`0.0.0.0:5678`)
- Use IP `192.168.4.210` in environment variables
- Allow access from `192.168.4.0/22` network

### 3. Start Services
```bash
python3 scripts/manage.py start
```

### 4. Access from Network
- **n8n UI**: `http://192.168.4.210:5678`
- **Webhook URL**: `http://192.168.4.210:5678/`

## Network Configuration Details

### Docker Compose Configuration
The `docker-compose.yml` is configured to:
```yaml
ports:
  - "0.0.0.0:${N8N_PORT}:5678"  # Binds to all interfaces
```

### Environment Variables
The `.env.example` is pre-configured with:
```bash
N8N_HOST=192.168.4.210
WEBHOOK_URL=http://192.168.4.210:5678/
```

## Firewall Configuration

### Ubuntu/Debian (UFW)
```bash
# Allow n8n port from local network
sudo ufw allow from 192.168.4.0/22 to any port 5678

# Check status
sudo ufw status
```

### CentOS/RHEL (firewalld)
```bash
# Allow n8n port from local network
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.4.0/22' port protocol='tcp' port='5678' accept"
sudo firewall-cmd --reload

# Check status
sudo firewall-cmd --list-rich-rules
```

### iptables (if using directly)
```bash
# Allow n8n port from local network
sudo iptables -A INPUT -s 192.168.4.0/22 -p tcp --dport 5678 -j ACCEPT

# Save rules (Ubuntu/Debian)
sudo iptables-save > /etc/iptables/rules.v4
```

## Deployment Commands

### Management Commands
```bash
# Setup (first time)
python3 scripts/manage.py setup

# Start services
python3 scripts/manage.py start

# Check status
python3 scripts/manage.py status

# View logs
python3 scripts/manage.py logs

# Stop services
python3 scripts/manage.py stop

# Restart services
python3 scripts/manage.py restart

# Create backup
python3 scripts/manage.py backup

# Complete cleanup
python3 scripts/manage.py cleanup
```

### Alternative Cleanup
```bash
# Use the standalone cleanup script
./cleanup.sh
```

## Network Access Verification

### From Client Machines (192.168.4.0/22)
```bash
# Test connectivity
curl -I http://192.168.4.210:5678

# Check if port is open
telnet 192.168.4.210 5678

# Test from browser
# Navigate to: http://192.168.4.210:5678
```

### From Server (192.168.4.210)
```bash
# Check if service is listening
netstat -tlnp | grep 5678
ss -tlnp | grep 5678

# Test local access
curl -I http://localhost:5678
curl -I http://192.168.4.210:5678
```

## Troubleshooting Network Access

### 1. Check Docker Container Status
```bash
python3 scripts/manage.py status
docker ps
```

### 2. Check Port Binding
```bash
# Should show 0.0.0.0:5678
docker port n8n
```

### 3. Check Firewall Rules
```bash
# Ubuntu/Debian
sudo ufw status verbose

# CentOS/RHEL
sudo firewall-cmd --list-all
```

### 4. Check Network Connectivity
```bash
# From client machine
ping 192.168.4.210
telnet 192.168.4.210 5678
```

### 5. Check Docker Logs
```bash
python3 scripts/manage.py logs
```

## Security Considerations

### 1. Network Access Control
- Only allow access from `192.168.4.0/22` network
- Consider using VPN for remote access
- Implement authentication for n8n

### 2. Firewall Rules
```bash
# Restrict to specific network only
sudo ufw allow from 192.168.4.0/22 to any port 5678
sudo ufw deny 5678
```

### 3. SSL/TLS (Optional)
For production use, consider:
- Setting up reverse proxy (nginx/Apache)
- Using SSL certificates
- Configuring HTTPS

## Backup and Recovery

### Automatic Backup
```bash
python3 scripts/manage.py backup
```

### Manual Backup
```bash
# Database backup
docker compose exec postgres pg_dump -U n8n n8n > backup.sql

# Volumes backup
tar czf volumes_backup.tar.gz -C /var/lib/docker/volumes $(docker volume ls -q | grep n8n)
```

### Restore from Backup
```bash
# Stop services
python3 scripts/manage.py stop

# Restore database
docker compose up -d postgres
docker compose exec -T postgres psql -U n8n n8n < backup.sql

# Restore volumes
tar xzf volumes_backup.tar.gz -C /var/lib/docker/volumes/

# Start services
python3 scripts/manage.py start
```

## Monitoring and Maintenance

### Health Checks
```bash
# Check service health
python3 scripts/manage.py status

# Check logs for errors
python3 scripts/manage.py logs | grep -i error

# Check disk usage
df -h
docker system df
```

### Regular Maintenance
```bash
# Clean up old backups (older than 30 days)
find backups/ -name "*.sql" -mtime +30 -delete
find backups/ -name "*.tar.gz" -mtime +30 -delete

# Clean up Docker system
docker system prune -f
```

## API Configuration

### Webhook URLs
Configure webhooks to use:
```
http://192.168.4.210:5678/webhook/[webhook-name]
```

### External API Access
For external services to access n8n:
- Use `http://192.168.4.210:5678` as the base URL
- Ensure firewall allows the specific IP ranges
- Consider using a domain name with DNS resolution

## Support

For deployment issues:
1. Check service status: `python3 scripts/manage.py status`
2. Check logs: `python3 scripts/manage.py logs`
3. Verify network connectivity from client machines
4. Check firewall rules
5. Verify Docker container is running and bound to correct interface
