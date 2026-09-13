<?php
namespace App\Services;
use App\Core\{Database,Auth};
final class AuditService {
    public static function log(string $action,string $module,?int $recordId=null,mixed $old=null,mixed $new=null): void {
        $db=Database::connection();
        $stmt=$db->prepare("INSERT INTO audit_logs(tenant_id,user_id,action,module,record_id,old_value,new_value,ip_address,created_at) VALUES(?,?,?,?,?,?,?,?,NOW())");
        $stmt->execute([Auth::tenantId(),Auth::id(),$action,$module,$recordId,$old===null?null:json_encode($old,JSON_UNESCAPED_UNICODE),$new===null?null:json_encode($new,JSON_UNESCAPED_UNICODE),$_SERVER['REMOTE_ADDR']??null]);
    }
}
