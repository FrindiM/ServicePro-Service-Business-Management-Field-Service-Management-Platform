<?php
namespace App\Services;
use App\Core\Database;
final class EventService {
    public static function emit(int $tenantId,string $event,array $data=[],?int $userId=null,?string $email=null,?string $templateKey=null): void {
        $title=self::title($event,$data);$message=self::message($event,$data);
        NotificationService::internal($tenantId,$userId,$event,$title,$message,$data);
        WebhookService::queue($tenantId,$event,['event'=>$event,'occurred_at'=>date(DATE_ATOM),'data'=>$data]);
        if($email&&filter_var($email,FILTER_VALIDATE_EMAIL))self::email($tenantId,$email,$templateKey?:str_replace('.','_',$event),$data,$title,$message);
    }
    public static function email(int $tenantId,string $to,string $templateKey,array $data,string $fallbackSubject,string $fallbackBody): bool {
        $db=Database::connection();$s=$db->prepare("SELECT subject,body_html FROM email_templates WHERE tenant_id=? AND template_key=? AND active=1 LIMIT 1");$s->execute([$tenantId,$templateKey]);$tpl=$s->fetch();$subject=$tpl['subject']??$fallbackSubject;$body=$tpl['body_html']??('<p>'.htmlspecialchars($fallbackBody,ENT_QUOTES,'UTF-8').'</p>');foreach($data as $k=>$v){if(is_scalar($v)||$v===null){$subject=str_replace('{{'.$k.'}}',(string)$v,$subject);$body=str_replace('{{'.$k.'}}',htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8'),$body);}}return MailService::sendTenant($tenantId,$to,$subject,$body);
    }
    private static function title(string $event,array $d):string{return match($event){'service_request.created'=>'New service request','job.assigned'=>'Job assigned','job.scheduled'=>'Job scheduled','job.completed'=>'Job completed','quotation.sent'=>'Quotation sent','quotation.approved'=>'Quotation approved','invoice.created'=>'Invoice created','invoice.overdue'=>'Invoice overdue','payment.proof_submitted'=>'Payment proof submitted','payment.received'=>'Payment received','inventory.low_stock'=>'Low stock','contract.expiring'=>'Contract expiring','warranty.expiring'=>'Warranty expiring',default=>ucwords(str_replace(['.','_'],' ',$event))};}
    private static function message(string $event,array $d):string{$ref=$d['request_number']??$d['job_number']??$d['quotation_number']??$d['invoice_number']??$d['contract_number']??$d['asset_code']??'';return trim(self::title($event,$d).($ref?' · '.$ref:''));}
}
