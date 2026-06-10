# WordPress on Dailey OS

Deploy WordPress to Dailey OS straight from GitHub — no marketplace needed.

1. Click **Use this template** → create your repo.
2. Deploy with a managed MySQL DB:
   - CLI: `dailey deploy <name> --repo <this-repo> --db mysql`
   - or the Dashboard: New Project → from GitHub → enable Database (MySQL).
3. DOS provisions MySQL, injects `DB_*`, builds this image. The entrypoint maps
   `DB_*` → `WORDPRESS_DB_*`, so WordPress boots **already connected to the DB**
   and skips the "configure database" install screen — you go straight to
   setting your site title + admin user.

Persistence: to keep uploads/plugins across restarts, add a volume for
`/var/www/html/wp-content` in your deploy config (needs storage quota).
