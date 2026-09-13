# Testing and Acceptance

## Automated/package checks

Run:

```bash
php tests/static_check.php
php bin/healthcheck.php
```

`static_check.php` lints PHP files and verifies essential schema/application artifacts. `healthcheck.php` verifies PHP/extensions, writable storage, `.env`, APP_KEY, DB connectivity and required tables when a database is configured.

## Manual acceptance matrix

At minimum validate:

- Authentication: valid/invalid login, password reset, session revoke and permission denial.
- Tenant isolation: create two tenants and confirm IDs/URLs cannot cross-read customers/jobs/invoices/files.
- CRM: lead stage drag/drop, convert lead, customer/site/contact/asset/QR.
- Request/SLA: create request, SLA calculation, conversion paths.
- Quotation: line totals, approval and Job creation.
- Job: assignment, recommendations, schedule, GPS check-in, logs, photos, materials, expense, completion, signatures and report.
- Inventory: adjustment, transfer, low stock and shortage rejection.
- Purchasing: PR → approval → PO → receive and stock increase.
- Finance: invoice, partial payment, full payment, AR aging and payment-proof approval/rejection.
- Recurring: contract coverage, maintenance schedule, recurring job generation and warranty alerts.
- Portal: customer isolation, request, quotation approval, invoice/report and payment proof.
- SaaS: trial/expiry, feature limit, user/branch/storage limit, suspend/archive and tenant admin reset.
- API/Webhook: valid/invalid Bearer token, plan gating, webhook signature/delivery/retry.
- Export/PDF: CSV, XLS, management PDF, quotation/invoice/service report.

Perform production load, security scanning and backup/restore drills in the actual hosting environment before critical commercial use.
