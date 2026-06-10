#!/bin/sh
set -e
# Map Dailey OS managed-MySQL env -> the vars the WordPress image expects.
# DOS injects: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD (+ DATABASE_URL).
export WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT:-3306}"
export WORDPRESS_DB_NAME="${DB_NAME}"
export WORDPRESS_DB_USER="${DB_USER}"
export WORDPRESS_DB_PASSWORD="${DB_PASSWORD}"
echo "[dailey] WordPress DB -> ${WORDPRESS_DB_HOST}/${WORDPRESS_DB_NAME} as ${WORDPRESS_DB_USER}"
# Seed wp-content from the image when the mounted volume is empty (first boot).
# The volume mount at /var/www/html/wp-content shadows the baked copy, so an
# empty Longhorn volume would otherwise yield a site with no default themes.
# /usr/src/wordpress/wp-content is OUTSIDE the mount, so it survives as the seed.
if [ -d /var/www/html/wp-content ] && [ -z "$(ls -A /var/www/html/wp-content 2>/dev/null)" ]; then
  if [ -d /usr/src/wordpress/wp-content ]; then
    echo "[dailey] seeding empty wp-content volume from image"
    cp -a /usr/src/wordpress/wp-content/. /var/www/html/wp-content/
  fi
fi
exec docker-entrypoint.sh "$@"
