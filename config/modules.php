<?php
return [
 'leads'=>[
  'title'=>'Leads','table'=>'leads','permission'=>'lead','soft_delete'=>true,'order'=>'id DESC','number'=>['field'=>'lead_number','type'=>'lead','prefix'=>'LEAD'],
  'list'=>['lead_number'=>'Lead','customer_name'=>'Name','company'=>'Company','service_interest'=>'Interest','estimated_value'=>'Value','status'=>'Status','follow_up_date'=>'Follow-up'],
  'fields'=>[
   ['name'=>'customer_name','label'=>'Customer Name','required'=>true],['name'=>'company','label'=>'Company'],['name'=>'phone','label'=>'Phone'],['name'=>'whatsapp','label'=>'WhatsApp'],['name'=>'email','label'=>'Email','type'=>'email'],['name'=>'source','label'=>'Source'],['name'=>'service_interest','label'=>'Service Interest'],['name'=>'estimated_value','label'=>'Estimated Value','type'=>'number','step'=>'0.01'],['name'=>'status','label'=>'Status','type'=>'select','options'=>['New','Contacted','Qualified','Proposal','Negotiation','Won','Lost']],['name'=>'follow_up_date','label'=>'Follow-up Date','type'=>'date'],['name'=>'notes','label'=>'Notes','type'=>'textarea']
  ]
 ],
 'customer-sites'=>[
  'title'=>'Customer Sites','table'=>'customer_sites','permission'=>'customer','soft_delete'=>true,'order'=>'id DESC',
  'list'=>['site_name'=>'Site','customer_id'=>'Customer ID','address'=>'Address','contact_person'=>'Contact','phone'=>'Phone'],
  'fields'=>[
   ['name'=>'customer_id','label'=>'Customer','type'=>'select_sql','sql'=>'SELECT id,name label FROM customers WHERE tenant_id=? AND deleted_at IS NULL ORDER BY name','required'=>true],['name'=>'site_name','label'=>'Site Name','required'=>true],['name'=>'address','label'=>'Address','type'=>'textarea','required'=>true],['name'=>'latitude','label'=>'Latitude','type'=>'number','step'=>'0.0000001'],['name'=>'longitude','label'=>'Longitude','type'=>'number','step'=>'0.0000001'],['name'=>'contact_person','label'=>'Contact Person'],['name'=>'phone','label'=>'Phone'],['name'=>'operating_hours','label'=>'Operating Hours'],['name'=>'notes','label'=>'Notes','type'=>'textarea']
  ]
 ],
 'customer-assets'=>[
  'title'=>'Customer Assets','table'=>'customer_assets','permission'=>'asset','soft_delete'=>true,'order'=>'id DESC','number'=>['field'=>'asset_code','type'=>'asset','prefix'=>'AST'],
  'list'=>['asset_code'=>'Asset','customer_id'=>'Customer ID','category'=>'Category','brand'=>'Brand','model'=>'Model','serial_number'=>'Serial','status'=>'Status','next_service'=>'Next Service'],
  'fields'=>[
   ['name'=>'customer_id','label'=>'Customer','type'=>'select_sql','sql'=>'SELECT id,name label FROM customers WHERE tenant_id=? AND deleted_at IS NULL ORDER BY name','required'=>true],['name'=>'site_id','label'=>'Site','type'=>'select_sql','sql'=>'SELECT id,CONCAT(site_name," · ",address) label FROM customer_sites WHERE tenant_id=? AND deleted_at IS NULL ORDER BY site_name'],['name'=>'category','label'=>'Category'],['name'=>'brand','label'=>'Brand'],['name'=>'model','label'=>'Model'],['name'=>'serial_number','label'=>'Serial Number'],['name'=>'installation_date','label'=>'Installation Date','type'=>'date'],['name'=>'warranty_start','label'=>'Warranty Start','type'=>'date'],['name'=>'warranty_end','label'=>'Warranty End','type'=>'date'],['name'=>'last_service','label'=>'Last Service','type'=>'date'],['name'=>'next_service','label'=>'Next Service','type'=>'date'],['name'=>'status','label'=>'Status','type'=>'select','options'=>['active','inactive','retired']]
  ]
 ],
 'service-categories'=>[
  'title'=>'Service Categories','table'=>'service_categories','permission'=>'catalog','soft_delete'=>false,'order'=>'name ASC',
  'list'=>['name'=>'Category','status'=>'Status'],
  'fields'=>[
   ['name'=>'name','label'=>'Category Name','required'=>true],['name'=>'status','label'=>'Status','type'=>'select','options'=>['active','inactive']]
  ]
 ],
 'service-catalog'=>[
  'title'=>'Service Catalog','table'=>'services','permission'=>'catalog','soft_delete'=>true,'order'=>'service_name ASC','number'=>['field'=>'service_code','type'=>'service','prefix'=>'SRV'],
  'list'=>['service_code'=>'Code','service_name'=>'Service','category_id'=>'Category ID','default_price'=>'Default Price','estimated_duration'=>'Duration (min)','taxable'=>'Taxable','active'=>'Active'],
  'fields'=>[
   ['name'=>'service_name','label'=>'Service Name','required'=>true],['name'=>'category_id','label'=>'Category','type'=>'select_sql','sql'=>'SELECT id,name label FROM service_categories WHERE tenant_id=? ORDER BY name'],['name'=>'description','label'=>'Description','type'=>'textarea'],['name'=>'default_price','label'=>'Default Price','type'=>'number','step'=>'0.01'],['name'=>'estimated_duration','label'=>'Estimated Duration (minutes)','type'=>'number'],['name'=>'taxable','label'=>'Taxable','type'=>'select','options'=>['1'=>'Yes','0'=>'No']],['name'=>'active','label'=>'Active','type'=>'select','options'=>['1'=>'Yes','0'=>'No']]
  ]
 ],
 'technicians'=>[
  'title'=>'Technicians','table'=>'technicians','permission'=>'technician','soft_delete'=>false,'order'=>'id DESC',
  'list'=>['user_id'=>'User ID','branch_id'=>'Branch ID','certification'=>'Certification','availability'=>'Availability','status'=>'Status'],
  'fields'=>[
   ['name'=>'user_id','label'=>'User','type'=>'select_sql','sql'=>'SELECT id,CONCAT(name," · ",email) label FROM users WHERE tenant_id=? AND deleted_at IS NULL ORDER BY name','required'=>true],['name'=>'branch_id','label'=>'Branch','type'=>'select_sql','sql'=>'SELECT id,name label FROM branches WHERE tenant_id=? AND deleted_at IS NULL ORDER BY name'],['name'=>'certification','label'=>'Certification','type'=>'textarea'],['name'=>'availability','label'=>'Availability'],['name'=>'status','label'=>'Status','type'=>'select','options'=>['Available','Assigned','On The Way','Working','Break','Leave','Offline']]
  ]
 ],
 'skills'=>[
  'title'=>'Technician Skills','table'=>'skills','permission'=>'technician','soft_delete'=>false,'order'=>'name ASC','list'=>['name'=>'Skill'],
  'fields'=>[['name'=>'name','label'=>'Skill Name','required'=>true]]
 ],
 'warehouses'=>[
  'title'=>'Warehouses','table'=>'warehouses','permission'=>'inventory','soft_delete'=>true,'order'=>'name ASC','list'=>['name'=>'Warehouse','type'=>'Type','location'=>'Location','status'=>'Status'],
  'fields'=>[
   ['name'=>'branch_id','label'=>'Branch','type'=>'select_sql','sql'=>'SELECT id,name label FROM branches WHERE tenant_id=? AND deleted_at IS NULL ORDER BY name'],['name'=>'name','label'=>'Warehouse Name','required'=>true],['name'=>'type','label'=>'Type','type'=>'select','options'=>['main','branch','technician','vehicle']],['name'=>'location','label'=>'Location'],['name'=>'status','label'=>'Status','type'=>'select','options'=>['active','inactive']]
  ]
 ],
 'vendors'=>[
  'title'=>'Vendors','table'=>'vendors','permission'=>'purchase','soft_delete'=>true,'order'=>'vendor_name ASC','number'=>['field'=>'vendor_code','type'=>'vendor','prefix'=>'VEN'],
  'list'=>['vendor_code'=>'Code','vendor_name'=>'Vendor','contact'=>'Contact','phone'=>'Phone','email'=>'Email','category'=>'Category'],
  'fields'=>[
   ['name'=>'vendor_name','label'=>'Vendor Name','required'=>true],['name'=>'contact','label'=>'Contact'],['name'=>'phone','label'=>'Phone'],['name'=>'email','label'=>'Email','type'=>'email'],['name'=>'address','label'=>'Address','type'=>'textarea'],['name'=>'tax_id','label'=>'Tax ID'],['name'=>'category','label'=>'Category'],['name'=>'notes','label'=>'Notes','type'=>'textarea']
  ]
 ],
 'contracts'=>[
  'title'=>'Service Contracts','table'=>'contracts','permission'=>'contract','soft_delete'=>true,'order'=>'id DESC','number'=>['field'=>'contract_number','type'=>'contract','prefix'=>'CTR'],
  'list'=>['contract_number'=>'Contract','customer_id'=>'Customer ID','start_date'=>'Start','end_date'=>'End','value'=>'Value','service_frequency'=>'Frequency','status'=>'Status'],
  'fields'=>[
   ['name'=>'customer_id','label'=>'Customer','type'=>'select_sql','sql'=>'SELECT id,name label FROM customers WHERE tenant_id=? AND deleted_at IS NULL ORDER BY name','required'=>true],['name'=>'start_date','label'=>'Start Date','type'=>'date','required'=>true],['name'=>'end_date','label'=>'End Date','type'=>'date','required'=>true],['name'=>'value','label'=>'Contract Value','type'=>'number','step'=>'0.01'],['name'=>'billing_frequency','label'=>'Billing Frequency','type'=>'select','options'=>['Monthly','Quarterly','Semiannual','Annual','One Time']],['name'=>'service_frequency','label'=>'Service Frequency','type'=>'select','options'=>['Weekly','Monthly','Every 3 Months','Every 6 Months','Annual']],['name'=>'sla_name','label'=>'SLA'],['name'=>'notes','label'=>'Notes','type'=>'textarea'],['name'=>'status','label'=>'Status','type'=>'select','options'=>['Draft','Active','Expired','Cancelled']]
  ]
 ],
 'maintenance'=>[
  'title'=>'Preventive Maintenance','table'=>'maintenance_schedules','permission'=>'contract','soft_delete'=>false,'order'=>'next_run_at ASC','list'=>['customer_id'=>'Customer ID','contract_id'=>'Contract ID','frequency_type'=>'Frequency','next_run_at'=>'Next Run','last_run_at'=>'Last Run','active'=>'Active'],
  'fields'=>[
   ['name'=>'contract_id','label'=>'Contract','type'=>'select_sql','sql'=>'SELECT id,contract_number label FROM contracts WHERE tenant_id=? AND deleted_at IS NULL ORDER BY id DESC'],['name'=>'customer_id','label'=>'Customer','type'=>'select_sql','sql'=>'SELECT id,name label FROM customers WHERE tenant_id=? AND deleted_at IS NULL ORDER BY name','required'=>true],['name'=>'asset_id','label'=>'Asset','type'=>'select_sql','sql'=>'SELECT id,asset_code label FROM customer_assets WHERE tenant_id=? AND deleted_at IS NULL ORDER BY asset_code'],['name'=>'frequency_type','label'=>'Frequency','type'=>'select','options'=>['Weekly','Monthly','Every 3 Months','Every 6 Months','Annual'],'required'=>true],['name'=>'next_run_at','label'=>'Next Run','type'=>'datetime-local','required'=>true],['name'=>'auto_create_job','label'=>'Auto Create Job','type'=>'select','options'=>['1'=>'Yes','0'=>'No']],['name'=>'active','label'=>'Active','type'=>'select','options'=>['1'=>'Yes','0'=>'No']]
  ]
 ],
 'warranties'=>[
  'title'=>'Warranties','table'=>'warranties','permission'=>'warranty','soft_delete'=>false,'order'=>'warranty_end ASC','list'=>['job_id'=>'Job ID','warranty_start'=>'Start','warranty_end'=>'End','status'=>'Status','coverage'=>'Coverage'],
  'fields'=>[
   ['name'=>'job_id','label'=>'Job','type'=>'select_sql','sql'=>'SELECT id,job_number label FROM jobs WHERE tenant_id=? AND deleted_at IS NULL ORDER BY id DESC','required'=>true],['name'=>'warranty_start','label'=>'Start','type'=>'date','required'=>true],['name'=>'warranty_end','label'=>'End','type'=>'date','required'=>true],['name'=>'coverage','label'=>'Coverage','type'=>'textarea'],['name'=>'terms','label'=>'Terms','type'=>'textarea'],['name'=>'status','label'=>'Status','type'=>'select','options'=>['Active','Expired','Voided']]
  ]
 ],
 'recurring-jobs'=>[
  'title'=>'Recurring Jobs','table'=>'recurring_jobs','permission'=>'contract','soft_delete'=>false,'order'=>'next_run_at ASC','list'=>['title'=>'Title','customer_id'=>'Customer ID','service_category'=>'Category','recurrence_rule'=>'Recurrence','next_run_at'=>'Next Run','active'=>'Active'],
  'fields'=>[
   ['name'=>'customer_id','label'=>'Customer','type'=>'select_sql','sql'=>'SELECT id,name label FROM customers WHERE tenant_id=? AND deleted_at IS NULL ORDER BY name','required'=>true],['name'=>'site_id','label'=>'Site','type'=>'select_sql','sql'=>'SELECT id,site_name label FROM customer_sites WHERE tenant_id=? AND deleted_at IS NULL ORDER BY site_name'],['name'=>'asset_id','label'=>'Asset','type'=>'select_sql','sql'=>'SELECT id,asset_code label FROM customer_assets WHERE tenant_id=? AND deleted_at IS NULL ORDER BY asset_code'],['name'=>'title','label'=>'Title','required'=>true],['name'=>'service_category','label'=>'Category'],['name'=>'description','label'=>'Description','type'=>'textarea'],['name'=>'recurrence_rule','label'=>'Recurrence Rule','placeholder'=>'weekly / monthly / 3 months','required'=>true],['name'=>'next_run_at','label'=>'Next Run','type'=>'datetime-local','required'=>true],['name'=>'active','label'=>'Active','type'=>'select','options'=>['1'=>'Yes','0'=>'No']]
  ]
 ],
 'branches'=>[
  'title'=>'Branches','table'=>'branches','permission'=>'settings','soft_delete'=>true,'order'=>'name ASC','list'=>['name'=>'Branch','manager_name'=>'Manager','phone'=>'Phone','email'=>'Email','timezone'=>'Timezone','status'=>'Status'],
  'fields'=>[
   ['name'=>'name','label'=>'Branch Name','required'=>true],['name'=>'address','label'=>'Address','type'=>'textarea'],['name'=>'manager_name','label'=>'Manager'],['name'=>'phone','label'=>'Phone'],['name'=>'email','label'=>'Email','type'=>'email'],['name'=>'timezone','label'=>'Timezone','placeholder'=>'Asia/Makassar'],['name'=>'status','label'=>'Status','type'=>'select','options'=>['active','inactive']]
  ]
 ],
 'sla'=>[
  'title'=>'SLA Policies','table'=>'sla_policies','permission'=>'settings','soft_delete'=>false,'order'=>'priority ASC','list'=>['name'=>'SLA','priority'=>'Priority','response_minutes'=>'Response (min)','resolution_minutes'=>'Resolution (min)','active'=>'Active'],
  'fields'=>[
   ['name'=>'name','label'=>'SLA Name','required'=>true],['name'=>'priority','label'=>'Priority','type'=>'select','options'=>['Low','Normal','High','Urgent','Emergency'],'required'=>true],['name'=>'response_minutes','label'=>'Response Minutes','type'=>'number','required'=>true],['name'=>'resolution_minutes','label'=>'Resolution Minutes','type'=>'number','required'=>true],['name'=>'active','label'=>'Active','type'=>'select','options'=>['1'=>'Yes','0'=>'No']]
  ]
 ],
];
