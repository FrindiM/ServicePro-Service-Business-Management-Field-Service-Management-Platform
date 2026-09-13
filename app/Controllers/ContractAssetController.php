<?php
namespace App\Controllers;
use App\Core\{Controller,Database,Auth,Request,Response};
use App\Services\AuditService;

final class ContractAssetController extends Controller {
    public function index(string $id): void {
        if(!Auth::can('contract.view')&&!Auth::can('contract.manage')){$this->forbidden();return;}
        $db=Database::connection();$t=Auth::tenantId();
        $s=$db->prepare("SELECT ct.*,c.name customer_name FROM contracts ct JOIN customers c ON c.id=ct.customer_id AND c.tenant_id=ct.tenant_id WHERE ct.id=? AND ct.tenant_id=? AND ct.deleted_at IS NULL");$s->execute([(int)$id,$t]);$contract=$s->fetch();
        if(!$contract){http_response_code(404);require BASE_PATH.'/app/Views/errors/404.php';return;}
        $a=$db->prepare("SELECT id,asset_code,category,brand,model,serial_number,status FROM customer_assets WHERE tenant_id=? AND customer_id=? AND deleted_at IS NULL ORDER BY asset_code");$a->execute([$t,$contract['customer_id']]);$assets=$a->fetchAll();
        $sel=$db->prepare("SELECT asset_id FROM contract_assets WHERE tenant_id=? AND contract_id=?");$sel->execute([$t,(int)$id]);$selected=array_map('intval',$sel->fetchAll(\PDO::FETCH_COLUMN));
        $this->view('contracts/assets',['title'=>'Contract Assets','contract'=>$contract,'assets'=>$assets,'selected'=>$selected]);
    }
    public function save(string $id): void {
        $this->requireCsrf();if(!Auth::can('contract.edit')&&!Auth::can('contract.manage'))Response::json(['success'=>false,'message'=>'Forbidden','errors'=>[]],403);
        $db=Database::connection();$t=Auth::tenantId();$c=$db->prepare("SELECT id,customer_id,contract_number FROM contracts WHERE id=? AND tenant_id=? AND deleted_at IS NULL");$c->execute([(int)$id,$t]);$contract=$c->fetch();if(!$contract)Response::json(['success'=>false,'message'=>'Contract tidak ditemukan.','errors'=>[]],404);
        $assetIds=Request::input('assets',[]);if(!is_array($assetIds))$assetIds=[];$assetIds=array_values(array_unique(array_filter(array_map('intval',$assetIds))));
        if($assetIds){$ph=implode(',',array_fill(0,count($assetIds),'?'));$v=$db->prepare("SELECT id FROM customer_assets WHERE tenant_id=? AND customer_id=? AND deleted_at IS NULL AND id IN ($ph)");$v->execute(array_merge([$t,$contract['customer_id']],$assetIds));$valid=array_map('intval',$v->fetchAll(\PDO::FETCH_COLUMN));sort($valid);$check=$assetIds;sort($check);if($valid!==$check)Response::json(['success'=>false,'message'=>'Ada asset yang tidak valid atau bukan milik customer kontrak.','errors'=>[]],422);}
        $old=$db->prepare("SELECT asset_id FROM contract_assets WHERE tenant_id=? AND contract_id=?");$old->execute([$t,(int)$id]);$oldIds=array_map('intval',$old->fetchAll(\PDO::FETCH_COLUMN));
        $db->beginTransaction();try{$db->prepare("DELETE FROM contract_assets WHERE tenant_id=? AND contract_id=?")->execute([$t,(int)$id]);if($assetIds){$ins=$db->prepare("INSERT INTO contract_assets(tenant_id,contract_id,asset_id) VALUES(?,?,?)");foreach($assetIds as $aid)$ins->execute([$t,(int)$id,$aid]);}$db->commit();}catch(\Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
        AuditService::log('edit','contract_assets',(int)$id,['assets'=>$oldIds],['assets'=>$assetIds]);Response::json(['success'=>true,'message'=>'Covered assets berhasil diperbarui.','data'=>['reload'=>true]]);
    }
    private function forbidden():void{http_response_code(403);require BASE_PATH.'/app/Views/errors/403.php';}
}
