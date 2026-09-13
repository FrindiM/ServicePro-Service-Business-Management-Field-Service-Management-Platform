<?php
namespace App\Controllers;
use App\Core\{Controller,Database,Auth,Request,Response,Session};
use App\Services\{AuditService,UploadService};
final class SettingsController extends Controller {
    public function index(): void {
        if(!Auth::can('settings.view')&&!Auth::can('settings.manage')){$this->forbidden();return;}
        $db=Database::connection();$t=(int)Auth::tenantId();$s=$db->prepare("SELECT * FROM tenants WHERE id=?");$s->execute([$t]);$tenant=$s->fetch();
        $q=$db->prepare("SELECT setting_key,setting_value FROM settings WHERE tenant_id=?");$q->execute([$t]);$settings=[];foreach($q->fetchAll() as $r)$settings[$r['setting_key']]=$r['setting_value'];
        $templates=$db->prepare("SELECT * FROM email_templates WHERE tenant_id=? ORDER BY template_key");$templates->execute([$t]);
        $this->view('settings/index',['title'=>'Business Settings','tenant'=>$tenant,'settings'=>$settings,'templates'=>$templates->fetchAll()]);
    }
    public function save(): void {
        $this->requireCsrf();if(!Auth::can('settings.edit')&&!Auth::can('settings.manage'))Response::json(['success'=>false,'message'=>'Forbidden','errors'=>[]],403);
        $db=Database::connection();$t=(int)Auth::tenantId();$old=$db->prepare("SELECT * FROM tenants WHERE id=?");$old->execute([$t]);$before=$old->fetch();
        $fields=['name','business_type','address','phone','email','website','tax_number','currency','default_tax','timezone','language','invoice_prefix','job_prefix','quotation_prefix','primary_color','invoice_footer'];$sets=[];$vals=[];foreach($fields as $f){$sets[]="{$f}=?";$vals[]=Request::input($f,$before[$f]??null);}$vals[]=$t;$db->prepare("UPDATE tenants SET ".implode(',',$sets).",updated_at=NOW() WHERE id=?")->execute($vals);
        $keys=['payment_terms','company_color','mail_host','mail_port','mail_username','mail_password','mail_encryption','mail_from_name','mail_from_email','whatsapp_provider','whatsapp_api_url','whatsapp_token','backup_enabled'];$up=$db->prepare("INSERT INTO settings(tenant_id,setting_key,setting_value,updated_at) VALUES(?,?,?,NOW()) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value),updated_at=NOW()");foreach($keys as $k)if(array_key_exists($k,$_POST))$up->execute([$t,$k,Request::input($k)]);
        AuditService::log('edit','settings',$t,$before,$_POST);$user=Session::get('user');$user['tenant_name']=Request::input('name',$user['tenant_name']);$user['tenant_color']=Request::input('primary_color','#335CFF');Session::put('user',$user);Response::json(['success'=>true,'message'=>'Business settings saved.','data'=>['reload'=>true]]);
    }
    public function branding():void{
        $this->requireCsrf();if(!Auth::can('settings.manage'))Response::json(['success'=>false,'message'=>'Forbidden'],403);$db=Database::connection();$t=(int)Auth::tenantId();$sets=[];$vals=[];
        foreach(['logo','signature','stamp'] as $field){if(isset($_FILES[$field])&&($_FILES[$field]['error']??UPLOAD_ERR_NO_FILE)===UPLOAD_ERR_OK){try{$path=UploadService::store($_FILES[$field],$t,'branding',4*1024*1024);}catch(\Throwable $e){Response::json(['success'=>false,'message'=>$e->getMessage()],422);}$sets[]="{$field}=?";$vals[]=$path;}}
        if(!$sets)Response::json(['success'=>false,'message'=>'Select at least one branding image.'],422);$vals[]=$t;$db->prepare("UPDATE tenants SET ".implode(',',$sets).",updated_at=NOW() WHERE id=?")->execute($vals);AuditService::log('branding','settings',$t,null,['fields'=>$sets]);Response::json(['success'=>true,'message'=>'Branding assets updated.','data'=>['reload'=>true]]);
    }
    private function forbidden():void{http_response_code(403);require BASE_PATH.'/app/Views/errors/403.php';}
}
