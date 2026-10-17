#!/bin/bash
set -e

echo "========================================================"
echo "          Starting EventSphere Cloud Container"
echo "========================================================"

# Determine if an external cloud database is configured
if [ -n "$MYSQL_URL" ] || [ -n "$DATABASE_URL" ] || [ -n "$DB_HOST" ] || [ -n "$MYSQLHOST" ]; then
    echo "[EventSphere] External database environment variable detected. Skipping internal MariaDB startup."
else
    echo "[EventSphere] No external database configured. Starting internal MariaDB server..."
    service mariadb start || /usr/bin/mysqld_safe --datadir='/var/lib/mysql' &
    
    echo "[EventSphere] Waiting for MariaDB service to accept connections..."
    for i in {1..30}; do
        if mysqladmin ping --silent 2>/dev/null; then
            echo "[EventSphere] MariaDB is up and responding."
            break
        fi
        sleep 1
    done
    
    echo "[EventSphere] Initializing 'eventsphere' database..."
    mysql -e "CREATE DATABASE IF NOT EXISTS eventsphere;"
    
    # Import schema if tables don't exist yet
    TABLE_COUNT=$(mysql -N -s -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'eventsphere';" 2>/dev/null || echo "0")
    if [ "$TABLE_COUNT" -eq 0 ] && [ -f /docker-entrypoint-initdb.d/schema.sql ]; then
        echo "[EventSphere] Seeding schema.sql (tables, initial events, users, seed data)..."
        mysql eventsphere < /docker-entrypoint-initdb.d/schema.sql 2>/dev/null || true
        echo "[EventSphere] Database seeded successfully."
    else
        echo "[EventSphere] Database already contains $TABLE_COUNT tables. Skipping seed."
    fi
fi

echo "========================================================"
echo "[EventSphere] Starting Apache Tomcat 10 on port 8080..."
echo "========================================================"
exec catalina.sh run
