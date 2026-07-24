#!/usr/bin/env bash
set -e

# Extract host and port from DATABASE_URL for pg_isready check
# DATABASE_URL format: postgresql://user:pass@host:port/dbname
DB_HOST=$(echo "$DATABASE_URL" | sed -E 's|.*@([^:/]+).*|\1|')
DB_PORT=$(echo "$DATABASE_URL" | sed -E 's|.*:([0-9]+)/.*|\1|')
DB_USER=$(echo "$DATABASE_URL" | sed -E 's|.*//([^:]+):.*|\1|')

DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}

echo "==> Waiting for database at ${DB_HOST}:${DB_PORT}..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -q; do
  echo "  Postgres not ready — retrying in 1s..."
  sleep 1
done
echo "  Postgres is ready!"

echo "==> Running db:prepare (create + migrate)..."
bundle exec rails db:prepare

echo "==> Starting server..."
exec "$@"
