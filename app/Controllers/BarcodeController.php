<?php
namespace App\Controllers;
use App\Core\{Controller,Database,Auth};
final class BarcodeController extends Controller {
    public function item(string $id): void {if(!Auth::can('inventory.view')){http_response_code(403);exit('Forbidden');}$db=Database::connection();$s=$db->prepare("SELECT * FROM items WHERE id=? AND tenant_id=? AND deleted_at IS NULL");$s->execute([(int)$id,Auth::tenantId()]);$item=$s->fetch();if(!$item){http_response_code(404);exit('Item not found');}if(empty($item['barcode'])){$barcode='SP-'.str_pad((string)$item['id'],10,'0',STR_PAD_LEFT);$db->prepare("UPDATE items SET barcode=? WHERE id=? AND tenant_id=?")->execute([$barcode,(int)$id,Auth::tenantId()]);$item['barcode']=$barcode;}$this->view('items/barcode',['title'=>'Barcode · '.$item['sku'],'item'=>$item]);}
}
