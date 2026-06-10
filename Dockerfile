# WordPress on Dailey OS — deploy straight from GitHub.
#
# Two things make the stock image work on DOS:
#
# 1. The EXPOSE line below is LOAD-BEARING. DOS's git/bundle deploy path
#    parses the Dockerfile for an explicit `EXPOSE <port>` to decide the
#    container's Linux capabilities. With a detected port it grants back
#    CHOWN/SETUID/SETGID (which Apache's entrypoint needs to set up the
#    webroot and drop to www-data); WITHOUT it the container runs with all
#    capabilities dropped and the stock entrypoint crash-loops. The EXPOSE 80
#    inherited from the base image does NOT count — it must be written here.
#
# 2. DB env names. DOS provisions a managed MySQL DB and injects
#    DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD; the official image reads
#    WORDPRESS_DB_*. dailey-entrypoint.sh maps them, so WordPress boots
#    already-connected and SKIPS the "set up your database" install screen.
FROM wordpress:6-apache

EXPOSE 80

COPY dailey-entrypoint.sh /usr/local/bin/dailey-entrypoint.sh
RUN chmod +x /usr/local/bin/dailey-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dailey-entrypoint.sh"]
CMD ["apache2-foreground"]
