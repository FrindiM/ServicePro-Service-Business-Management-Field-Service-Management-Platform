<?php
namespace App\Controllers;
use App\Core\{Controller,Auth,Response};
use App\Services\{ScheduledService,WebhookService};
final class MaintenanceController extends Controller {
    public function run():void{$this->requireCsrf();if(!Auth::can('contract.manage')&&!Auth::can('settings.manage'))Response::json(['success'=>false,'message'=>'Forbidden','errors'=>[]],403);$r=ScheduledService::runTenant((int)Auth::tenantId());$w=WebhookService::deliverDue((int)Auth::tenantId(),100);Response::json(['success'=>true,'message'=>'Scheduled tasks complete: '.json_encode($r).' Webhooks: '.json_encode($w),'data'=>['reload'=>true]]);}
}
