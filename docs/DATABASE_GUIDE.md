# Database Guide

Fresh installations use `database/schema.sql`. Demo data is in `database/demo.sql`.

## Multi-tenancy

Tenant-owned operational tables include `tenant_id`. Controllers/services must verify the active tenant for every read/write. Public customer/asset paths use scoped tokens or customer-portal sessions and still bind queries to the tenant/customer.

## Critical consistency patterns

- Document numbers use `number_sequences` and an atomic/locked sequence service; never `COUNT()+1`.
- Stock is represented by `stock_balances` per tenant + warehouse + item.
- Material consumption, stock transfer and receipt operations use database transactions and row locking to prevent negative/concurrent stock errors.
- Quotation/invoice header + line-item writes use transactions.
- Payments update invoice paid/balance/status transactionally.
- Important business records use soft delete where appropriate.
- `audit_logs` stores user/action/module/record and old/new JSON values.
- `activity_logs` records operational entity timelines.

## Fresh install

```bash
php database/install.php
```

No legacy migration chain is required for this release because it is intended for a new installation.

## Backup

Application-level tenant backups create JSON snapshots in `storage/backups`. Platform Super Admin can orchestrate backups across active tenants. Infrastructure-level database and file backups are still required for disaster recovery.
