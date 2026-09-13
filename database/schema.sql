SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE IF NOT EXISTS subscription_plans (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE,
  code VARCHAR(40) NOT NULL UNIQUE,
  user_limit INT NULL,
  branch_limit INT NULL,
  storage_limit_mb INT NULL,
  features JSON NULL,
  price_monthly DECIMAL(14,2) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenants (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  company_code VARCHAR(50) NOT NULL UNIQUE,
  business_type VARCHAR(100) NULL,
  address TEXT NULL,
  phone VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  website VARCHAR(160) NULL,
  tax_number VARCHAR(80) NULL,
  logo VARCHAR(255) NULL,
  signature VARCHAR(255) NULL,
  stamp VARCHAR(255) NULL,
  primary_color VARCHAR(20) NULL DEFAULT '#335CFF',
  invoice_footer TEXT NULL,
  currency VARCHAR(10) NOT NULL DEFAULT 'IDR',
  default_tax DECIMAL(8,2) NOT NULL DEFAULT 0,
  timezone VARCHAR(80) NOT NULL DEFAULT 'Asia/Makassar',
  language VARCHAR(10) NOT NULL DEFAULT 'id',
  invoice_prefix VARCHAR(20) NOT NULL DEFAULT 'INV',
  job_prefix VARCHAR(20) NOT NULL DEFAULT 'JOB',
  quotation_prefix VARCHAR(20) NOT NULL DEFAULT 'QUO',
  status ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS subscriptions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  plan_id BIGINT UNSIGNED NOT NULL,
  status ENUM('trial','active','past_due','expired','cancelled') NOT NULL DEFAULT 'trial',
  starts_at DATETIME NOT NULL,
  trial_ends_at DATETIME NULL,
  ends_at DATETIME NULL,
  amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_sub_tenant_status(tenant_id,status),
  CONSTRAINT fk_sub_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_sub_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS branches (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  address TEXT NULL,
  manager_name VARCHAR(120) NULL,
  phone VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  timezone VARCHAR(80) NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_branch_name(tenant_id,name),
  INDEX idx_branch_tenant(tenant_id),
  CONSTRAINT fk_branch_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NULL,
  branch_id BIGINT UNSIGNED NULL,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(160) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(40) NULL,
  photo VARCHAR(255) NULL,
  language VARCHAR(10) NOT NULL DEFAULT 'id',
  theme ENUM('light','dark','system') NOT NULL DEFAULT 'system',
  two_factor_enabled TINYINT(1) NOT NULL DEFAULT 0,
  two_factor_secret VARCHAR(255) NULL,
  is_platform_admin TINYINT(1) NOT NULL DEFAULT 0,
  status ENUM('active','inactive','locked') NOT NULL DEFAULT 'active',
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_user_email(email),
  INDEX idx_users_tenant(tenant_id),
  CONSTRAINT fk_user_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_user_branch FOREIGN KEY (branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NULL,
  name VARCHAR(80) NOT NULL,
  code VARCHAR(80) NOT NULL,
  is_system TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_role(tenant_id,code),
  CONSTRAINT fk_role_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permissions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(120) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  module VARCHAR(80) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(role_id,permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY(role_id) REFERENCES roles(id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_perm FOREIGN KEY(permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_roles (
  tenant_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(tenant_id,user_id,role_id),
  CONSTRAINT fk_ur_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_ur_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ur_role FOREIGN KEY(role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  customer_code VARCHAR(60) NOT NULL,
  customer_type ENUM('Individual','Company') NOT NULL DEFAULT 'Company',
  name VARCHAR(160) NOT NULL,
  company VARCHAR(160) NULL,
  contact_person VARCHAR(160) NULL,
  phone VARCHAR(40) NULL,
  whatsapp VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  billing_address TEXT NULL,
  service_address TEXT NULL,
  tax_id VARCHAR(80) NULL,
  notes TEXT NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  deleted_by BIGINT UNSIGNED NULL,
  UNIQUE KEY uq_customer_code(tenant_id,customer_code),
  INDEX idx_customer_tenant_name(tenant_id,name),
  CONSTRAINT fk_customer_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customer_contacts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  position VARCHAR(120) NULL,
  phone VARCHAR(40) NULL,
  whatsapp VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  is_primary TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  INDEX idx_contact_tenant_customer(tenant_id,customer_id),
  CONSTRAINT fk_contact_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_contact_customer FOREIGN KEY(customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customer_sites (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  site_name VARCHAR(160) NOT NULL,
  address TEXT NOT NULL,
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  contact_person VARCHAR(160) NULL,
  phone VARCHAR(40) NULL,
  operating_hours VARCHAR(160) NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  INDEX idx_site_tenant_customer(tenant_id,customer_id),
  CONSTRAINT fk_site_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_site_customer FOREIGN KEY(customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customer_assets (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  site_id BIGINT UNSIGNED NULL,
  asset_code VARCHAR(80) NOT NULL,
  category VARCHAR(100) NULL,
  brand VARCHAR(100) NULL,
  model VARCHAR(100) NULL,
  serial_number VARCHAR(120) NULL,
  installation_date DATE NULL,
  warranty_start DATE NULL,
  warranty_end DATE NULL,
  last_service DATE NULL,
  next_service DATE NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'active',
  photo VARCHAR(255) NULL,
  qr_code VARCHAR(255) NULL,
  public_token CHAR(40) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_asset_code(tenant_id,asset_code),
  UNIQUE KEY uq_asset_public_token(public_token),
  INDEX idx_asset_tenant_customer(tenant_id,customer_id),
  CONSTRAINT fk_asset_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_asset_customer FOREIGN KEY(customer_id) REFERENCES customers(id),
  CONSTRAINT fk_asset_site FOREIGN KEY(site_id) REFERENCES customer_sites(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leads (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  lead_number VARCHAR(60) NOT NULL,
  customer_name VARCHAR(160) NOT NULL,
  company VARCHAR(160) NULL,
  phone VARCHAR(40) NULL,
  whatsapp VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  source VARCHAR(100) NULL,
  service_interest VARCHAR(160) NULL,
  estimated_value DECIMAL(14,2) NOT NULL DEFAULT 0,
  sales_user_id BIGINT UNSIGNED NULL,
  status ENUM('New','Contacted','Qualified','Proposal','Negotiation','Won','Lost') NOT NULL DEFAULT 'New',
  follow_up_date DATE NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_lead_no(tenant_id,lead_number),
  INDEX idx_leads_tenant_status(tenant_id,status),
  CONSTRAINT fk_lead_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_lead_sales FOREIGN KEY(sales_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_service_cat(tenant_id,name),
  CONSTRAINT fk_servicecat_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS services (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  service_code VARCHAR(60) NOT NULL,
  service_name VARCHAR(160) NOT NULL,
  category_id BIGINT UNSIGNED NULL,
  description TEXT NULL,
  default_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  estimated_duration INT NULL,
  taxable TINYINT(1) NOT NULL DEFAULT 1,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_service_code(tenant_id,service_code),
  CONSTRAINT fk_service_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_service_category FOREIGN KEY(category_id) REFERENCES service_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  request_number VARCHAR(70) NOT NULL,
  request_date DATE NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  site_id BIGINT UNSIGNED NULL,
  asset_id BIGINT UNSIGNED NULL,
  service_category VARCHAR(120) NULL,
  problem_description TEXT NOT NULL,
  priority ENUM('Low','Normal','High','Urgent','Emergency') NOT NULL DEFAULT 'Normal',
  requested_date DATE NULL,
  contact_person VARCHAR(160) NULL,
  status ENUM('New','Reviewed','Need Survey','Quoted','Approved','Scheduled','Assigned','In Progress','On Hold','Completed','Cancelled','Closed') NOT NULL DEFAULT 'New',
  response_deadline DATETIME NULL,
  resolution_deadline DATETIME NULL,
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  deleted_by BIGINT UNSIGNED NULL,
  UNIQUE KEY uq_request_no(tenant_id,request_number),
  INDEX idx_request_tenant_status(tenant_id,status),
  CONSTRAINT fk_request_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_request_customer FOREIGN KEY(customer_id) REFERENCES customers(id),
  CONSTRAINT fk_request_site FOREIGN KEY(site_id) REFERENCES customer_sites(id),
  CONSTRAINT fk_request_asset FOREIGN KEY(asset_id) REFERENCES customer_assets(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS surveys (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  survey_number VARCHAR(70) NOT NULL,
  service_request_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  site_id BIGINT UNSIGNED NULL,
  surveyor_id BIGINT UNSIGNED NULL,
  survey_date DATE NOT NULL,
  findings TEXT NULL,
  recommended_solution TEXT NULL,
  estimated_materials TEXT NULL,
  estimated_labor DECIMAL(14,2) NOT NULL DEFAULT 0,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_survey_no(tenant_id,survey_number),
  CONSTRAINT fk_survey_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_survey_request FOREIGN KEY(service_request_id) REFERENCES service_requests(id),
  CONSTRAINT fk_survey_customer FOREIGN KEY(customer_id) REFERENCES customers(id),
  CONSTRAINT fk_survey_site FOREIGN KEY(site_id) REFERENCES customer_sites(id),
  CONSTRAINT fk_survey_user FOREIGN KEY(surveyor_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS quotations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  quotation_number VARCHAR(70) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  survey_id BIGINT UNSIGNED NULL,
  quotation_date DATE NOT NULL,
  valid_until DATE NULL,
  sales_user_id BIGINT UNSIGNED NULL,
  status ENUM('Draft','Internal Review','Sent','Viewed','Approved','Rejected','Expired') NOT NULL DEFAULT 'Draft',
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0,
  discount DECIMAL(14,2) NOT NULL DEFAULT 0,
  tax DECIMAL(14,2) NOT NULL DEFAULT 0,
  grand_total DECIMAL(14,2) NOT NULL DEFAULT 0,
  terms TEXT NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_quotation_no(tenant_id,quotation_number),
  CONSTRAINT fk_quote_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_quote_customer FOREIGN KEY(customer_id) REFERENCES customers(id),
  CONSTRAINT fk_quote_survey FOREIGN KEY(survey_id) REFERENCES surveys(id),
  CONSTRAINT fk_quote_sales FOREIGN KEY(sales_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS quotation_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  quotation_id BIGINT UNSIGNED NOT NULL,
  item_type ENUM('service','material','other') NOT NULL DEFAULT 'service',
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(12,2) NOT NULL DEFAULT 1,
  unit VARCHAR(40) NULL,
  unit_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  discount DECIMAL(14,2) NOT NULL DEFAULT 0,
  tax DECIMAL(14,2) NOT NULL DEFAULT 0,
  line_total DECIMAL(14,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_qitem_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_qitem_quote FOREIGN KEY(quotation_id) REFERENCES quotations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS jobs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_number VARCHAR(70) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  site_id BIGINT UNSIGNED NULL,
  asset_id BIGINT UNSIGNED NULL,
  service_request_id BIGINT UNSIGNED NULL,
  quotation_id BIGINT UNSIGNED NULL,
  service_category VARCHAR(120) NULL,
  description TEXT NOT NULL,
  priority ENUM('Low','Normal','High','Urgent','Emergency') NOT NULL DEFAULT 'Normal',
  scheduled_date DATETIME NULL,
  estimated_duration INT NULL,
  status ENUM('Draft','Scheduled','Assigned','On The Way','Arrived','In Progress','On Hold','Completed','Customer Confirmation','Closed','Cancelled') NOT NULL DEFAULT 'Draft',
  internal_notes TEXT NULL,
  customer_notes TEXT NULL,
  checkin_latitude DECIMAL(10,7) NULL,
  checkin_longitude DECIMAL(10,7) NULL,
  checked_in_at DATETIME NULL,
  started_at DATETIME NULL,
  completed_at DATETIME NULL,
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  deleted_by BIGINT UNSIGNED NULL,
  UNIQUE KEY uq_job_no(tenant_id,job_number),
  INDEX idx_job_tenant_status(tenant_id,status),
  INDEX idx_job_tenant_schedule(tenant_id,scheduled_date),
  CONSTRAINT fk_job_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_job_customer FOREIGN KEY(customer_id) REFERENCES customers(id),
  CONSTRAINT fk_job_site FOREIGN KEY(site_id) REFERENCES customer_sites(id),
  CONSTRAINT fk_job_asset FOREIGN KEY(asset_id) REFERENCES customer_assets(id),
  CONSTRAINT fk_job_request FOREIGN KEY(service_request_id) REFERENCES service_requests(id),
  CONSTRAINT fk_job_quote FOREIGN KEY(quotation_id) REFERENCES quotations(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_technicians (
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(tenant_id,job_id,user_id),
  CONSTRAINT fk_jt_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_jt_job FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  CONSTRAINT fk_jt_user FOREIGN KEY(user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_status_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  old_status VARCHAR(50) NULL,
  new_status VARCHAR(50) NOT NULL,
  changed_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_jsh_job(tenant_id,job_id,created_at),
  CONSTRAINT fk_jsh_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_jsh_job FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_work_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  technician_id BIGINT UNSIGNED NOT NULL,
  start_time DATETIME NULL,
  finish_time DATETIME NULL,
  activity TEXT NULL,
  problem_found TEXT NULL,
  action_taken TEXT NULL,
  result TEXT NULL,
  recommendation TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_jwl_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_jwl_job FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  CONSTRAINT fk_jwl_user FOREIGN KEY(technician_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_photos (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  technician_id BIGINT UNSIGNED NULL,
  type ENUM('before','during','after') NOT NULL,
  path VARCHAR(255) NOT NULL,
  caption VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_jphoto_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_jphoto_job FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS skills (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_skill(tenant_id,name),
  CONSTRAINT fk_skill_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS technicians (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NULL,
  certification TEXT NULL,
  availability VARCHAR(40) NOT NULL DEFAULT 'Available',
  work_schedule JSON NULL,
  status ENUM('Available','Assigned','On The Way','Working','Break','Leave','Offline') NOT NULL DEFAULT 'Available',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_technician_user(tenant_id,user_id),
  CONSTRAINT fk_tech_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_tech_user FOREIGN KEY(user_id) REFERENCES users(id),
  CONSTRAINT fk_tech_branch FOREIGN KEY(branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS technician_skills (
  tenant_id BIGINT UNSIGNED NOT NULL,
  technician_id BIGINT UNSIGNED NOT NULL,
  skill_id BIGINT UNSIGNED NOT NULL,
  level TINYINT UNSIGNED NOT NULL DEFAULT 3,
  PRIMARY KEY(tenant_id,technician_id,skill_id),
  CONSTRAINT fk_ts_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_ts_tech FOREIGN KEY(technician_id) REFERENCES technicians(id) ON DELETE CASCADE,
  CONSTRAINT fk_ts_skill FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_required_skills (
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  skill_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(tenant_id,job_id,skill_id),
  INDEX idx_jrs_job(tenant_id,job_id),
  CONSTRAINT fk_jrs_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_jrs_job FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  CONSTRAINT fk_jrs_skill FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS warehouses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NULL,
  name VARCHAR(120) NOT NULL,
  type ENUM('main','branch','technician','vehicle') NOT NULL DEFAULT 'main',
  location VARCHAR(255) NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_warehouse(tenant_id,name),
  CONSTRAINT fk_wh_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_wh_branch FOREIGN KEY(branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  sku VARCHAR(80) NOT NULL,
  item_name VARCHAR(160) NOT NULL,
  category VARCHAR(100) NULL,
  brand VARCHAR(100) NULL,
  unit VARCHAR(40) NOT NULL DEFAULT 'pcs',
  purchase_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  selling_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  minimum_stock DECIMAL(14,2) NOT NULL DEFAULT 0,
  barcode VARCHAR(120) NULL,
  location VARCHAR(160) NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_item_sku(tenant_id,sku),
  INDEX idx_item_tenant_name(tenant_id,item_name),
  CONSTRAINT fk_item_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stock_balances (
  tenant_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NOT NULL,
  quantity DECIMAL(14,2) NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY(tenant_id,warehouse_id,item_id),
  CONSTRAINT fk_sb_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_sb_wh FOREIGN KEY(warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_sb_item FOREIGN KEY(item_id) REFERENCES items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stock_movements (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NOT NULL,
  movement_type ENUM('receipt','issue','usage','transfer_in','transfer_out','adjustment','return') NOT NULL,
  quantity DECIMAL(14,2) NOT NULL,
  reference_type VARCHAR(50) NULL,
  reference_id BIGINT UNSIGNED NULL,
  notes VARCHAR(255) NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sm_tenant_item(tenant_id,item_id,created_at),
  CONSTRAINT fk_sm_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_sm_wh FOREIGN KEY(warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_sm_item FOREIGN KEY(item_id) REFERENCES items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_materials (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  technician_id BIGINT UNSIGNED NULL,
  quantity DECIMAL(14,2) NOT NULL,
  unit_cost DECIMAL(14,2) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_jm_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_jm_job FOREIGN KEY(job_id) REFERENCES jobs(id),
  CONSTRAINT fk_jm_item FOREIGN KEY(item_id) REFERENCES items(id),
  CONSTRAINT fk_jm_wh FOREIGN KEY(warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stock_transfers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  transfer_number VARCHAR(70) NOT NULL,
  from_warehouse_id BIGINT UNSIGNED NOT NULL,
  to_warehouse_id BIGINT UNSIGNED NOT NULL,
  status ENUM('Draft','Approved','In Transit','Received','Cancelled') NOT NULL DEFAULT 'Draft',
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_transfer_no(tenant_id,transfer_number),
  CONSTRAINT fk_st_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_st_from FOREIGN KEY(from_warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_st_to FOREIGN KEY(to_warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS vendors (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  vendor_code VARCHAR(60) NOT NULL,
  vendor_name VARCHAR(160) NOT NULL,
  contact VARCHAR(160) NULL,
  phone VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  address TEXT NULL,
  tax_id VARCHAR(80) NULL,
  category VARCHAR(100) NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_vendor_code(tenant_id,vendor_code),
  CONSTRAINT fk_vendor_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS purchase_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  request_number VARCHAR(70) NOT NULL,
  requester_id BIGINT UNSIGNED NOT NULL,
  branch_id BIGINT UNSIGNED NULL,
  status ENUM('Request','Approved','Rejected','Purchasing','PO Created','Received') NOT NULL DEFAULT 'Request',
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pr_no(tenant_id,request_number),
  CONSTRAINT fk_pr_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_pr_user FOREIGN KEY(requester_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS purchase_request_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  purchase_request_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(14,2) NOT NULL,
  unit VARCHAR(40) NULL,
  CONSTRAINT fk_pri_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_pri_pr FOREIGN KEY(purchase_request_id) REFERENCES purchase_requests(id) ON DELETE CASCADE,
  CONSTRAINT fk_pri_item FOREIGN KEY(item_id) REFERENCES items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS purchase_orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  po_number VARCHAR(70) NOT NULL,
  vendor_id BIGINT UNSIGNED NOT NULL,
  purchase_request_id BIGINT UNSIGNED NULL,
  order_date DATE NOT NULL,
  expected_date DATE NULL,
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0,
  tax DECIMAL(14,2) NOT NULL DEFAULT 0,
  total DECIMAL(14,2) NOT NULL DEFAULT 0,
  status ENUM('Draft','Sent','Partial','Received','Cancelled') NOT NULL DEFAULT 'Draft',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_po_no(tenant_id,po_number),
  CONSTRAINT fk_po_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_po_vendor FOREIGN KEY(vendor_id) REFERENCES vendors(id),
  CONSTRAINT fk_po_pr FOREIGN KEY(purchase_request_id) REFERENCES purchase_requests(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS purchase_order_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  purchase_order_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(14,2) NOT NULL,
  unit_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  line_total DECIMAL(14,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_poi_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_poi_po FOREIGN KEY(purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_poi_item FOREIGN KEY(item_id) REFERENCES items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS goods_receipts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  receipt_number VARCHAR(70) NOT NULL,
  purchase_order_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  received_date DATE NOT NULL,
  received_by BIGINT UNSIGNED NOT NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_gr_no(tenant_id,receipt_number),
  CONSTRAINT fk_gr_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_gr_po FOREIGN KEY(purchase_order_id) REFERENCES purchase_orders(id),
  CONSTRAINT fk_gr_wh FOREIGN KEY(warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_gr_user FOREIGN KEY(received_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoices (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  invoice_number VARCHAR(70) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NULL,
  quotation_id BIGINT UNSIGNED NULL,
  contract_id BIGINT UNSIGNED NULL,
  invoice_date DATE NOT NULL,
  due_date DATE NULL,
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0,
  discount DECIMAL(14,2) NOT NULL DEFAULT 0,
  tax DECIMAL(14,2) NOT NULL DEFAULT 0,
  total DECIMAL(14,2) NOT NULL DEFAULT 0,
  paid DECIMAL(14,2) NOT NULL DEFAULT 0,
  balance DECIMAL(14,2) NOT NULL DEFAULT 0,
  status ENUM('Draft','Sent','Partial','Paid','Overdue','Cancelled') NOT NULL DEFAULT 'Draft',
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_invoice_no(tenant_id,invoice_number),
  INDEX idx_invoice_tenant_status(tenant_id,status),
  CONSTRAINT fk_invoice_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_invoice_customer FOREIGN KEY(customer_id) REFERENCES customers(id),
  CONSTRAINT fk_invoice_job FOREIGN KEY(job_id) REFERENCES jobs(id),
  CONSTRAINT fk_invoice_quote FOREIGN KEY(quotation_id) REFERENCES quotations(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoice_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(14,2) NOT NULL DEFAULT 1,
  unit VARCHAR(40) NULL,
  unit_price DECIMAL(14,2) NOT NULL DEFAULT 0,
  discount DECIMAL(14,2) NOT NULL DEFAULT 0,
  tax DECIMAL(14,2) NOT NULL DEFAULT 0,
  line_total DECIMAL(14,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_ii_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_ii_invoice FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  payment_date DATE NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  payment_method ENUM('Cash','Bank Transfer','QRIS','Credit Card','Other') NOT NULL,
  bank VARCHAR(120) NULL,
  reference VARCHAR(120) NULL,
  attachment VARCHAR(255) NULL,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_payments_tenant_date(tenant_id,payment_date),
  CONSTRAINT fk_payment_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_payment_invoice FOREIGN KEY(invoice_id) REFERENCES invoices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_expenses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  category ENUM('Transportation','Parking','Fuel','Accommodation','Food','Tools','Other') NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  receipt VARCHAR(255) NULL,
  notes TEXT NULL,
  expense_date DATE NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_exp_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_exp_job FOREIGN KEY(job_id) REFERENCES jobs(id),
  CONSTRAINT fk_exp_user FOREIGN KEY(user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contracts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  contract_number VARCHAR(70) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  value DECIMAL(14,2) NOT NULL DEFAULT 0,
  billing_frequency VARCHAR(50) NULL,
  service_frequency VARCHAR(50) NULL,
  sla_name VARCHAR(100) NULL,
  notes TEXT NULL,
  status ENUM('Draft','Active','Expired','Cancelled') NOT NULL DEFAULT 'Draft',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_contract_no(tenant_id,contract_number),
  CONSTRAINT fk_contract_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_contract_customer FOREIGN KEY(customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contract_assets (
  tenant_id BIGINT UNSIGNED NOT NULL,
  contract_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(tenant_id,contract_id,asset_id),
  CONSTRAINT fk_ca_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_ca_contract FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE,
  CONSTRAINT fk_ca_asset FOREIGN KEY(asset_id) REFERENCES customer_assets(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS maintenance_schedules (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  contract_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NULL,
  frequency_type VARCHAR(40) NOT NULL,
  next_run_at DATETIME NOT NULL,
  last_run_at DATETIME NULL,
  auto_create_job TINYINT(1) NOT NULL DEFAULT 1,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_ms_tenant_next(tenant_id,next_run_at,active),
  CONSTRAINT fk_ms_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_ms_contract FOREIGN KEY(contract_id) REFERENCES contracts(id),
  CONSTRAINT fk_ms_customer FOREIGN KEY(customer_id) REFERENCES customers(id),
  CONSTRAINT fk_ms_asset FOREIGN KEY(asset_id) REFERENCES customer_assets(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS warranties (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  warranty_start DATE NOT NULL,
  warranty_end DATE NOT NULL,
  coverage TEXT NULL,
  terms TEXT NULL,
  status ENUM('Active','Expired','Voided') NOT NULL DEFAULT 'Active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_warranty_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_warranty_job FOREIGN KEY(job_id) REFERENCES jobs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS documents (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  entity_type VARCHAR(60) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  category VARCHAR(80) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(255) NOT NULL,
  mime_type VARCHAR(120) NULL,
  file_size BIGINT UNSIGNED NULL,
  uploaded_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_doc_entity(tenant_id,entity_type,entity_id),
  CONSTRAINT fk_doc_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS comments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  entity_type VARCHAR(60) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  body TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_comment_entity(tenant_id,entity_type,entity_id),
  CONSTRAINT fk_comment_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_comment_user FOREIGN KEY(user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NULL,
  user_id BIGINT UNSIGNED NULL,
  type VARCHAR(80) NOT NULL,
  title VARCHAR(180) NOT NULL,
  message TEXT NOT NULL,
  data JSON NULL,
  read_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notify_user(tenant_id,user_id,read_at),
  CONSTRAINT fk_notify_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_notify_user FOREIGN KEY(user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NULL,
  user_id BIGINT UNSIGNED NULL,
  action VARCHAR(60) NOT NULL,
  module VARCHAR(80) NOT NULL,
  record_id BIGINT UNSIGNED NULL,
  old_value JSON NULL,
  new_value JSON NULL,
  ip_address VARCHAR(64) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_tenant_module(tenant_id,module,created_at),
  CONSTRAINT fk_audit_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_audit_user FOREIGN KEY(user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS custom_fields (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  entity_type VARCHAR(60) NOT NULL,
  field_key VARCHAR(80) NOT NULL,
  label VARCHAR(120) NOT NULL,
  field_type VARCHAR(40) NOT NULL DEFAULT 'text',
  options JSON NULL,
  required TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_custom_field(tenant_id,entity_type,field_key),
  CONSTRAINT fk_cf_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS custom_field_values (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  custom_field_id BIGINT UNSIGNED NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  value_text TEXT NULL,
  UNIQUE KEY uq_cfv(tenant_id,custom_field_id,entity_id),
  CONSTRAINT fk_cfv_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_cfv_field FOREIGN KEY(custom_field_id) REFERENCES custom_fields(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS settings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NULL,
  setting_key VARCHAR(120) NOT NULL,
  setting_value TEXT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_setting(tenant_id,setting_key),
  CONSTRAINT fk_setting_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS number_sequences (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  type VARCHAR(50) NOT NULL,
  year SMALLINT UNSIGNED NOT NULL,
  current_value BIGINT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_seq(tenant_id,type,year),
  CONSTRAINT fk_seq_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS login_attempts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(160) NOT NULL,
  ip_address VARCHAR(64) NULL,
  succeeded TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_login_email_time(email,created_at),
  INDEX idx_login_ip_time(ip_address,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




CREATE TABLE IF NOT EXISTS sla_policies (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  priority ENUM('Low','Normal','High','Urgent','Emergency') NOT NULL,
  response_minutes INT UNSIGNED NOT NULL,
  resolution_minutes INT UNSIGNED NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_sla_priority(tenant_id,name,priority),
  CONSTRAINT fk_sla_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS job_signatures (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  signature_type ENUM('technician','customer') NOT NULL,
  signer_name VARCHAR(160) NOT NULL,
  signature_path VARCHAR(255) NOT NULL,
  rating TINYINT UNSIGNED NULL,
  feedback TEXT NULL,
  signed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(64) NULL,
  CONSTRAINT fk_jsig_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_jsig_job FOREIGN KEY(job_id) REFERENCES jobs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS recurring_jobs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  site_id BIGINT UNSIGNED NULL,
  asset_id BIGINT UNSIGNED NULL,
  title VARCHAR(180) NOT NULL,
  service_category VARCHAR(120) NULL,
  description TEXT NULL,
  recurrence_rule VARCHAR(255) NOT NULL,
  next_run_at DATETIME NOT NULL,
  last_run_at DATETIME NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_recurring_due(tenant_id,active,next_run_at),
  CONSTRAINT fk_rj_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_rj_customer FOREIGN KEY(customer_id) REFERENCES customers(id),
  CONSTRAINT fk_rj_site FOREIGN KEY(site_id) REFERENCES customer_sites(id),
  CONSTRAINT fk_rj_asset FOREIGN KEY(asset_id) REFERENCES customer_assets(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tags (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(80) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tag(tenant_id,name),
  CONSTRAINT fk_tag_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS entity_tags (
  tenant_id BIGINT UNSIGNED NOT NULL,
  tag_id BIGINT UNSIGNED NOT NULL,
  entity_type VARCHAR(60) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(tenant_id,tag_id,entity_type,entity_id),
  INDEX idx_entity_tag_lookup(tenant_id,entity_type,entity_id),
  CONSTRAINT fk_et_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_et_tag FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS api_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  scopes JSON NULL,
  last_used_at DATETIME NULL,
  expires_at DATETIME NULL,
  revoked_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_api_tenant_user(tenant_id,user_id),
  CONSTRAINT fk_api_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_api_user FOREIGN KEY(user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS webhooks (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  endpoint_url VARCHAR(500) NOT NULL,
  secret VARCHAR(255) NOT NULL,
  events JSON NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_webhook_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS webhook_deliveries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  webhook_id BIGINT UNSIGNED NOT NULL,
  event_name VARCHAR(100) NOT NULL,
  payload JSON NOT NULL,
  response_code SMALLINT NULL,
  response_body TEXT NULL,
  attempts SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  delivered_at DATETIME NULL,
  next_attempt_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_webhook_retry(tenant_id,delivered_at,next_attempt_at),
  CONSTRAINT fk_wd_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_wd_webhook FOREIGN KEY(webhook_id) REFERENCES webhooks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_prt_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  session_hash CHAR(64) NOT NULL UNIQUE,
  ip_address VARCHAR(64) NULL,
  user_agent VARCHAR(500) NULL,
  last_seen_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_session_user(user_id,revoked_at),
  CONSTRAINT fk_session_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS customer_portal_users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  email VARCHAR(160) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  status ENUM('active','inactive','locked') NOT NULL DEFAULT 'active',
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_portal_email(tenant_id,email),
  INDEX idx_portal_customer(tenant_id,customer_id),
  CONSTRAINT fk_portal_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_portal_customer FOREIGN KEY(customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customer_payment_proofs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  portal_user_id BIGINT UNSIGNED NOT NULL,
  payment_date DATE NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  payment_method ENUM('Cash','Bank Transfer','QRIS','Credit Card','Other') NOT NULL DEFAULT 'Bank Transfer',
  bank VARCHAR(120) NULL, reference VARCHAR(120) NULL, attachment VARCHAR(255) NOT NULL, notes TEXT NULL,
  status ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending', reviewed_by BIGINT UNSIGNED NULL, reviewed_at DATETIME NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cpp_tenant_status(tenant_id,status,created_at),
  CONSTRAINT fk_cpp_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id), CONSTRAINT fk_cpp_invoice FOREIGN KEY(invoice_id) REFERENCES invoices(id),
  CONSTRAINT fk_cpp_portal FOREIGN KEY(portal_user_id) REFERENCES customer_portal_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS quotation_approvals (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  quotation_id BIGINT UNSIGNED NOT NULL,
  action ENUM('Approved','Rejected') NOT NULL,
  customer_name VARCHAR(160) NOT NULL,
  customer_email VARCHAR(160) NULL,
  signature_path VARCHAR(255) NULL,
  notes TEXT NULL,
  approved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(64) NULL,
  INDEX idx_qa_quote(tenant_id,quotation_id),
  CONSTRAINT fk_qa_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_qa_quote FOREIGN KEY(quotation_id) REFERENCES quotations(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS goods_receipt_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  goods_receipt_id BIGINT UNSIGNED NOT NULL,
  purchase_order_item_id BIGINT UNSIGNED NULL,
  item_id BIGINT UNSIGNED NULL,
  quantity DECIMAL(14,2) NOT NULL,
  unit_cost DECIMAL(14,2) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_gri_receipt(tenant_id,goods_receipt_id),
  CONSTRAINT fk_gri_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_gri_receipt FOREIGN KEY(goods_receipt_id) REFERENCES goods_receipts(id),
  CONSTRAINT fk_gri_po_item FOREIGN KEY(purchase_order_item_id) REFERENCES purchase_order_items(id),
  CONSTRAINT fk_gri_item FOREIGN KEY(item_id) REFERENCES items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stock_transfer_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  stock_transfer_id BIGINT UNSIGNED NOT NULL,
  item_id BIGINT UNSIGNED NOT NULL,
  quantity DECIMAL(14,2) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sti_transfer(tenant_id,stock_transfer_id),
  CONSTRAINT fk_sti_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_sti_transfer FOREIGN KEY(stock_transfer_id) REFERENCES stock_transfers(id),
  CONSTRAINT fk_sti_item FOREIGN KEY(item_id) REFERENCES items(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS service_reports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  job_id BIGINT UNSIGNED NOT NULL,
  report_number VARCHAR(70) NOT NULL,
  generated_by BIGINT UNSIGNED NULL,
  file_path VARCHAR(255) NULL,
  customer_confirmed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_service_report(tenant_id,report_number),
  UNIQUE KEY uq_service_report_job(tenant_id,job_id),
  CONSTRAINT fk_srpt_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_srpt_job FOREIGN KEY(job_id) REFERENCES jobs(id),
  CONSTRAINT fk_srpt_user FOREIGN KEY(generated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS email_templates (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  template_key VARCHAR(100) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  body_html MEDIUMTEXT NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_email_template(tenant_id,template_key),
  CONSTRAINT fk_email_template_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS backup_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NULL,
  backup_type ENUM('database','files','full') NOT NULL,
  file_path VARCHAR(255) NULL,
  file_size BIGINT UNSIGNED NULL,
  status ENUM('running','success','failed') NOT NULL DEFAULT 'running',
  message TEXT NULL,
  initiated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  INDEX idx_backup_tenant(tenant_id,created_at),
  CONSTRAINT fk_backup_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_backup_user FOREIGN KEY(initiated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS activity_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  entity_type VARCHAR(60) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(100) NOT NULL,
  description TEXT NULL,
  user_id BIGINT UNSIGNED NULL,
  metadata JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_activity_entity(tenant_id,entity_type,entity_id,created_at),
  CONSTRAINT fk_activity_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_activity_user FOREIGN KEY(user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tenant_feature_overrides (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  feature_key VARCHAR(100) NOT NULL,
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  limit_value VARCHAR(100) NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_feature_override(tenant_id,feature_key),
  CONSTRAINT fk_feature_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS subscription_payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tenant_id BIGINT UNSIGNED NOT NULL,
  subscription_id BIGINT UNSIGNED NOT NULL,
  payment_date DATE NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  method VARCHAR(80) NULL,
  reference VARCHAR(120) NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sp_tenant FOREIGN KEY(tenant_id) REFERENCES tenants(id),
  CONSTRAINT fk_sp_subscription FOREIGN KEY(subscription_id) REFERENCES subscriptions(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS=1;
