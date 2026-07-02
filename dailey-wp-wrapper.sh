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
# memory_limit=512M gives search-replace / db import/export headroom on large
# sites. The lifecycle engine used to pass `php -d memory_limit=512M` itself, but
# it now calls `wp` directly (calling `php <this-wrapper>` is a silent no-op), so
# the bump lives here for every wp invocation.
exec php -d memory_limit=512M /usr/local/bin/wp-cli.phar --allow-root "$@"
