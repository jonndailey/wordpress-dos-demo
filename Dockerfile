# WordPress on Dailey OS — deploy straight from GitHub. Production template.
#
# FOUR things make the stock image deploy cleanly on DOS:
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
#
# 4. Media offload. When public storage is enabled on the project (DOS injects
#    S3_PUBLIC_* env), uploads are automatically offloaded to the public R2
#    bucket and served from assets.dailey.cloud via the baked-in
#    humanmade/S3-Uploads mu-plugin. No-ops when S3_PUBLIC_* is absent.
#    Kill switch: set env WP_OFFLOAD_MEDIA=false.

# --- Build stage: S3-Uploads (media offload engine) + its vendor deps -------
# Pinned release; recent versions ship no prebuilt zip, so compose it here.
FROM composer:2 AS s3uploads
RUN git clone --depth 1 --branch 3.0.13 https://github.com/humanmade/S3-Uploads.git /s3-uploads \
 && cd /s3-uploads \
 && composer install --no-dev --no-interaction --optimize-autoloader

FROM wordpress:6-apache

EXPOSE 80

# Pre-populate the webroot at build time so first-boot is instant.
RUN cp -a /usr/src/wordpress/. /var/www/html/ \
 && chown -R www-data:www-data /var/www/html

# Image-owned mu-plugins dir — OUTSIDE wp-content so the persistent volume
# can't shadow it; updated by image rebuilds, not by the volume.
COPY --from=s3uploads /s3-uploads /var/www/dailey-mu-plugins/s3-uploads
COPY dailey-media-offload.php /var/www/dailey-mu-plugins/dailey-media-offload.php
RUN chown -R www-data:www-data /var/www/dailey-mu-plugins

COPY dailey-entrypoint.sh /usr/local/bin/dailey-entrypoint.sh
RUN chmod +x /usr/local/bin/dailey-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dailey-entrypoint.sh"]
CMD ["apache2-foreground"]
