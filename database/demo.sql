INSERT INTO subscription_plans(name,code,user_limit,branch_limit,storage_limit_mb,features,price_monthly)
VALUES
('Starter','starter',5,1,1024,JSON_ARRAY('customers','service_requests','jobs','inventory_basic','reports_basic'),299000),
('Business','business',20,5,10240,JSON_ARRAY('customers','service_requests','jobs','inventory','quotations','invoices','payments','scheduling','contracts','reports_advanced'),799000),
('Professional','professional',NULL,NULL,51200,JSON_ARRAY('all','api','custom_reports','customer_portal','analytics','automation','white_label'),1499000)
ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT INTO tenants(name,company_code,business_type,address,phone,email,currency,default_tax,timezone,language,status)
VALUES('ServicePro Demo Company','DEMO','IT Service & Field Service','Manado, North Sulawesi','+62 000 0000','demo@servicepro.local','IDR',11,'Asia/Makassar','id','active')
ON DUPLICATE KEY UPDATE name=VALUES(name);
SET @tenant=(SELECT id FROM tenants WHERE company_code='DEMO');
SET @plan=(SELECT id FROM subscription_plans WHERE code='professional');
INSERT INTO subscriptions(tenant_id,plan_id,status,starts_at,trial_ends_at,amount)
SELECT @tenant,@plan,'trial',NOW(),DATE_ADD(NOW(),INTERVAL 30 DAY),0
WHERE NOT EXISTS(SELECT 1 FROM subscriptions WHERE tenant_id=@tenant);

INSERT INTO branches(tenant_id,name,address,status) VALUES(@tenant,'Main Branch','Manado, North Sulawesi','active')
ON DUPLICATE KEY UPDATE name=VALUES(name);
SET @branch=(SELECT id FROM branches WHERE tenant_id=@tenant AND name='Main Branch');

INSERT INTO users(tenant_id,branch_id,name,email,password_hash,is_platform_admin,status)
VALUES
(NULL,NULL,'Platform Super Admin','platform@demo.com','$2y$12$.TwyKcfD5GxlBS2BdSoOGOSY5Ch0RdF2Px0VaM3.sNjuX.dmW8eDG',1,'active'),
(@tenant,@branch,'Demo Owner','owner@demo.com','$2y$12$.TwyKcfD5GxlBS2BdSoOGOSY5Ch0RdF2Px0VaM3.sNjuX.dmW8eDG',0,'active'),
(@tenant,@branch,'Demo Admin','admin@demo.com','$2y$12$.TwyKcfD5GxlBS2BdSoOGOSY5Ch0RdF2Px0VaM3.sNjuX.dmW8eDG',0,'active'),
(@tenant,@branch,'Demo Dispatcher','dispatcher@demo.com','$2y$12$.TwyKcfD5GxlBS2BdSoOGOSY5Ch0RdF2Px0VaM3.sNjuX.dmW8eDG',0,'active'),
(@tenant,@branch,'Demo Technician','technician@demo.com','$2y$12$.TwyKcfD5GxlBS2BdSoOGOSY5Ch0RdF2Px0VaM3.sNjuX.dmW8eDG',0,'active'),
(@tenant,@branch,'Demo Finance','finance@demo.com','$2y$12$.TwyKcfD5GxlBS2BdSoOGOSY5Ch0RdF2Px0VaM3.sNjuX.dmW8eDG',0,'active')
ON DUPLICATE KEY UPDATE name=VALUES(name),password_hash=VALUES(password_hash),status='active';

INSERT INTO roles(tenant_id,name,code,is_system) VALUES
(@tenant,'Company Owner','owner',1),(@tenant,'Administrator','administrator',1),(@tenant,'Dispatcher','dispatcher',1),(@tenant,'Technician','technician',1),(@tenant,'Finance','finance',1)
ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT INTO permissions(code,name,module) VALUES
('customer.view','View customers','customer'),('customer.create','Create customers','customer'),('customer.edit','Edit customers','customer'),('customer.delete','Delete customers','customer'),
('request.view','View requests','request'),('request.create','Create requests','request'),('request.edit','Edit requests','request'),
('job.view','View jobs','job'),('job.create','Create jobs','job'),('job.assign','Assign jobs','job'),('job.complete','Complete jobs','job'),
('inventory.view','View inventory','inventory'),('inventory.manage','Manage inventory','inventory'),
('invoice.view','View invoices','invoice'),('invoice.create','Create invoices','invoice'),('invoice.payment','Record payments','invoice'),
('report.view','View reports','report'),('settings.manage','Manage settings','settings')
ON DUPLICATE KEY UPDATE name=VALUES(name),module=VALUES(module);

SET @owner_role=(SELECT id FROM roles WHERE tenant_id=@tenant AND code='owner');
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @owner_role,id FROM permissions;
SET @owner=(SELECT id FROM users WHERE email='owner@demo.com');
SET @admin=(SELECT id FROM users WHERE email='admin@demo.com');
SET @dispatcher=(SELECT id FROM users WHERE email='dispatcher@demo.com');
SET @techuser=(SELECT id FROM users WHERE email='technician@demo.com');
SET @finance=(SELECT id FROM users WHERE email='finance@demo.com');
INSERT IGNORE INTO user_roles(tenant_id,user_id,role_id) VALUES(@tenant,@owner,@owner_role);

SET @admin_role=(SELECT id FROM roles WHERE tenant_id=@tenant AND code='administrator');
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @admin_role,id FROM permissions;
INSERT IGNORE INTO user_roles VALUES(@tenant,@admin,@admin_role);
SET @dispatcher_role=(SELECT id FROM roles WHERE tenant_id=@tenant AND code='dispatcher');
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @dispatcher_role,id FROM permissions WHERE code IN('customer.view','request.view','job.view','job.create','job.assign');
INSERT IGNORE INTO user_roles VALUES(@tenant,@dispatcher,@dispatcher_role);
SET @tech_role=(SELECT id FROM roles WHERE tenant_id=@tenant AND code='technician');
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @tech_role,id FROM permissions WHERE code IN('customer.view','job.view','job.complete','inventory.view');
INSERT IGNORE INTO user_roles VALUES(@tenant,@techuser,@tech_role);
SET @finance_role=(SELECT id FROM roles WHERE tenant_id=@tenant AND code='finance');
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @finance_role,id FROM permissions WHERE code IN('customer.view','job.view','invoice.view','invoice.create','invoice.payment','report.view');
INSERT IGNORE INTO user_roles VALUES(@tenant,@finance,@finance_role);

INSERT INTO customers(tenant_id,customer_code,customer_type,name,company,phone,email,service_address,status,created_by) VALUES
(@tenant,'CUS-000001','Company','Hotel Nusantara','Hotel Nusantara','081200000001','ops@nusantara.test','Manado','active',@owner),
(@tenant,'CUS-000002','Company','PT Maju Bersama','PT Maju Bersama','081200000002','it@majubersama.test','Minahasa','active',@owner),
(@tenant,'CUS-000003','Company','Restaurant Bahari','Restaurant Bahari','081200000003','owner@bahari.test','Manado','active',@owner),
(@tenant,'CUS-000004','Company','Villa Seaview','Villa Seaview','081200000004','admin@seaview.test','Likupang','active',@owner)
ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT INTO service_categories(tenant_id,name) VALUES(@tenant,'CCTV'),(@tenant,'Network'),(@tenant,'AC'),(@tenant,'Electrical')
ON DUPLICATE KEY UPDATE name=VALUES(name);
INSERT INTO services(tenant_id,service_code,service_name,category_id,default_price,estimated_duration,taxable) VALUES
(@tenant,'SRV-CCTV-01','CCTV Installation',(SELECT id FROM service_categories WHERE tenant_id=@tenant AND name='CCTV'),1500000,240,1),
(@tenant,'SRV-NET-01','Network Troubleshooting',(SELECT id FROM service_categories WHERE tenant_id=@tenant AND name='Network'),350000,120,1),
(@tenant,'SRV-AC-01','AC Maintenance',(SELECT id FROM service_categories WHERE tenant_id=@tenant AND name='AC'),250000,90,1),
(@tenant,'SRV-EL-01','Electrical Repair',(SELECT id FROM service_categories WHERE tenant_id=@tenant AND name='Electrical'),300000,120,1)
ON DUPLICATE KEY UPDATE service_name=VALUES(service_name);

INSERT INTO warehouses(tenant_id,branch_id,name,type,location) VALUES(@tenant,@branch,'Main Warehouse','main','Main Branch') ON DUPLICATE KEY UPDATE name=VALUES(name);
SET @warehouse=(SELECT id FROM warehouses WHERE tenant_id=@tenant AND name='Main Warehouse');
INSERT INTO items(tenant_id,sku,item_name,category,brand,unit,purchase_price,selling_price,minimum_stock,status,created_by) VALUES
(@tenant,'RJ45-CAT6','RJ45 Connector Cat6','Network','Generic','pcs',1500,3000,20,'active',@owner),
(@tenant,'UTP-CAT6','UTP Cable Cat6','Network','Generic','meter',4500,7500,100,'active',@owner),
(@tenant,'PWR-12V','Power Adapter 12V','CCTV','Generic','pcs',45000,85000,5,'active',@owner)
ON DUPLICATE KEY UPDATE item_name=VALUES(item_name);
INSERT INTO stock_balances(tenant_id,warehouse_id,item_id,quantity)
SELECT @tenant,@warehouse,id,CASE sku WHEN 'RJ45-CAT6' THEN 18 WHEN 'UTP-CAT6' THEN 250 ELSE 3 END FROM items WHERE tenant_id=@tenant
ON DUPLICATE KEY UPDATE quantity=VALUES(quantity);

INSERT INTO service_requests(tenant_id,request_number,request_date,customer_id,service_category,problem_description,priority,requested_date,status,created_by)
SELECT @tenant,'SR-2026-000001',CURDATE(),id,'Network','Internet intermittent in office area','High',CURDATE(),'Reviewed',@owner FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000001'
ON DUPLICATE KEY UPDATE status=VALUES(status);

INSERT INTO jobs(tenant_id,job_number,customer_id,service_category,description,priority,scheduled_date,estimated_duration,status,created_by)
SELECT @tenant,'JOB-2026-000001',id,'Network','Troubleshoot intermittent connection and verify access point uplink.','High',DATE_ADD(NOW(),INTERVAL 1 DAY),120,'Scheduled',@owner FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000001'
ON DUPLICATE KEY UPDATE status=VALUES(status);
INSERT IGNORE INTO job_technicians(tenant_id,job_id,user_id) VALUES(@tenant,(SELECT id FROM jobs WHERE tenant_id=@tenant AND job_number='JOB-2026-000001'),@techuser);

INSERT INTO technicians(tenant_id,user_id,branch_id,certification,availability,status) VALUES(@tenant,@techuser,@branch,'Network, CCTV','Available','Available') ON DUPLICATE KEY UPDATE status='Available';
INSERT INTO skills(tenant_id,name) VALUES(@tenant,'Networking'),(@tenant,'Fiber Optic'),(@tenant,'MikroTik'),(@tenant,'CCTV') ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT INTO invoices(tenant_id,invoice_number,customer_id,invoice_date,due_date,subtotal,tax,total,paid,balance,status,created_by)
SELECT @tenant,'INV-2026-000001',id,CURDATE(),DATE_ADD(CURDATE(),INTERVAL 14 DAY),1000000,110000,1110000,0,1110000,'Sent',@owner FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000002'
ON DUPLICATE KEY UPDATE status=VALUES(status);

INSERT INTO number_sequences(tenant_id,type,year,current_value) VALUES
(@tenant,'customer',YEAR(CURDATE()),4),
(@tenant,'service_request',YEAR(CURDATE()),1),
(@tenant,'job',YEAR(CURDATE()),1),
(@tenant,'invoice',YEAR(CURDATE()),1)
ON DUPLICATE KEY UPDATE current_value=GREATEST(current_value,VALUES(current_value));

-- Expanded roles and permissions for complete ServicePro demo.
INSERT INTO roles(tenant_id,name,code,is_system) VALUES
(@tenant,'Service Manager','service_manager',1),(@tenant,'Sales','sales',1),(@tenant,'Inventory','inventory',1)
ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT INTO permissions(code,name,module) VALUES
('lead.view','View leads','lead'),('lead.create','Create leads','lead'),('lead.edit','Edit leads','lead'),('lead.delete','Delete leads','lead'),
('asset.view','View assets','asset'),('asset.create','Create assets','asset'),('asset.edit','Edit assets','asset'),('asset.delete','Delete assets','asset'),
('catalog.view','View service catalog','catalog'),('catalog.create','Create services','catalog'),('catalog.edit','Edit services','catalog'),('catalog.delete','Delete services','catalog'),
('survey.view','View surveys','survey'),('survey.create','Create surveys','survey'),('survey.edit','Edit surveys','survey'),('survey.convert','Convert survey','survey'),
('quotation.view','View quotations','quotation'),('quotation.create','Create quotations','quotation'),('quotation.edit','Edit quotations','quotation'),('quotation.approve','Approve quotations','quotation'),('quotation.convert','Convert quotation','quotation'),
('technician.view','View technicians','technician'),('technician.create','Create technicians','technician'),('technician.edit','Edit technicians','technician'),('technician.manage','Manage technicians','technician'),
('dispatch.view','View dispatch board','dispatch'),('dispatch.manage','Manage dispatch','dispatch'),
('inventory.create','Create inventory data','inventory'),('inventory.edit','Edit inventory','inventory'),('inventory.delete','Delete inventory','inventory'),('inventory.transfer','Transfer stock','inventory'),('inventory.adjust','Adjust stock','inventory'),
('purchase.view','View purchasing','purchase'),('purchase.create','Create purchasing','purchase'),('purchase.edit','Edit purchasing','purchase'),('purchase.delete','Delete vendor','purchase'),('purchase.approve','Approve purchase request','purchase'),('purchase.receive','Receive goods','purchase'),
('payment.view','View payments','payment'),('payment.create','Record payments','payment'),
('contract.view','View contracts','contract'),('contract.create','Create contracts','contract'),('contract.edit','Edit contracts','contract'),('contract.delete','Delete contracts','contract'),('contract.manage','Manage recurring service','contract'),
('warranty.view','View warranties','warranty'),('warranty.create','Create warranties','warranty'),('warranty.edit','Edit warranties','warranty'),
('portal.manage','Manage customer portal','portal'),('notification.view','View notifications','notification'),
('user.view','View users','user'),('user.create','Create users','user'),('user.edit','Edit users','user'),('user.manage','Manage RBAC','user'),
('settings.view','View settings','settings'),('settings.edit','Edit settings','settings'),
('audit.view','View audit log','audit'),('api.manage','Manage API','api')
ON DUPLICATE KEY UPDATE name=VALUES(name),module=VALUES(module);

-- Give owner/admin all current permissions.
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @owner_role,id FROM permissions;
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @admin_role,id FROM permissions;

SET @svc_role=(SELECT id FROM roles WHERE tenant_id=@tenant AND code='service_manager');
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @svc_role,id FROM permissions WHERE module IN('customer','asset','request','survey','quotation','job','technician','dispatch','report','warranty','notification');
SET @sales_role=(SELECT id FROM roles WHERE tenant_id=@tenant AND code='sales');
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @sales_role,id FROM permissions WHERE module IN('lead','customer','asset','quotation','report');
SET @inv_role=(SELECT id FROM roles WHERE tenant_id=@tenant AND code='inventory');
INSERT IGNORE INTO role_permissions(role_id,permission_id) SELECT @inv_role,id FROM permissions WHERE module IN('inventory','purchase');

INSERT INTO customer_sites(tenant_id,customer_id,site_name,address,contact_person,phone)
SELECT @tenant,id,'Head Office','Jl. Demo No. 1, Manado','Operational Manager','081200000001' FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000001'
ON DUPLICATE KEY UPDATE address=VALUES(address);
SET @site=(SELECT id FROM customer_sites WHERE tenant_id=@tenant AND customer_id=(SELECT id FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000001') LIMIT 1);
INSERT INTO customer_assets(tenant_id,customer_id,site_id,asset_code,category,brand,model,serial_number,installation_date,warranty_start,warranty_end,last_service,next_service,status,public_token)
SELECT @tenant,id,@site,'AST-2026-000001','Router','MikroTik','RB5009','DEMO-RB5009-01','2026-01-10','2026-01-10','2027-01-10','2026-08-10','2026-11-10','active','demoasset000000000000000000000000000001' FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000001'
ON DUPLICATE KEY UPDATE model=VALUES(model);

INSERT INTO leads(tenant_id,lead_number,customer_name,company,phone,email,source,service_interest,estimated_value,status,follow_up_date,notes)
VALUES(@tenant,'LEAD-2026-000001','Rina Manado','PT Contoh Baru','081244400001','rina@example.test','Referral','CCTV Installation',8500000,'Qualified',DATE_ADD(CURDATE(),INTERVAL 3 DAY),'Demo lead')
ON DUPLICATE KEY UPDATE status=VALUES(status);

INSERT INTO quotations(tenant_id,quotation_number,customer_id,quotation_date,valid_until,sales_user_id,status,subtotal,discount,tax,grand_total,terms,notes)
SELECT @tenant,'QUO-2026-000001',id,CURDATE(),DATE_ADD(CURDATE(),INTERVAL 14 DAY),@owner,'Sent',2500000,0,275000,2775000,'Payment 50% before work','Demo quotation' FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000003'
ON DUPLICATE KEY UPDATE status=VALUES(status);
SET @quote=(SELECT id FROM quotations WHERE tenant_id=@tenant AND quotation_number='QUO-2026-000001');
INSERT INTO quotation_items(tenant_id,quotation_id,item_type,description,quantity,unit,unit_price,discount,tax,line_total)
SELECT @tenant,@quote,'service','CCTV maintenance package',1,'job',2500000,0,275000,2775000 WHERE NOT EXISTS(SELECT 1 FROM quotation_items WHERE tenant_id=@tenant AND quotation_id=@quote);

INSERT INTO contracts(tenant_id,contract_number,customer_id,start_date,end_date,value,billing_frequency,service_frequency,sla_name,notes,status)
SELECT @tenant,'CTR-2026-000001',id,'2026-01-01','2026-12-31',12000000,'Quarterly','Every 3 Months','Normal','Annual preventive maintenance','Active' FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000004'
ON DUPLICATE KEY UPDATE status=VALUES(status);
SET @contract=(SELECT id FROM contracts WHERE tenant_id=@tenant AND contract_number='CTR-2026-000001');
INSERT INTO maintenance_schedules(tenant_id,contract_id,customer_id,frequency_type,next_run_at,auto_create_job,active)
SELECT @tenant,@contract,c.id,'Every 3 Months',DATE_ADD(NOW(),INTERVAL 14 DAY),1,1 FROM customers c WHERE c.tenant_id=@tenant AND c.customer_code='CUS-000004' AND NOT EXISTS(SELECT 1 FROM maintenance_schedules m WHERE m.tenant_id=@tenant AND m.contract_id=@contract);

INSERT INTO sla_policies(tenant_id,name,priority,response_minutes,resolution_minutes,active) VALUES
(@tenant,'Default','Emergency',15,240,1),(@tenant,'Default','Urgent',30,480,1),(@tenant,'Default','High',60,480,1),(@tenant,'Default','Normal',240,1440,1),(@tenant,'Default','Low',480,2880,1)
ON DUPLICATE KEY UPDATE response_minutes=VALUES(response_minutes),resolution_minutes=VALUES(resolution_minutes);

INSERT INTO email_templates(tenant_id,template_key,subject,body_html) VALUES
(@tenant,'service_request_received','Service Request {{request_number}} received','<p>We have received your service request.</p>'),
(@tenant,'job_scheduled','Job {{job_number}} scheduled','<p>Your service job has been scheduled.</p>'),
(@tenant,'quotation','Quotation {{quotation_number}}','<p>Please review the attached quotation.</p>'),
(@tenant,'invoice','Invoice {{invoice_number}}','<p>Please review your invoice.</p>'),
(@tenant,'technician_assigned','Technician assigned for {{job_number}}','<p>{{technician_name}} has been assigned to your service job.</p>'),
(@tenant,'job_completed','Job {{job_number}} completed','<p>Your service job has been completed. The service report is now available.</p>'),
(@tenant,'payment_confirmation','Payment received for {{invoice_number}}','<p>Thank you. We have received your payment of {{amount}}.</p>'),
(@tenant,'contract_expiry','Contract {{contract_number}} is expiring','<p>Your service contract will expire on {{end_date}}.</p>'),
(@tenant,'invoice_overdue','Invoice {{invoice_number}} is overdue','<p>Your invoice is overdue. Outstanding balance: {{balance}}.</p>'),
(@tenant,'warranty_expiry','Warranty is expiring','<p>Your service warranty expires on {{warranty_end}}.</p>')
ON DUPLICATE KEY UPDATE subject=VALUES(subject);

INSERT INTO number_sequences(tenant_id,type,year,current_value) VALUES
(@tenant,'lead',YEAR(CURDATE()),1),(@tenant,'asset',YEAR(CURDATE()),1),(@tenant,'service',YEAR(CURDATE()),4),(@tenant,'survey',YEAR(CURDATE()),0),(@tenant,'quotation',YEAR(CURDATE()),1),(@tenant,'vendor',YEAR(CURDATE()),0),(@tenant,'contract',YEAR(CURDATE()),1),(@tenant,'purchase_request',YEAR(CURDATE()),0),(@tenant,'purchase_order',YEAR(CURDATE()),0),(@tenant,'goods_receipt',YEAR(CURDATE()),0),(@tenant,'stock_transfer',YEAR(CURDATE()),0),(@tenant,'service_report',YEAR(CURDATE()),0)
ON DUPLICATE KEY UPDATE current_value=GREATEST(current_value,VALUES(current_value));

INSERT INTO customer_portal_users(tenant_id,customer_id,name,email,password_hash,status)
SELECT @tenant,id,'Demo Customer','customer@demo.com','$2y$12$.TwyKcfD5GxlBS2BdSoOGOSY5Ch0RdF2Px0VaM3.sNjuX.dmW8eDG','active' FROM customers WHERE tenant_id=@tenant AND customer_code='CUS-000001'
ON DUPLICATE KEY UPDATE name=VALUES(name),password_hash=VALUES(password_hash),status='active';


-- Demo metadata and technician skill matrix.
INSERT INTO tags(tenant_id,name) VALUES(@tenant,'VIP'),(@tenant,'Hotel'),(@tenant,'Contract'),(@tenant,'Emergency')
ON DUPLICATE KEY UPDATE name=VALUES(name);
SET @tech_record=(SELECT id FROM technicians WHERE tenant_id=@tenant AND user_id=@techuser LIMIT 1);
INSERT IGNORE INTO technician_skills(tenant_id,technician_id,skill_id,level)
SELECT @tenant,@tech_record,id,4 FROM skills WHERE tenant_id=@tenant AND name IN('Networking','MikroTik','CCTV');
