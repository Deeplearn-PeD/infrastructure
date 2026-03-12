#!/bin/bash
# Database Size Metrics Exporter for Prometheus Node Exporter
# Collects PostgreSQL and DuckDB database sizes and exports them as Prometheus metrics

set -e

METRICS_DIR="/var/lib/node_exporter/textfile_collector"
METRICS_FILE="${METRICS_DIR}/database_sizes.prom"
TEMP_FILE="${METRICS_FILE}.$$"

mkdir -p "$METRICS_DIR"

# Initialize metrics file
cat > "$TEMP_FILE" << 'EOF'
# HELP kwar_ai_database_size_bytes Size of database in bytes
# TYPE kwar_ai_database_size_bytes gauge
# HELP kwar_ai_database_table_count Number of tables in database
# TYPE kwar_ai_database_table_count gauge
# HELP kwar_ai_database_backup_count Number of backups available
# TYPE kwar_ai_database_backup_count gauge
# HELP kwar_ai_database_backup_size_bytes Total size of backups in bytes
# TYPE kwar_ai_database_backup_size_bytes gauge
# HELP kwar_ai_directory_size_bytes Size of directory in bytes
# TYPE kwar_ai_directory_size_bytes gauge
EOF

# PostgreSQL metrics
get_postgres_size() {
    local size=0
    local tables=0
    
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^libby-postgres$"; then
        size=$(docker exec libby-postgres psql -U libby -d libby -t -c \
            "SELECT pg_database_size('libby');" 2>/dev/null | tr -d '[:space:]') || size=0
        
        tables=$(docker exec libby-postgres psql -U libby -d libby -t -c \
            "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d '[:space:]') || tables=0
    fi
    
    echo "$size $tables"
}

# DuckDB metrics
get_duckdb_size() {
    local db_file="/var/lib/docker/volumes/epidbot_epidbot_data/_data/chat_history.duckdb"
    local metadata_file="/opt/kwar-ai/epidbot/backups/.metadata"
    local size=0
    local tables=0
    
    if [ -f "$db_file" ]; then
        size=$(stat -c %s "$db_file" 2>/dev/null) || size=0
    fi
    
    if [ -f "$metadata_file" ]; then
        tables=$(grep "^table_count=" "$metadata_file" 2>/dev/null | cut -d= -f2) || tables=0
    fi
    
    echo "$size $tables"
}

# Backup metrics
get_backup_metrics() {
    local backup_dir="/opt/kwar-ai/epidbot/backups"
    local count=0
    local total_size=0
    
    if [ -d "$backup_dir" ]; then
        count=$(find "$backup_dir" -name "epidbot_duckdb_*.duckdb.gz" -type f 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            total_size=$(du -sb "$backup_dir"/epidbot_duckdb_*.duckdb.gz 2>/dev/null | awk '{sum += $1} END {print sum}') || total_size=0
        fi
    fi
    
    echo "$count ${total_size:-0}"
}

# Directory size metrics for treemap
collect_directory_sizes() {
    local dirs=(
        "/opt/kwar-ai/epidbot:epidbot:app"
        "/opt/kwar-ai/epidbot/backups:epidbot:backups"
        "/opt/kwar-ai/epidbot/data:epidbot:data"
        "/opt/kwar-ai/libby:libby:app"
        "/opt/kwar-ai/monitoring:monitoring:app"
        "/opt/kwar-ai/nginx:nginx:app"
        "/var/lib/docker/volumes/epidbot_epidbot_data:epidbot:docker-volume"
        "/var/lib/docker/volumes/libby_postgres-data:libby:docker-volume"
        "/var/lib/docker/volumes/libby_ollama-models:libby:docker-volume"
        "/var/lib/docker/volumes/libby_libby-data:libby:docker-volume"
        "/var/lib/docker/volumes/epidbot_data:epidbot:docker-volume"
    )
    
    for entry in "${dirs[@]}"; do
        IFS=':' read -r dir service category <<< "$entry"
        if [ -d "$dir" ]; then
            local size=$(du -sb "$dir" 2>/dev/null | cut -f1) || size=0
            local name=$(basename "$dir")
            echo "kwar_ai_directory_size_bytes{name=\"$name\",service=\"$service\",category=\"$category\"} $size" >> "$TEMP_FILE"
        fi
    done
}

# Collect and write PostgreSQL metrics
read pg_size pg_tables <<< $(get_postgres_size)
echo "kwar_ai_database_size_bytes{database=\"postgresql\",service=\"libby\"} $pg_size" >> "$TEMP_FILE"
echo "kwar_ai_database_table_count{database=\"postgresql\",service=\"libby\"} $pg_tables" >> "$TEMP_FILE"

# Collect and write DuckDB metrics
read duck_size duck_tables <<< $(get_duckdb_size)
echo "kwar_ai_database_size_bytes{database=\"duckdb\",service=\"epidbot\"} $duck_size" >> "$TEMP_FILE"
echo "kwar_ai_database_table_count{database=\"duckdb\",service=\"epidbot\"} $duck_tables" >> "$TEMP_FILE"

# Collect and write backup metrics
read backup_count backup_size <<< $(get_backup_metrics)
echo "kwar_ai_database_backup_count{database=\"duckdb\",service=\"epidbot\"} $backup_count" >> "$TEMP_FILE"
echo "kwar_ai_database_backup_size_bytes{database=\"duckdb\",service=\"epidbot\"} $backup_size" >> "$TEMP_FILE"

# Collect and write directory size metrics
collect_directory_sizes

# Atomically replace metrics file
mv "$TEMP_FILE" "$METRICS_FILE"
