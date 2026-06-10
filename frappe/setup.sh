#!/bin/bash
set -e

# Write common_site_config.json with correct db host
cat > sites/common_site_config.json << 'EOF'
{
  "db_host": "db",
  "db_port": 3306,
  "redis_cache": "redis-cache:6379",
  "redis_queue": "redis-queue:6379",
  "redis_socketio": "redis-queue:6379"
}
EOF

echo "common_site_config.json written"

# Wait for DB to be ready
echo "Waiting for MariaDB..."
until mysqladmin ping -h db -u root -padmin --silent; do
  sleep 2
done
echo "MariaDB is ready"

# Create the site
echo "Creating ERPNext site..."
bench new-site \
  --no-mariadb-socket \
  --admin-password=admin \
  --db-root-password=admin \
  --install-app erpnext \
  --set-default \
  localhost

echo "ERPNext site created successfully!"
echo "Login at http://localhost:8090 with Administrator / admin"
