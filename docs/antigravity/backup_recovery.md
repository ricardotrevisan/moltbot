# Backup & Recovery Strategy

This document outlines the critical components, state files, and procedures for backing up and restoring the **OpenClaw (Moltbot)** and **N8N** agent ecosystem.

## Critical Components

### 1. Configuration & Secrets
These files contain API keys, credentials, and environment-specific settings. **Loss of these files requires regenerating all credentials.**

| File Path | Description | Stack |
| :--- | :--- | :--- |
| `moltbot/.env` | Core secrets for OpenClaw. | Moltbot |
| `moltbot/.env.voice` | API keys for Voice Backend (OpenAI, etc.). | Moltbot |
| `moltbot/docker-compose.yml` | Service definitions and network config. | Moltbot |
| `n8n-scrapy-stack/.env` | Secrets for N8N, Postgres, and Scrapers. | N8N |
| `n8n-scrapy-stack/docker-compose.yml` | Stack definition for N8N ecosystem. | N8N |

### 2. Agent Definitions (Knowledge Base)
These files define *who* the agent is and its core behavior.

| Directory | Description | Stack |
| :--- | :--- | :--- |
| `moltbot/persona/` | Markdown files defining identity, memory, and prompts. | Moltbot |

### 3. Runtime State (Persistence)
These directories contain dynamic data created during operation (sessions, learned memory, databases).

| Path/Volume | Description | Stack | Type |
| :--- | :--- | :--- | :--- |
| `moltbot/data/config/` | WhatsApp sessions, device keys, local vector store. | Moltbot | Directory |
| `n8n-scrapy-stack/x-scrapper/session.json` | Authenticated Twitter/X session cookies. | N8N | File |
| `postgres_data` | **VOLUME**: Main vector database and application data. | N8N | Named Volume |
| `n8n_data_transcription` | **VOLUME**: N8N workflows, credentials, and execution history. | N8N | Named Volume |

## Backup Procedures

### Quick File Backup (Scriptable)
This backs up all configuration and file-based state. Run this from the parent directory containing both repositories.

```bash
# Create a timestamped backup archive
tar -czvf "backup_$(date +%Y%m%d_%H%M%S).tar.gz" \
  moltbot/.env \
  moltbot/.env.voice \
  moltbot/docker-compose.yml \
  moltbot/persona/ \
  moltbot/data/config/ \
  n8n-scrapy-stack/.env \
  n8n-scrapy-stack/docker-compose.yml \
  n8n-scrapy-stack/x-scrapper/session.json
```

### Full Data Backup (Including Docker Volumes)
Because `postgres` and `n8n` use **Docker Named Volumes**, simply copying files is not enough. You must export the volume data.

#### Option A: `docker run` Export (Universal)
```bash
# Backup Postgres Volume
docker run --rm -v postgres_data:/volume -v $(pwd):/backup alpine \
  tar -czf /backup/postgres_data_backup.tar.gz -C /volume .

# Backup N8N Data Volume
docker run --rm -v n8n_data_transcription:/volume -v $(pwd):/backup alpine \
  tar -czf /backup/n8n_data_backup.tar.gz -C /volume .
```

#### Option B: PG_DUMP (Database Only)
For a cleaner database backup (SQL format):
```bash
docker exec postgres_n8n pg_dumpall -U n8n > full_backup.sql
```

## Recovery Procedures

### 1. Restore Files
Extract the file archive to your repository location:
```bash
tar -xzvf backup_YYYYMMDD_HHMMSS.tar.gz
```

### 2. Restore Docker Volumes
If you are moving to a new machine or recovering from data loss, you must manually populate the volumes **before** starting containers.

```bash
# Create the volumes first
docker volume create postgres_data
docker volume create n8n_data_transcription

# Restore Postgres Data
docker run --rm -v postgres_data:/volume -v $(pwd):/backup alpine \
  sh -c "rm -rf /volume/* && tar -C /volume -xzf /backup/postgres_data_backup.tar.gz"

# Restore N8N Data
docker run --rm -v n8n_data_transcription:/volume -v $(pwd):/backup alpine \
  sh -c "rm -rf /volume/* && tar -C /volume -xzf /backup/n8n_data_backup.tar.gz"
```

### 3. Re-initialize Infrastructure
```bash
# 1. Start N8N Stack (Database & Network)
cd n8n-scrapy-stack
docker compose up -d

# 2. Start Moltbot (Agent)
cd ../moltbot
docker compose up -d
```
