# WordPress on Dailey OS — deploy straight from GitHub.
#
# Two adaptations make the stock image work on DOS:
#
# 1. DB env names. DOS provisions a managed MySQL DB and injects
#    DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD. The official wordpress
#    image instead reads WORDPRESS_DB_*, so dailey-entrypoint.sh maps them —
#    which means WordPress boots already-connected and SKIPS the "set up your
#    database" install screen.
#
# 2. Hardened runtime. DOS runs containers without CAP_CHOWN. The stock
#    entrypoint copies WordPress into /var/www/html at *runtime* and chowns it
#    to www-data, which fails ("Operation not permitted") and crash-loops. So
#    we pre-populate /var/www/html here at BUILD time (full privileges), with
#    ownership baked in. At runtime the entrypoint sees WordPress already
#    present, skips the copy+chown, and goes straight to wp-config generation.
FROM wordpress:6-apache

# Bake WordPress into the webroot at build time, owned by www-data (uid 33).
RUN set -eux; \
    cp -a /usr/src/wordpress/. /var/www/html/; \
    chown -R www-data:www-data /var/www/html

COPY dailey-entrypoint.sh /usr/local/bin/dailey-entrypoint.sh
RUN chmod +x /usr/local/bin/dailey-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dailey-entrypoint.sh"]
CMD ["apache2-foreground"]
