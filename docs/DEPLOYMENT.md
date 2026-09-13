# Deployment Guide

## Recommended topology

- Web root: `servicepro/public`
- Application/source: outside public web access
- MySQL/MariaDB on a private/local endpoint where possible
- HTTPS termination at Apache/Nginx/control panel
- Cron worker every 5–15 minutes
- SMTP credentials through `.env` fallback or tenant Business Settings

## Production settings

Use `APP_ENV=production`, a strong `APP_KEY`, correct `APP_URL`, production DB credentials and `SESSION_SECURE=true`.

The app emits baseline `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` and `Permissions-Policy` headers. A deployment may add a stricter Content-Security-Policy once allowed third-party/CDN origins are finalized.

## Shared hosting

ServicePro avoids a heavy PHP framework and can run on shared hosting when PHP 8.2+, PDO MySQL, writable storage and cron are available. If document-root configuration is unavailable, the project root `.htaccess` forwards requests to `public/`; explicitly protect non-public paths.

## VPS

For Nginx/Apache VPS deployments, expose only `public/`, use PHP-FPM, restrict filesystem ownership/permissions, enable TLS, and configure log rotation and external/infrastructure backups.

## Post-deploy acceptance

1. Run `php bin/healthcheck.php`.
2. Run `php tests/static_check.php`.
3. Create a second test tenant and verify isolation.
4. Test Lead → Customer → Request → Quotation → Job → Invoice → Payment.
5. Test stock shortage rejection and concurrent-style stock operations.
6. Test customer portal, PDFs and file downloads.
7. Test SMTP, cron and webhook delivery.
8. Test backup and restore on a non-production copy.
