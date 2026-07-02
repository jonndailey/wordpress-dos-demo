#!/bin/sh
# wp-cli wrapper for Dailey OS. The DOS WordPress lifecycle (snapshot/restore/
# clone) runs `wp` via `kubectl exec`, a fresh shell that does NOT inherit the
# WORDPRESS_DB_* vars the entrypoint exports for the Apache process. Map them
# from the DOS-injected DB_* secret env (present in every shell) so wp-config's
# getenv('WORDPRESS_DB_HOST') resolves to the real DB instead of the 'mysql'
# default. Also run with --allow-root (pod execs run as root).
: "${WORDPRESS_DB_HOST:=${DB_HOST}:${DB_PORT:-3306}}"
: "${WORDPRESS_DB_NAME:=${DB_NAME}}"
: "${WORDPRESS_DB_USER:=${DB_USER}}"
: "${WORDPRESS_DB_PASSWORD:=${DB_PASSWORD}}"
export WORDPRESS_DB_HOST WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD
exec php /usr/local/bin/wp-cli.phar --allow-root "$@"
