<?php
namespace App\Controllers;
use App\Core\{Controller,Database,Auth,Request,Response};
use App\Services\{AuditService,NumberService,SubscriptionService};

final class ModuleController extends Controller {
    private function cfg(string $module): array {
        $all=require BASE_PATH.'/config/modules.php';
        if(!isset($all[$module])) { http_response_code(404); require BASE_PATH.'/app/Views/errors/404.php'; exit; }
        return $all[$module];
    }
    private function can(array $cfg,string $action): bool {
        $code=($cfg['permission']??'settings').'.'.$action;
        return Auth::can($code) || Auth::can(($cfg['permission']??'settings').'.manage') || Auth::can('settings.manage');
    }
    public function index(string $module): void {
        $cfg=$this->cfg($module); if(!$this->can($cfg,'view')){$this->forbidden();return;}
        $db=Database::connection();$t=Auth::tenantId();$where='tenant_id=?';if(($cfg['soft_delete']??false))$where.=' AND deleted_at IS NULL';
        $stmt=$db->prepare("SELECT * FROM {$cfg['table']} WHERE {$where} ORDER BY ".($cfg['order']??'id DESC'));$stmt->execute([$t]);$rows=$stmt->fetchAll();
        $options=[];foreach($cfg['fields'] as $f){if(($f['type']??'')==='select_sql'){ $s=$db->prepare($f['sql']);$s->execute([$t]);$options[$f['name']]=$s->fetchAll(); }}
        $this->view('modules/index',['title'=>$cfg['title'],'module'=>$module,'cfg'=>$cfg,'rows'=>$rows,'options'=>$options]);
    }
    public function save(string $module): void {
        $this->requireCsrf();$cfg=$this->cfg($module);$id=(int)Request::input('id',0);$action=$id?'edit':'create';if(!$this->can($cfg,$action))Response::json(['success'=>false,'message'=>'Forbidden','errors'=>[]],403);
        $db=Database::connection();$t=Auth::tenantId();if(!$id && $module==='branches'){$limit=SubscriptionService::branchLimit($t);if($limit!==null){$c=$db->prepare("SELECT COUNT(*) FROM branches WHERE tenant_id=? AND deleted_at IS NULL");$c->execute([$t]);if((int)$c->fetchColumn()>=$limit)Response::json(['success'=>false,'message'=>'Branch limit subscription tercapai ('.$limit.').','errors'=>[]],422);}}$data=[];$errors=[];
        foreach($cfg['fields'] as $f){$name=$f['name'];$v=Request::input($name);if(is_string($v))$v=trim($v);if(($f['required']??false)&&($v===null||$v===''))$errors[$name]=$f['label'].' wajib diisi.';$data[$name]=($v==='')?null:$v;}
        if($errors)Response::json(['success'=>false,'message'=>'Periksa field yang wajib diisi.','errors'=>$errors],422);
        if(!$id && isset($cfg['number'])){$n=$cfg['number'];$data[$n['field']]=NumberService::next($t,$n['type'],$n['prefix']);}
        if($id){$s=$db->prepare("SELECT * FROM {$cfg['table']} WHERE id=? AND tenant_id=?".(($cfg['soft_delete']??false)?' AND deleted_at IS NULL':'')." LIMIT 1");$s->execute([$id,$t]);$old=$s->fetch();if(!$old)Response::json(['success'=>false,'message'=>'Data tidak ditemukan.','errors'=>[]],404);$sets=[];$vals=[];foreach($data as $k=>$v){$sets[]="{$k}=?";$vals[]=$v;}$vals[]=$id;$vals[]=$t;$db->prepare("UPDATE {$cfg['table']} SET ".implode(',',$sets).",updated_at=NOW() WHERE id=? AND tenant_id=?")->execute($vals);AuditService::log('edit',$module,$id,$old,$data);
        }else{$cols=array_keys($data);$vals=array_values($data);array_unshift($cols,'tenant_id');array_unshift($vals,$t);$ph=implode(',',array_fill(0,count($cols),'?'));$db->prepare("INSERT INTO {$cfg['table']}(".implode(',',$cols).",created_at,updated_at) VALUES({$ph},NOW(),NOW())")->execute($vals);$id=(int)$db->lastInsertId();if($module==='customer-assets'){$db->prepare("UPDATE customer_assets SET public_token=? WHERE id=? AND tenant_id=? AND public_token IS NULL")->execute([bin2hex(random_bytes(20)),$id,$t]);}AuditService::log('create',$module,$id,null,$data);}
        Response::json(['success'=>true,'message'=>$cfg['title'].' berhasil disimpan.','data'=>['reload'=>true]]);
    }
    public function delete(string $module,string $id): void {
        $this->requireCsrf();$cfg=$this->cfg($module);if(!$this->can($cfg,'delete'))Response::json(['success'=>false,'message'=>'Forbidden','errors'=>[]],403);$t=Auth::tenantId();$db=Database::connection();
        if($cfg['soft_delete']??false)$db->prepare("UPDATE {$cfg['table']} SET deleted_at=NOW() WHERE id=? AND tenant_id=?")->execute([(int)$id,$t]);else Response::json(['success'=>false,'message'=>'Data ini tidak mendukung penghapusan. Nonaktifkan melalui edit.','errors'=>[]],422);
        AuditService::log('delete',$module,(int)$id);Response::json(['success'=>true,'message'=>'Data dinonaktifkan/dihapus.','data'=>['reload'=>true]]);
    }
    private function forbidden(): void { http_response_code(403);require BASE_PATH.'/app/Views/errors/403.php'; }
}
