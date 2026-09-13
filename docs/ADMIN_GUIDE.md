# Tenant Admin Guide

## Initial setup

1. Open **Business Settings** and configure company identity, currency, tax, timezone, numbering, branding and SMTP.
2. Create branches/warehouses.
3. Create users and assign default or custom RBAC roles.
4. Set Service Categories and Service Catalog prices/durations.
5. Define SLA policies.
6. Add technician users, technician records and skill matrices.
7. Add vendors and starting inventory.
8. If needed, create Customer Portal users and API/webhook integrations.

## Daily service workflow

Use **Leads** for prospects. A Won lead can be converted to a customer. Customers can have multiple contacts, service sites and assets. Asset QR labels open the asset service passport.

Create a **Service Request** for reported work. Based on the case, convert it into a Site Survey, Quotation or Job. SLA response/resolution deadlines are calculated from active SLA policies.

Use **Quotations** for service/material pricing. Send the quotation, let the customer approve it in the portal, then create a Job.

Use **Dispatch & Calendar** to schedule work. On a Job, define required skills; ServicePro ranks available technicians using skill match, branch, availability and active workload.

After completion, generate a Service Report PDF and Invoice. Finance can record partial/full payments or approve payment proof uploaded by a customer.

## Inventory and purchasing

Inventory is held per warehouse. Adjustments and transfers create stock movements. Material usage from a Job reduces stock transactionally; a request exceeding available stock is rejected.

When stock is needed, use Purchase Request → Approval → Purchase Order → Goods Receipt. Receiving goods updates stock.

## Contracts and recurring maintenance

Create a Service Contract, choose covered assets, and create preventive-maintenance schedules. The cron worker generates due jobs automatically. Recurring Jobs work similarly without requiring a contract.

## Administration tools

**System Tools** contains audit logs, custom fields, tags, API tokens, webhooks, email templates and tenant backup. **Import Center** supports preview/validation before importing customers, items and assets.

## Platform Super Admin

The `/platform` area is separate from tenant administration. It manages companies, subscription plans/status, trial/extension, feature overrides, user/branch/storage constraints, subscription payments, admin reset, tenant archive and platform backup orchestration.
