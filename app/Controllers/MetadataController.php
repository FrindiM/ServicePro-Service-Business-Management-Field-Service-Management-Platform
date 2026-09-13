<?php
namespace App\Controllers;
use App\Core\{Controller,Auth,Request,Response};
use App\Services\{MetadataService,AuditService};
final class MetadataController extends Controller {
    private array $allowed=['customer','asset','job','invoice'];
    public function get(string $entity,string $id):never{if(!in_array($entity,$this->allowed,true))Response::json(['success'=>false,'message'=>'Unsupported entity'],404);$this->guard($entity,'view');Response::json(['success'=>true,'data'=>MetadataService::get((int)Auth::tenantId(),$entity,(int)$id)]);}
    public function save(string $entity,string $id):never{$this->requireCsrf();if(!in_array($entity,$this->allowed,true))Response::json(['success'=>false,'message'=>'Unsupported entity'],404);$this->guard($entity,'edit');$values=$_POST['custom']??[];$tags=$_POST['tags']??[];MetadataService::save((int)Auth::tenantId(),$entity,(int)$id,is_array($values)?$values:[],is_array($tags)?$tags:[]);AuditService::log('edit_metadata',$entity,(int)$id,null,['custom_fields'=>array_keys((array)$values),'tags'=>$tags]);Response::json(['success'=>true,'message'=>'Custom fields and tags saved.','data'=>['reload'=>true]]);}
    private function guard(string $entity,string $action):void{$perm=match($entity){'customer'=>'customer','asset'=>'asset','job'=>'job','invoice'=>'invoice'};if(!Auth::can($perm.'.'.$action)&&!Auth::can('settings.manage'))Response::json(['success'=>false,'message'=>'Forbidden'],403);}
}
