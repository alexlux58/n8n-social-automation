# n8n Social Automation

Automated pipeline for daily DevSecOps/CCNA content:
- Generates posts with GPT-5
- Creates visuals with OpenAI Images
- Schedules via Buffer
- Logs to Google Sheets

## Quick Start

### Option 1: Automated Setup (Recommended)
```bash
# Run the automated setup script
./setup.sh
```

### Option 2: Manual Setup
```bash
# 1. Setup dependencies
python3 scripts/manage.py setup

# 2. Edit configuration
nano .env

# 3. Start services
python3 scripts/manage.py start
```

## Detailed Setup

### Prerequisites
- Python 3.6+
- Docker and Docker Compose
- OpenAI API key
- Buffer account (for social media scheduling)
- Google account (for Sheets logging)

### Step-by-Step Setup

1. **Clone and navigate to the project:**
   ```bash
   git clone <repository-url>
   cd n8n-social-automation
   ```

2. **Run automated setup:**
   ```bash
   ./setup.sh
   ```
   
   This script will:
   - Install Docker and Docker Compose (if not present)
   - Create `.env` file from `.env.example`
   - Generate secure encryption keys and passwords
   - Set up the complete environment

3. **Configure your API keys:**
   ```bash
   nano .env
   ```
   
   Required configuration:
   - `OPENAI_API_KEY`: Get from [OpenAI Platform](https://platform.openai.com/api-keys)
   - `N8N_HOST`: Your server's IP or domain
   - `WEBHOOK_URL`: Full URL to your n8n instance
   - Other settings as needed

4. **Start the services:**
   ```bash
   python3 scripts/manage.py start
   ```

5. **Access n8n UI:**
   ```
   http://localhost:5678
   ```

6. **Import the workflow:**
   - In n8n, go to Workflows → Import from File
   - Select `workflow.json` from this repository
   - Configure your API credentials in n8n

## Management Commands

| Command | Description |
|---------|-------------|
| `python3 scripts/manage.py setup` | Check and install dependencies |
| `python3 scripts/manage.py start` | Start the n8n services |
| `python3 scripts/manage.py stop` | Stop the n8n services |
| `python3 scripts/manage.py restart` | Restart the n8n services |
| `python3 scripts/manage.py status` | Show status of services |
| `python3 scripts/manage.py logs` | Show logs from services |
| `python3 scripts/manage.py backup` | Create backup of n8n data |
| `python3 scripts/manage.py cleanup` | Complete cleanup (removes all data) |

## Configuration

### Environment Variables

The `.env` file contains all configuration. Key variables:

- **Database**: PostgreSQL credentials
- **n8n**: Host, port, encryption key
- **OpenAI**: API key for GPT-5 and image generation
- **Timezone**: Default is America/Los_Angeles

### API Credentials Setup

1. **OpenAI API**: 
   - Get API key from [OpenAI Platform](https://platform.openai.com/api-keys)
   - Add to `OPENAI_API_KEY` in `.env`

2. **Buffer API** (in n8n UI):
   - Go to Credentials → Add Credential → OAuth2 API
   - Configure Buffer OAuth2 credentials
   - Update profile IDs in workflow nodes

3. **Google Sheets** (in n8n UI):
   - Go to Credentials → Add Credential → Google API
   - Configure Google OAuth2 credentials
   - Update sheet ID in workflow

## Backup and Restore

### Automatic Backups
```bash
python3 scripts/manage.py backup
```

Backups are stored in `backups/` directory:
- Database dump: `n8n_YYYYMMDD_HHMMSS.sql`
- Volumes archive: `n8n_volumes_YYYYMMDD_HHMMSS.tar.gz`

### Manual Backup
```bash
# Database backup
docker compose exec postgres pg_dump -U n8n n8n > backup.sql

# Volumes backup
tar czf volumes_backup.tar.gz -C /var/lib/docker/volumes $(docker volume ls -q | grep n8n)
```

## Cleanup

### Complete Cleanup
```bash
# Remove all containers, volumes, and data
python3 scripts/manage.py cleanup

# Or use the standalone script
./cleanup.sh
```

**Warning**: Cleanup permanently removes all n8n data, workflows, and configurations.

## Troubleshooting

### Docker Issues
```bash
# Check Docker status
sudo systemctl status docker

# Start Docker service
sudo systemctl start docker

# Check Docker Compose
docker compose version
```

### Permission Issues
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Log out and back in
```

### Service Issues
```bash
# Check service status
python3 scripts/manage.py status

# View logs
python3 scripts/manage.py logs

# Restart services
python3 scripts/manage.py restart
```

## Workflow Configuration

The workflow (`workflow.json`) includes:
- **Daily trigger**: Runs at 9:00 AM PT
- **Content generation**: GPT-5 creates educational posts
- **Image creation**: OpenAI DALL-E generates visuals
- **Social scheduling**: Buffer posts to LinkedIn, Twitter, Instagram
- **Logging**: Google Sheets tracks all content

### Customizing Content
Edit the topic list in the "Pick Topic" node to change content themes.

### Scheduling
Modify the cron trigger to change posting frequency or time.

## Support

For issues:
1. Check the logs: `python3 scripts/manage.py logs`
2. Verify configuration in `.env`
3. Ensure all API credentials are properly configured in n8n
4. Check Docker service status
