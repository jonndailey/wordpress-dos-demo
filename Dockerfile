# WordPress on Dailey OS — deploy straight from GitHub.
#
# Three adaptations make the stock image work on DOS's hardened runtime:
#
# 1. DB env names. DOS provisions a managed MySQL DB and injects
#    DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD. The official wordpress
#    image instead reads WORDPRESS_DB_*, so dailey-entrypoint.sh maps them —
#    so WordPress boots already-connected and SKIPS the "set up your
#    database" install screen.
#
# 2. No runtime file-copy/chown. DOS runs containers without CAP_CHOWN, and
#    the stock entrypoint copies WordPress into /var/www/html and chowns it at
#    runtime (crash: "Operation not permitted"). So we pre-populate the webroot
#    here at BUILD time, where we have full privileges.
#
# 3. No runtime wp-config write. The stock entrypoint then tries to *write*
#    wp-config.php into /var/www/html at runtime (crash: "Permission denied"
#    on the hardened FS). So we bake wp-config.php at build time from the
#    image's docker variant (it reads the WORDPRESS_DB_* env at runtime), and
#    make the tree group-writable for gid 0 — the standard pattern for
#    containers that run as an arbitrary uid in the root group.
FROM wordpress:6-apache

RUN set -eux; \
    cp -a /usr/src/wordpress/. /var/www/html/; \
    cp /var/www/html/wp-config-docker.php /var/www/html/wp-config.php; \
    chown -R www-data:0 /var/www/html; \
    chmod -R g=u /var/www/html

COPY dailey-entrypoint.sh /usr/local/bin/dailey-entrypoint.sh
RUN chmod +x /usr/local/bin/dailey-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dailey-entrypoint.sh"]
CMD ["apache2-foreground"]
