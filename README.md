# n8n Social Automation

Automated pipeline for daily DevSecOps/CCNA content:
- Generates posts with GPT-5
- Creates visuals with OpenAI Images
- Schedules via Buffer
- Logs to Google Sheets

## Setup

1. Copy `.env.example` to `.env` and fill values:
   ```bash
   cp .env.example .env
   nano .env
   ```

2. Start stack:
   ```bash
   python3 scripts/manage.py start
   ```

3. Open UI:
   ```
   http://<server-ip>:5678
   ```

4. Import the workflow JSON (`workflow.json`) from this repo into n8n.

## Commands

- `python3 scripts/manage.py start`
- `python3 scripts/manage.py stop`
- `python3 scripts/manage.py restart`
- `python3 scripts/manage.py status`
- `python3 scripts/manage.py backup`

Backups go into `backups/` folder with DB dump + volumes tarball.
