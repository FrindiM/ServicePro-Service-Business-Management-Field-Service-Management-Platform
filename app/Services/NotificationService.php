<?php
namespace App\Services;
use App\Core\Database;
final class NotificationService {
    public static function internal(?int $tenantId,?int $userId,string $type,string $title,string $message,array $data=[]): void {
        $db=Database::connection(); $s=$db->prepare("INSERT INTO notifications(tenant_id,user_id,type,title,message,data,created_at) VALUES(?,?,?,?,?,?,NOW())");
        $s->execute([$tenantId,$userId,$type,$title,$message,$data?json_encode($data,JSON_UNESCAPED_UNICODE):null]);
    }
    public static function send(string $channel,array $payload): void {
        // Extension point: smtp, whatsapp provider, SMS, push. Provider is intentionally not hard-coded.
        if($channel==='internal'){ self::internal($payload['tenant_id']??null,$payload['user_id']??null,$payload['type']??'general',$payload['title']??'Notification',$payload['message']??'', $payload['data']??[]); return; }
        throw new \RuntimeException("Notification channel '{$channel}' has no configured provider.");
    }
}
