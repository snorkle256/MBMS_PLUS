#!/bin/bash
set -e

# Path to the Postgres 16 data directory
PGDATA="/var/lib/postgresql/16/main"

# 1. Ensure the directory exists and has the right permissions
# This is vital for Proxmox Bind Mounts
mkdir -p "$PGDATA"
chown -R postgres:postgres /var/lib/postgresql/16/main
chmod 700 "$PGDATA"

# 2. Initialize Postgres if the directory is empty
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "First run detected: Initializing PostgreSQL 16 database..."
    sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D "$PGDATA"
    
    # Optional: If you want to auto-create the musicbrainz user on first boot:
    # sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start
    # sudo -u postgres psql --command "CREATE USER musicbrainz WITH SUPERUSER PASSWORD 'musicbrainz';"
    # sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl -D "$PGDATA" -m fast -w stop
fi

# 3. Handle the PID file for Supervisor
# This prevents "already running" errors if the LXC is hard-rebooted
rm -f /var/run/supervisord.pid

# 4. Start Supervisor to manage Postgres, the MB Server, and the Bridge
echo "Starting Supervisor..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
