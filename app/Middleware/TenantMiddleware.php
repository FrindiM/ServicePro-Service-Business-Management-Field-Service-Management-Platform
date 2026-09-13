<?php
namespace App\Middleware;
use App\Core\{Auth,Database,Request,Response,Session};
use App\Services\SubscriptionService;
final class TenantMiddleware {
    public static function handle(): void {
        if(Auth::isPlatformAdmin())return;
        $tenantId=Auth::tenantId();if(!$tenantId)Response::redirect('/login');
        $db=Database::connection();$t=$db->prepare("SELECT status FROM tenants WHERE id=? LIMIT 1");$t->execute([$tenantId]);if($t->fetchColumn()!=='active'){Session::forget('user');Response::redirect('/login');}
        $sub=SubscriptionService::current($tenantId);
        if(!SubscriptionService::usable($sub)){
            if($sub && in_array($sub['status'],['trial','active'],true))$db->prepare("UPDATE subscriptions SET status='expired',updated_at=NOW() WHERE id=?")->execute([$sub['id']]);
            if(Request::wantsJson())Response::json(['success'=>false,'message'=>'Subscription is inactive or expired.','errors'=>[]],402);
            http_response_code(402);require BASE_PATH.'/app/Views/errors/subscription.php';exit;
        }
        $path=Request::path();
        $gates=[
            '/quotations'=>'quotations','/invoices'=>'invoices','/dispatch'=>'scheduling','/calendar'=>'scheduling','/purchasing'=>'inventory',
            '/portal-users'=>'customer_portal','/manage/contracts'=>'contracts','/manage/maintenance'=>'contracts','/manage/recurring-jobs'=>'contracts',
        ];
        if(str_contains($path,'/convert/quotation'))$gates[$path]='quotations';
        if(preg_match('#^/jobs/[^/]+/invoice$#',$path))$gates[$path]='invoices';
        if(in_array($path,['/inventory/adjust','/inventory/transfer'],true))$gates[$path]='inventory';
        foreach($gates as $prefix=>$feature){if(str_starts_with($path,$prefix)&&!SubscriptionService::featureEnabled($tenantId,$feature)){if(Request::wantsJson())Response::json(['success'=>false,'message'=>'Feature ini tidak tersedia pada subscription plan aktif.','errors'=>[]],403);http_response_code(403);require BASE_PATH.'/app/Views/errors/feature.php';exit;}}
    }
}
