# WordPress on Dailey OS — deploy straight from GitHub.
#
# DOS runs this container as root but with a hardened security context that
# DROPS Linux capabilities (no CAP_CHOWN, CAP_SETGID, CAP_SETUID). The stock
# wordpress:apache image assumes classic root-with-all-caps, so three things
# it does at runtime fail. We fix all three at BUILD time:
#
# 1. DB env names. DOS injects DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD;
#    the image reads WORDPRESS_DB_*. dailey-entrypoint.sh maps them, so
#    WordPress boots already-connected and SKIPS the "set up your database"
#    install screen.
#
# 2. Runtime copy+chown of the webroot needs CAP_CHOWN → crash. So we
#    pre-populate /var/www/html at build time instead.
#
# 3. Runtime write of wp-config.php fails on the hardened FS → crash. So we
#    bake wp-config.php at build (the docker variant reads WORDPRESS_DB_* at
#    runtime).
#
# 4. Apache workers drop privileges to the www-data group via setgid(33),
#    which needs CAP_SETGID → workers die, health check fails. So we patch
#    /etc/apache2/envvars to run Apache as root:root (no privilege drop).
FROM wordpress:6-apache

RUN set -eux; \
    cp -a /usr/src/wordpress/. /var/www/html/; \
    cp /var/www/html/wp-config-docker.php /var/www/html/wp-config.php; \
    sed -ri 's/^export APACHE_RUN_USER=.*/export APACHE_RUN_USER=root/; \
             s/^export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=root/' \
            /etc/apache2/envvars; \
    chown -R root:0 /var/www/html; \
    chmod -R g=u /var/www/html

COPY dailey-entrypoint.sh /usr/local/bin/dailey-entrypoint.sh
RUN chmod +x /usr/local/bin/dailey-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dailey-entrypoint.sh"]
CMD ["apache2-foreground"]
