<?php
namespace App\Services;
use App\Core\Database;
final class WebhookService {
    public static function queue(int $tenantId,string $event,array $payload): int {
        $db=Database::connection();
        $s=$db->prepare("SELECT id,events FROM webhooks WHERE tenant_id=? AND active=1");$s->execute([$tenantId]);$count=0;
        $ins=$db->prepare("INSERT INTO webhook_deliveries(tenant_id,webhook_id,event_name,payload,attempts,next_attempt_at,created_at) VALUES(?,?,?,?,0,NOW(),NOW())");
        foreach($s->fetchAll() as $w){$events=json_decode((string)$w['events'],true)?:[];if(!in_array('*',$events,true)&&!in_array($event,$events,true))continue;$ins->execute([$tenantId,$w['id'],$event,json_encode($payload,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);$count++;}
        return $count;
    }
    public static function deliverDue(?int $tenantId=null,int $limit=50): array {
        $db=Database::connection();$where=$tenantId?' AND d.tenant_id=?':'';$sql="SELECT d.*,w.endpoint_url,w.secret FROM webhook_deliveries d JOIN webhooks w ON w.id=d.webhook_id AND w.tenant_id=d.tenant_id WHERE d.delivered_at IS NULL AND w.active=1 AND (d.next_attempt_at IS NULL OR d.next_attempt_at<=NOW()) {$where} ORDER BY d.id ASC LIMIT ".max(1,min(200,$limit));$s=$db->prepare($sql);$s->execute($tenantId?[$tenantId]:[]);$ok=0;$failed=0;
        foreach($s->fetchAll() as $d){$payload=(string)$d['payload'];$sig=hash_hmac('sha256',$payload,(string)$d['secret']);[$code,$body,$error]=self::post((string)$d['endpoint_url'],$payload,['Content-Type: application/json','User-Agent: ServicePro-Webhook/1.0','X-ServicePro-Event: '.$d['event_name'],'X-ServicePro-Signature: sha256='.$sig]);$attempt=(int)$d['attempts']+1;if($code>=200&&$code<300){$db->prepare("UPDATE webhook_deliveries SET attempts=?,response_code=?,response_body=?,delivered_at=NOW(),next_attempt_at=NULL WHERE id=?")->execute([$attempt,$code,mb_substr($body,0,5000),$d['id']]);$ok++;}else{$minutes=min(1440,(int)pow(2,min($attempt,10)));$msg=$error?:$body;$db->prepare("UPDATE webhook_deliveries SET attempts=?,response_code=?,response_body=?,next_attempt_at=DATE_ADD(NOW(),INTERVAL ? MINUTE) WHERE id=?")->execute([$attempt,$code?:null,mb_substr((string)$msg,0,5000),$minutes,$d['id']]);$failed++;}}
        return ['delivered'=>$ok,'failed'=>$failed];
    }
    private static function post(string $url,string $payload,array $headers): array {
        if(function_exists('curl_init')){$ch=curl_init($url);curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>$payload,CURLOPT_HTTPHEADER=>$headers,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>12,CURLOPT_CONNECTTIMEOUT=>5,CURLOPT_FOLLOWLOCATION=>false]);$body=(string)curl_exec($ch);$err=curl_error($ch);$code=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);curl_close($ch);return[$code,$body,$err];}
        $ctx=stream_context_create(['http'=>['method'=>'POST','header'=>implode("\r\n",$headers), 'content'=>$payload,'timeout'=>12,'ignore_errors'=>true]]);$body=@file_get_contents($url,false,$ctx);$code=0;if(isset($http_response_header[0])&&preg_match('/\s(\d{3})\s/',$http_response_header[0],$m))$code=(int)$m[1];return[$code,(string)$body,$body===false?'HTTP request failed':''];
    }
}
