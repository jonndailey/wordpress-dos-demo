<?php
/**
 * Dailey OS — immutable WordPress core.
 *
 * On Dailey OS the WordPress webroot (/var/www/html) is ephemeral; only
 * wp-content is on the persistent volume. An in-place core update therefore
 * lands in the ephemeral webroot and is wiped on the next pod restart, leaving
 * users with a perpetual "Please update WordPress" nag and lost updates.
 *
 * Instead, core is managed by the IMAGE: the WordPress version is the Docker
 * base tag, and is refreshed by rebuilding the image and redeploying. This
 * mu-plugin hides the core update nag/action so users aren't prompted to do an
 * update that wouldn't survive a restart. It ONLY touches core — plugins,
 * themes, and uploads live on the volume and update/persist normally.
 */
if (!defined('ABSPATH')) { exit; }

// Short-circuit the core update check: report "no update available" using the
// running version, so wp-admin shows no nag and no "Update now" for core.
// Runs at transient-read time (not at mu-plugin load), so $wp_version is set.
add_filter('pre_site_transient_update_core', function () {
    global $wp_version;
    $current = isset($wp_version) ? $wp_version : '';
    return (object) array(
        'updates'         => array(),
        'version_checked' => $current,
        'last_checked'    => time(),
    );
});

// Belt-and-suspenders: also disable background core auto-updates, which would
// otherwise write to the ephemeral webroot.
if (!defined('WP_AUTO_UPDATE_CORE'))        { define('WP_AUTO_UPDATE_CORE', false); }
if (!defined('AUTOMATIC_UPDATER_DISABLED')) { define('AUTOMATIC_UPDATER_DISABLED', true); }
