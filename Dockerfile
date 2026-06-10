# WordPress on Dailey OS — deploy straight from GitHub. Production template.
#
# THREE things make the stock image deploy cleanly on DOS:
#
# 1. EXPOSE 80 is LOAD-BEARING. DOS's git/bundle deploy path parses the
#    Dockerfile for an explicit `EXPOSE <port>` to decide the container's
#    Linux capabilities. With a detected port it grants CHOWN/SETUID/SETGID
#    (which Apache's entrypoint needs to set up the webroot and drop to
#    www-data); WITHOUT it the container runs with ALL capabilities dropped
#    and the stock entrypoint crash-loops. The EXPOSE inherited from the base
#    image does NOT count — it must be written literally here.
#
# 2. DB env names. DOS provisions a managed MySQL DB and injects
#    DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD; the official image reads
#    WORDPRESS_DB_*. dailey-entrypoint.sh maps them, so WordPress boots
#    already-connected and SKIPS the "set up your database" install screen.
#
# 3. Fast first boot. The stock entrypoint copies all of WordPress into
#    /var/www/html on first start (~40s) — long enough to trip the deploy's
#    readiness gate. We pre-populate the webroot at BUILD time so the runtime
#    container is ready almost immediately.
FROM wordpress:6-apache

EXPOSE 80

# Pre-populate the webroot at build time so first-boot is instant.
RUN cp -a /usr/src/wordpress/. /var/www/html/ \
 && chown -R www-data:www-data /var/www/html

COPY dailey-entrypoint.sh /usr/local/bin/dailey-entrypoint.sh
RUN chmod +x /usr/local/bin/dailey-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dailey-entrypoint.sh"]
CMD ["apache2-foreground"]
