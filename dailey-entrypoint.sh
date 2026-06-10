#!/bin/sh
set -e
# Map Dailey OS managed-DB env -> the vars the WordPress image expects.
export WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT:-3306}"
export WORDPRESS_DB_NAME="${DB_DATABASE}"
export WORDPRESS_DB_USER="${DB_USER}"
export WORDPRESS_DB_PASSWORD="${DB_PASSWORD}"
# Optional: set WORDPRESS_TABLE_PREFIX, WP_HOME/WP_SITEURL, etc. here.
echo "[dailey] WordPress DB -> ${WORDPRESS_DB_HOST}/${WORDPRESS_DB_NAME} as ${WORDPRESS_DB_USER}"
exec docker-entrypoint.sh "$@"
