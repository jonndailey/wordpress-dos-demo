# WordPress on Dailey OS — deploy straight from GitHub.
# DOS provisions a managed MySQL DB and injects DB_HOST/DB_PORT/DB_USER/
# DB_PASSWORD/DB_DATABASE. The official wordpress image instead reads
# WORDPRESS_DB_*, so we map them in the entrypoint below — which means
# WordPress boots already-configured and SKIPS the "set up your database"
# install screen.
FROM wordpress:6-apache

COPY dailey-entrypoint.sh /usr/local/bin/dailey-entrypoint.sh
RUN chmod +x /usr/local/bin/dailey-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dailey-entrypoint.sh"]
CMD ["apache2-foreground"]
