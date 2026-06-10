#!/bin/sh
set -e
# Map Dailey OS managed-MySQL env -> the vars the WordPress image expects.
# DOS injects: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD (+ DATABASE_URL).
export WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT:-3306}"
export WORDPRESS_DB_NAME="${DB_NAME}"
export WORDPRESS_DB_USER="${DB_USER}"
export WORDPRESS_DB_PASSWORD="${DB_PASSWORD}"
echo "[dailey] WordPress DB -> ${WORDPRESS_DB_HOST}/${WORDPRESS_DB_NAME} as ${WORDPRESS_DB_USER}"
exec docker-entrypoint.sh "$@"
