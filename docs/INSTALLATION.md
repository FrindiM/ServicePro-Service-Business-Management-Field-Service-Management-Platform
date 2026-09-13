# Installation Guide

ServicePro is supplied as a **fresh-install** package. Do not import legacy migrations from older development builds.

## 1. Server requirements

Use PHP 8.2+, MySQL 8+ or MariaDB 10.6+, and the PHP extensions `pdo_mysql`, `fileinfo`, `json`, and `openssl`. `mbstring` and GD are recommended. Enable HTTPS for production.

## 2. Configure environment

Copy `.env.example` to `.env`, then set at minimum:

```env
APP_ENV=production
APP_URL=https://service.example.com
APP_KEY=<long-random-secret>
APP_TIMEZONE=Asia/Makassar
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=servicepro
DB_USER=servicepro_user
DB_PASSWORD=<strong-password>
SESSION_SECURE=true
```

Global SMTP fallback values can also be placed in `.env`. A tenant can override SMTP from Business Settings.

## 3. Create database

Create an empty `utf8mb4` database and grant the application user only the privileges required by the application.

From CLI:

```bash
php database/install.php
```

The installer executes:

1. `database/schema.sql`
2. `database/demo.sql`

Alternatively import those files manually in that order with phpMyAdmin/Adminer/MySQL CLI.

## 4. Web root

Best option: set the domain document root to `/path/to/servicepro/public`.

Apache can route via the included `.htaccess`. Nginx should use a rule equivalent to:

```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
```

The root forwarding `.htaccess` exists for shared hosting that cannot point directly at `public/`, but exposing only `public/` is safer.

## 5. Writable directories

The PHP user must be able to write:

- `storage/logs`
- `storage/uploads`
- `storage/documents`
- `storage/cache`
- `storage/backups`

Uploaded files remain outside the public web root and are served through tenant-checking controllers.

## 6. Cron

Run the worker every 5–15 minutes:

```cron
*/10 * * * * /usr/bin/php /home/account/servicepro/bin/cron.php >/dev/null 2>&1
```

It handles recurring/preventive jobs, overdue/expiry/low-stock events and due webhook deliveries.

## 7. Validate installation

```bash
php bin/healthcheck.php
php tests/static_check.php
```

Then test login, tenant creation, core workflow, file upload, SMTP, cron and PDF generation.

## 8. Demo credentials

- Tenant owner: `owner@demo.com` / `Demo123!`
- Platform admin: `platform@demo.com` / `Demo123!`

Immediately change or remove all demo accounts before production.
