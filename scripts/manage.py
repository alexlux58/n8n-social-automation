#!/usr/bin/env python3
import os
import sys
import subprocess
from datetime import datetime

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKUP_DIR = os.path.join(PROJECT_ROOT, "backups")
os.makedirs(BACKUP_DIR, exist_ok=True)

def run(cmd):
    print(f"> {cmd}")
    return subprocess.call(cmd, shell=True, cwd=PROJECT_ROOT)

def start():
    run("docker compose up -d")

def stop():
    run("docker compose down")

def restart():
    stop()
    start()

def status():
    run("docker compose ps")

def backup():
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    sql_file = os.path.join(BACKUP_DIR, f"n8n_{ts}.sql")
    tar_file = os.path.join(BACKUP_DIR, f"n8n_volumes_{ts}.tar.gz")

    print("Dumping Postgres DB...")
    run(f"docker compose exec -T postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > {sql_file}")

    print("Archiving volumes...")
    run(f"tar czf {tar_file} -C /var/lib/docker/volumes $(docker volume ls -q | grep n8n)")

    print(f"Backup complete: {sql_file}, {tar_file}")

def usage():
    print("Usage: manage.py [start|stop|restart|status|backup]")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    cmd = sys.argv[1].lower()
    if cmd == "start":
        start()
    elif cmd == "stop":
        stop()
    elif cmd == "restart":
        restart()
    elif cmd == "status":
        status()
    elif cmd == "backup":
        backup()
    else:
        usage()
