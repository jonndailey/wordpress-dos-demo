# WordPress on Dailey OS — deploy from GitHub

A minimal, reusable template for running WordPress on Dailey OS **straight from a GitHub repo** (no marketplace needed). Two small files do the whole job.

## How to deploy (any user)

1. Click **"Use this template"** on GitHub to make your own copy.
2. Deploy it on Dailey OS as a **git deploy with a MySQL database**:
   - Dashboard: New Project → from GitHub → pick your repo → add a MySQL database.
   - or CLI/MCP: `dailey deploy --repo <your-repo> --db mysql`
3. Open the project URL → you land on the WordPress **site setup** wizard (language → site title → admin user). You will **not** see a "set up your database" screen — the DB is already wired.

## Why it works (the two non-obvious bits)

### 1. The `EXPOSE 80` line is load-bearing
DOS's git build path decides a container's Linux capabilities from whether it detected a port. It detects the port by reading a literal `EXPOSE <n>` line **in this Dockerfile** (the one inherited from the base image does not count). With a detected port, DOS grants the `CHOWN/SETUID/SETGID` capabilities the stock WordPress + Apache entrypoint needs. Without it, the container runs with all capabilities dropped and crash-loops (`tar: Operation not permitted`, then Apache `AH02156: setgid ...`). So: **always put an explicit `EXPOSE` in a Dockerfile for a community/Apache/PHP image on DOS.**

### 2. DB env name mapping
DOS injects `DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD`. The official WordPress image reads `WORDPRESS_DB_*`. `dailey-entrypoint.sh` maps one to the other, so WordPress boots already-connected and skips the DB-config install screen.

## Persistence (important for a real site)

The managed **MySQL database is persistent**. But files written to the container filesystem — uploaded media, and any plugins/themes installed through the WordPress admin — live in `/var/www/html/wp-content` and are **ephemeral**: they are lost when the pod restarts. For a real site, attach a persistent volume mounted at `/var/www/html/wp-content`. (On Dailey OS this needs storage enabled on the project / sufficient storage quota in your namespace.)

If you prefer immutable infrastructure, bake your themes/plugins into the image instead (COPY them into `wp-content/` in the Dockerfile) and keep only uploads on a volume.

## Media offload (R2 / assets.dailey.cloud)

When public storage is enabled on the project, DOS injects `S3_PUBLIC_*` env vars. The image includes a baked-in [humanmade/S3-Uploads](https://github.com/humanmade/S3-Uploads) mu-plugin (`dailey-media-offload.php`) that picks these up automatically: all uploads go to the public R2 bucket and are served from `assets.dailey.cloud` instead of the pod volume.

- **No config needed** — it activates when `S3_PUBLIC_BUCKET_NAME` is present.
- **No-ops silently** when public storage isn't enabled.
- **Kill switch**: `dailey env set WP_OFFLOAD_MEDIA=false` to disable without rebuilding.

The mu-plugin lives in `/var/www/dailey-mu-plugins/` (outside `wp-content`) so the Longhorn volume mount can't shadow it, and WordPress is pointed at that dir via `WPMU_PLUGIN_DIR` injected through `WORDPRESS_CONFIG_EXTRA` in the entrypoint.

## Files
- `Dockerfile` — `FROM wordpress:6-apache` + `EXPOSE 80` + pre-populated webroot (instant boot) + baked S3-Uploads.
- `dailey-entrypoint.sh` — maps `DB_*` → `WORDPRESS_DB_*`, injects `WPMU_PLUGIN_DIR`, then runs the stock entrypoint.
- `dailey-media-offload.php` — mu-plugin: auto-configures S3-Uploads from `S3_PUBLIC_*` env.
