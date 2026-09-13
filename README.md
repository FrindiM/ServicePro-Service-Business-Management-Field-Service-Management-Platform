# ServicePro

**Service Business Management & Field Service Management SaaS** built with native PHP 8.2+, MVC, PDO, MySQL/MariaDB, Bootstrap 5, jQuery and AJAX.

ServicePro is a multi-tenant application for IT service, CCTV/network installers, maintenance companies, AC/electrical/plumbing service, contractors and other field-service businesses. It covers the operational flow from lead and customer acquisition through field execution, billing, warranty and recurring maintenance.

## Included modules

- Multi-tenant SaaS with tenant isolation, plans, trials, suspension, feature/user/branch/storage limits and Platform Super Admin
- Authentication, password reset, login throttling, active sessions, secure session/cookie handling and RBAC/custom roles
- Role-aware dashboard for management and field technicians
- Leads with Kanban pipeline and Lead → Customer conversion
- Customers, multiple contacts, sites, customer assets, QR asset passport, tags and custom fields
- Service Catalog and Service Categories
- Service Requests with priority, SLA deadline/breach tracking and Request → Survey / Quotation / Job conversion
- Site Survey with findings, estimated materials/labor, collaboration/documents and Survey → Quotation conversion
- Quotations with multi-line items, tax/discount, PDF, customer portal approval and Quotation → Job conversion
- Job Orders, required skills, technician recommendations, scheduling, assignment and activity timeline
- Mobile-first field workflow: Start Trip, GPS Check-in + site distance, Start/Pause/Complete, work logs, before/during/after photos, material usage, expenses, customer/technician signature, rating and service report PDF
- Technician skill matrix, availability, branch and workload-aware recommendation
- Inventory, barcode labels, multi-warehouse balances, adjustments, transfers, low-stock alerts and row-lock stock safety
- Purchasing: Purchase Request → Approval → Purchase Order → Goods Receipt → stock update
- Vendors
- Job costing, material/expense cost, revenue, gross profit and margin
- Invoices, multi-line billing, quotation/job conversion, partial/full payment, AR aging and customer payment-proof approval workflow
- Contracts, covered assets, preventive-maintenance schedules, recurring jobs and warranty
- Customer Portal for requests, assets, jobs, quotation approval, invoices, payment proof, reports, contracts and warranties
- Internal notifications, editable email templates, SMTP per tenant/global fallback, event-driven email and webhook delivery/retry
- Comments, `@email` mentions, documents and activity/audit logs
- CSV import with preview/validation for customers, items and assets
- Report Center with CSV, Excel-compatible export and management PDF
- REST API v1 with tenant-bound Bearer tokens for customers/jobs/assets/inventory/invoices
- Webhook configuration and signed delivery queue
- Tenant backup plus Platform Super Admin global backup orchestration
- White-label logo/color/email/invoice/service-report branding
- Light/Dark/System theme preference and responsive UI

## Architecture

All application requests use `public/index.php`. Business code is kept outside the public web root under `app/`, with controllers, core services and views separated from routing/configuration. Tenant-owned data is scoped by `tenant_id`; critical stock and financial operations use database transactions.

## Requirements

- PHP 8.2+
- MySQL 8+ or MariaDB 10.6+
- PHP extensions: `pdo`, `pdo_mysql`, `fileinfo`, `json`, `openssl`; `mbstring` recommended
- GD is optional but recommended for PNG-to-JPEG processing/compression in some image/PDF workflows
- Apache with `mod_rewrite`, or Nginx equivalent
- HTTPS for production

## Fresh installation

This package is intentionally a **fresh-install build**. There is no upgrade migration chain to run.

1. Copy `.env.example` to `.env` and configure the database and `APP_URL`.
2. Create an empty UTF-8 (`utf8mb4`) MySQL/MariaDB database.
3. Run `php database/install.php` to import `database/schema.sql` and `database/demo.sql`, or import those two SQL files manually in that order.
4. Point the web document root to `servicepro/public` whenever possible.
5. Make `storage/logs`, `storage/uploads`, `storage/documents`, `storage/cache` and `storage/backups` writable by PHP.
6. Run `php bin/healthcheck.php` on the target server.
7. For recurring automation, schedule `php /path/to/servicepro/bin/cron.php` every 5–15 minutes.
8. Sign in and immediately change/remove all demo credentials before production.

Demo tenant owner: `owner@demo.com` / `Demo123!`

Platform Super Admin: `platform@demo.com` / `Demo123!`

Demo customer portal: see the seeded portal user in `database/demo.sql` and replace all demo passwords before real use.

## Development server

```bash
cp .env.example .env
php -S 127.0.0.1:8080 -t public public/router.php
```

Set `APP_URL=http://127.0.0.1:8080` in `.env`.

## Production checklist

- Set `APP_ENV=production`.
- Use a strong random `APP_KEY`.
- Set `SESSION_SECURE=true` behind HTTPS.
- Keep `.env`, `database/`, `storage/`, `app/`, `config/` and `routes/` outside public access.
- Change/delete demo accounts.
- Configure SMTP and test outbound mail.
- Configure the cron job and verify overdue/recurring/webhook processing.
- Test tenant isolation with at least two tenants before onboarding customers.
- Back up both database and `storage/` and test restore procedures.
- Run `php tests/static_check.php` and `php bin/healthcheck.php`.

See `docs/` for installation, deployment, admin, technician, customer-portal, database, API and testing guides.


## License

ServicePro is proprietary commercial software.

Copyright © 2026 Frindi Mangimbulude. All Rights Reserved.

The source code in this repository is provided for portfolio and evaluation purposes only.

Unauthorized use, deployment, modification, redistribution, resale, sublicensing, or commercial exploitation is prohibited without prior written permission.

See the [LICENSE](LICENSE) file for complete licensing terms.
