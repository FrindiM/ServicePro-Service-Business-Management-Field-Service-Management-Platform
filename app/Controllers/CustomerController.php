<?php
namespace App\Controllers;
use App\Core\{Controller,Database,Auth,Request,Response}; use App\Models\Customer; use App\Services\{AuditService,NumberService};
final class CustomerController extends Controller {
    public function index(): void { if(!Auth::can('customer.view')){http_response_code(403);require BASE_PATH.'/app/Views/errors/403.php';return;} $this->view('customers/index',['title'=>'Customers','customers'=>(new Customer())->all('name ASC')]); }

    public function show(string $id): void {
        if(!Auth::can('customer.view')){http_response_code(403);require BASE_PATH.'/app/Views/errors/403.php';return;}
        $db=Database::connection();$t=Auth::tenantId();$q=$db->prepare("SELECT * FROM customers WHERE id=? AND tenant_id=? AND deleted_at IS NULL");$q->execute([(int)$id,$t]);$customer=$q->fetch();if(!$customer){http_response_code(404);require BASE_PATH.'/app/Views/errors/404.php';return;}
        $fetch=function(string $sql,array $args)use($db){$s=$db->prepare($sql);$s->execute($args);return $s->fetchAll();};
        $contacts=$fetch("SELECT * FROM customer_contacts WHERE tenant_id=? AND customer_id=? AND deleted_at IS NULL ORDER BY is_primary DESC,name",[$t,(int)$id]);
        $sites=$fetch("SELECT * FROM customer_sites WHERE tenant_id=? AND customer_id=? AND deleted_at IS NULL ORDER BY site_name",[$t,(int)$id]);
        $assets=$fetch("SELECT * FROM customer_assets WHERE tenant_id=? AND customer_id=? AND deleted_at IS NULL ORDER BY id DESC",[$t,(int)$id]);
        $jobs=$fetch("SELECT id,job_number,description,status,scheduled_date FROM jobs WHERE tenant_id=? AND customer_id=? AND deleted_at IS NULL ORDER BY id DESC LIMIT 25",[$t,(int)$id]);
        $invoices=$fetch("SELECT id,invoice_number,total,balance,status,due_date FROM invoices WHERE tenant_id=? AND customer_id=? AND deleted_at IS NULL ORDER BY id DESC LIMIT 25",[$t,(int)$id]);
        $this->view('customers/show',['title'=>$customer['name'],'customer'=>$customer,'contacts'=>$contacts,'sites'=>$sites,'assets'=>$assets,'jobs'=>$jobs,'invoices'=>$invoices]);
    }
    public function contact(string $id): void {
        $this->requireCsrf();if(!Auth::can('customer.edit')&&!Auth::can('customer.create'))Response::json(['success'=>false,'message'=>'Forbidden','errors'=>[]],403);$name=trim((string)Request::input('name'));if($name==='')Response::json(['success'=>false,'message'=>'Contact name wajib diisi.','errors'=>[]],422);$db=Database::connection();$check=$db->prepare("SELECT id FROM customers WHERE id=? AND tenant_id=? AND deleted_at IS NULL");$check->execute([(int)$id,Auth::tenantId()]);if(!$check->fetchColumn())Response::json(['success'=>false,'message'=>'Customer tidak ditemukan.','errors'=>[]],404);$primary=(int)(bool)Request::input('is_primary');if($primary)$db->prepare("UPDATE customer_contacts SET is_primary=0 WHERE tenant_id=? AND customer_id=?")->execute([Auth::tenantId(),(int)$id]);$db->prepare("INSERT INTO customer_contacts(tenant_id,customer_id,name,position,phone,whatsapp,email,is_primary,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,NOW(),NOW())")->execute([Auth::tenantId(),(int)$id,$name,Request::input('position'),Request::input('phone'),Request::input('whatsapp'),Request::input('email'),$primary]);AuditService::log('create','customer_contact',(int)$db->lastInsertId(),null,['customer_id'=>(int)$id,'name'=>$name]);Response::json(['success'=>true,'message'=>'Customer contact ditambahkan.','data'=>['reload'=>true]]);
    }
    public function store(): void {
        $this->requireCsrf(); if(!Auth::can('customer.create')) Response::json(['success'=>false,'message'=>'Forbidden','errors'=>[]],403); $name=trim((string)Request::input('name')); if($name===''){Response::json(['success'=>false,'message'=>'Customer name wajib diisi.','errors'=>['name'=>'Required']],422);}
        $db=Database::connection(); $code=NumberService::next((int)Auth::tenantId(),'customer','CUS');
        $s=$db->prepare("INSERT INTO customers(tenant_id,customer_code,customer_type,name,company,phone,whatsapp,email,billing_address,service_address,status,created_by,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,NOW(),NOW())");
        $s->execute([Auth::tenantId(),$code,Request::input('customer_type','Company'),$name,Request::input('company'),Request::input('phone'),Request::input('whatsapp'),Request::input('email'),Request::input('billing_address'),Request::input('service_address'),'active',Auth::id()]);
        AuditService::log('create','customer',(int)$db->lastInsertId(),null,['name'=>$name]);
        Response::json(['success'=>true,'message'=>'Customer berhasil dibuat.','data'=>['reload'=>true]]);
    }
}
