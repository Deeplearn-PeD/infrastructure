# EpidBot DuckDB Backup Plan

## Overview

This document describes the backup strategy for EpidBot's DuckDB database, which stores:
- User accounts and authentication data
- Chat sessions and message history
- User configurations and preferences

## Backup Components

### 1. Automated Server-Side Backups

**Script**: `/opt/kwar-ai/epidbot/scripts/epidbot-backup.sh`

**Schedule**: Daily at 2:00 AM (configured via cron)

**Location**: `/opt/kwar-ai/epidbot/backups/`

**Retention**: 7 days (configurable via `RETENTION_DAYS` env var)

**Features**:
- Automatic retry on database lock (3 attempts, 10s delay)
- Gzip compression
- Automatic cleanup of old backups
- Logging to `/var/log/epidbot-backup.log`

### 2. Full System Backups

**Script**: `scripts/backup.sh` (run manually)

**Contents**:
- `epidbot_data.tar.gz` - Full data directory (includes DuckDB)
- `epidbot_duckdb.duckdb.gz` - Explicit DuckDB backup

**Location**: `./backups/YYYYMMDD_HHMMSS/`

### 3. Remote Backup Management

**Script**: `scripts/epidbot-backup-manage.sh`

**Commands**:
```bash
./scripts/epidbot-backup-manage.sh backup       # Create backup on server
./scripts/epidbot-backup-manage.sh status       # Show backup status
./scripts/epidbot-backup-manage.sh list         # List available backups
./scripts/epidbot-backup-manage.sh restore 1    # Restore from backup
./scripts/epidbot-backup-manage.sh download     # Download latest backup
./scripts/epidbot-backup-manage.sh download-all # Download all backups
./scripts/epidbot-backup-manage.sh logs         # View backup logs
```

## Backup Schedule

| Type | Schedule | Retention | Location |
|------|----------|-----------|----------|
| Daily DuckDB | 2:00 AM | 7 days | Server: `/opt/kwar-ai/epidbot/backups/` |
| Full system | Manual | Indefinite | Local: `./backups/` |

## Recovery Procedures

### Quick Recovery (from server backups)

```bash
# List available backups
./scripts/epidbot-backup-manage.sh list

# Restore from backup (stops EpidBot automatically)
./scripts/epidbot-backup-manage.sh restore 1
```

### Manual Recovery on Server

```bash
# SSH to server
ssh root@204.168.149.153

# List backups
/opt/kwar-ai/epidbot/scripts/epidbot-restore.sh list

# Restore from backup
/opt/kwar-ai/epidbot/scripts/epidbot-restore.sh restore <backup_file>
```

### Recovery from Local Backup

```bash
# Upload backup to server
scp -i ssh_keys/kwar-ai-ssh-key \
    ./backups/20240101_120000/epidbot_duckdb.duckdb.gz \
    root@204.168.149.153:/opt/kwar-ai/epidbot/backups/

# SSH and restore
ssh -i ssh_keys/kwar-ai-ssh-key root@204.168.149.153
/opt/kwar-ai/epidbot/scripts/epidbot-restore.sh restore epidbot_duckdb.duckdb.gz
```

## Configuration

Environment variables (set in backup scripts):

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_DIR` | `/opt/kwar-ai/epidbot/data` | Database location |
| `BACKUP_DIR` | `/opt/kwar-ai/epidbot/backups` | Backup storage |
| `RETENTION_DAYS` | `7` | Days to keep backups |
| `MAX_RETRIES` | `3` | Lock retry attempts |
| `RETRY_DELAY` | `10` | Seconds between retries |

## Monitoring

### Check Backup Status

```bash
./scripts/epidbot-backup-manage.sh status
```

### View Backup Logs

```bash
./scripts/epidbot-backup-manage.sh logs
```

### On Server

```bash
tail -f /var/log/epidbot-backup.log
```

## Best Practices

1. **Regular Testing**: Periodically test restore procedures
2. **Off-site Copies**: Download backups to local machine regularly
3. **Monitor Logs**: Check backup logs for failures
4. **Before Updates**: Create manual backup before system updates
5. **Disk Space**: Monitor backup directory size

## Troubleshooting

### Database Locked

The backup script handles this automatically with retries. If persistent:
```bash
# Check if EpidBot is running
docker ps | grep epidbot

# If needed, stop temporarily
cd /opt/kwar-ai/epidbot && docker-compose down
# Run backup
/opt/kwar-ai/epidbot/scripts/epidbot-backup.sh backup
# Restart
docker-compose up -d
```

### Backup Failed

1. Check logs: `tail -50 /var/log/epidbot-backup.log`
2. Verify disk space: `df -h /opt/kwar-ai/epidbot/backups`
3. Check permissions: `ls -la /opt/kwar-ai/epidbot/data/chat_history.duckdb`

### Restore Failed

1. Verify backup file integrity: `gunzip -t backup.duckdb.gz`
2. Ensure EpidBot is stopped during restore
3. Check file permissions after restore
