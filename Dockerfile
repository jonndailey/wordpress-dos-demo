# WordPress on Dailey OS — deploy straight from GitHub. Production template.
#
# SIX things make the stock image deploy cleanly on DOS:
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
#
# 5. Upload limits. Stock wordpress:apache ships PHP upload_max_filesize=2M /
#    post_max_size=8M. A bigger theme/plugin/media upload exceeds post_max_size,
#    PHP drops the whole POST body (nonce included), and WP shows the misleading
#    "The link you followed has expired." dailey-uploads.ini raises these to 128M.
#
# 6. Immutable core. The webroot (/var/www/html) is ephemeral — only wp-content
#    is on the persistent volume — so an in-place WordPress core update is wiped
#    on the next pod restart, leaving users with a perpetual "please update" nag.
#    We instead manage core via the IMAGE: the WP version is the base tag below,
#    and dailey-core-version-lock.php hides the core update nag/action. Plugins,
#    themes, and uploads live on the volume and update/persist normally. To ship
#    a newer WP core: bump the FROM tag and redeploy.

# --- Build stage: S3-Uploads (media offload engine) + its vendor deps -------
# Pinned release; recent versions ship no prebuilt zip, so compose it here.
FROM composer:2 AS s3uploads
RUN git clone --depth 1 --branch 3.0.13 https://github.com/humanmade/S3-Uploads.git /s3-uploads \
 && cd /s3-uploads \
 && composer install --no-dev --no-interaction --optimize-autoloader

# WP core version is pinned by this tag (immutable-core model — see point 6).
# major.minor pin: rebuilds pull 7.0.x security patches; core stays stable
# between rebuilds. Bump here + redeploy to move to a newer WordPress.
FROM wordpress:7.0-php8.3-apache

EXPOSE 80

# Pre-populate the webroot at build time so first-boot is instant.
RUN cp -a /usr/src/wordpress/. /var/www/html/ \
 && chown -R www-data:www-data /var/www/html

# Image-owned mu-plugins dir — OUTSIDE wp-content so the persistent volume
# can't shadow it; updated by image rebuilds, not by the volume.
COPY --from=s3uploads /s3-uploads /var/www/dailey-mu-plugins/s3-uploads
COPY dailey-media-offload.php /var/www/dailey-mu-plugins/dailey-media-offload.php
RUN chown -R www-data:www-data /var/www/dailey-mu-plugins

# Raise PHP upload limits above the stock 2M/8M (see point 5 above). Loaded last
# (zz- prefix) so it overrides the base image's conf.d defaults.
COPY dailey-uploads.ini /usr/local/etc/php/conf.d/zz-dailey-uploads.ini

# Immutable core: hide the core update nag/action (core = image; see point 6).
# Loaded from the image-owned mu-plugins dir alongside the media-offload plugin.
COPY dailey-core-version-lock.php /var/www/dailey-mu-plugins/dailey-core-version-lock.php
RUN chown www-data:www-data /var/www/dailey-mu-plugins/dailey-core-version-lock.php

COPY dailey-entrypoint.sh /usr/local/bin/dailey-entrypoint.sh
RUN chmod +x /usr/local/bin/dailey-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dailey-entrypoint.sh"]
CMD ["apache2-foreground"]
