<?php
namespace App\Services;
use App\Core\{Database,Auth};
final class ActivityService {
    public static function log(string $entityType,int $entityId,string $action,?string $description=null,array $metadata=[]): void {
        $tenant=Auth::tenantId(); if(!$tenant)return;
        $s=Database::connection()->prepare("INSERT INTO activity_logs(tenant_id,entity_type,entity_id,action,description,user_id,metadata,created_at) VALUES(?,?,?,?,?,?,?,NOW())");
        $s->execute([$tenant,$entityType,$entityId,$action,$description,Auth::id(),$metadata?json_encode($metadata,JSON_UNESCAPED_UNICODE):null]);
    }
}
