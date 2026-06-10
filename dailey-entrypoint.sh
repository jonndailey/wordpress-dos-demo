#!/bin/sh
set -e
# Map Dailey OS managed-MySQL env -> the vars the WordPress image expects.
# DOS injects: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD (+ DATABASE_URL).
export WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT:-3306}"
export WORDPRESS_DB_NAME="${DB_NAME}"
export WORDPRESS_DB_USER="${DB_USER}"
export WORDPRESS_DB_PASSWORD="${DB_PASSWORD}"
echo "[dailey] WordPress DB -> ${WORDPRESS_DB_HOST}/${WORDPRESS_DB_NAME} as ${WORDPRESS_DB_USER}"
# Seed wp-content from the image on first boot, then drop a sentinel. Using a
# marker (not an empty-dir check) means an interrupted first-boot copy re-seeds
# and completes on the next start instead of leaving a half-populated volume.
# The copy is idempotent. /usr/src/wordpress/wp-content is OUTSIDE the mount, so
# it always survives as the seed source.
if [ -d /var/www/html/wp-content ] && [ ! -f /var/www/html/wp-content/.dailey-seeded ]; then
  if [ -d /usr/src/wordpress/wp-content ]; then
    echo "[dailey] seeding wp-content volume from image"
    cp -a /usr/src/wordpress/wp-content/. /var/www/html/wp-content/
    touch /var/www/html/wp-content/.dailey-seeded
  fi
fi
exec docker-entrypoint.sh "$@"
