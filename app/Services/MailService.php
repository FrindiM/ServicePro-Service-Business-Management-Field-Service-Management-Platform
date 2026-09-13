<?php
namespace App\Services;
use App\Core\Database;
final class MailService {
    public static function sendTenant(?int $tenantId,string $to,string $subject,string $html): bool {
        $cfg=self::settings($tenantId);
        if(!empty($cfg['mail_host'])) return self::smtp($cfg,$to,$subject,$html);
        $from=$cfg['mail_from_email']??getenv('MAIL_FROM_ADDRESS')?:'noreply@localhost';$name=$cfg['mail_from_name']??'ServicePro';
        $headers="MIME-Version: 1.0\r\nContent-Type: text/html; charset=UTF-8\r\nFrom: ".self::header($name)." <{$from}>\r\n";
        return @mail($to,$subject,$html,$headers);
    }
    private static function settings(?int $tenantId):array {
        $out=[];if($tenantId){$s=Database::connection()->prepare("SELECT setting_key,setting_value FROM settings WHERE tenant_id=? AND setting_key LIKE 'mail_%'");$s->execute([$tenantId]);foreach($s->fetchAll() as $r)$out[$r['setting_key']]=$r['setting_value'];}
        $env=['mail_host'=>'MAIL_HOST','mail_port'=>'MAIL_PORT','mail_username'=>'MAIL_USERNAME','mail_password'=>'MAIL_PASSWORD','mail_encryption'=>'MAIL_ENCRYPTION','mail_from_email'=>'MAIL_FROM_ADDRESS','mail_from_name'=>'MAIL_FROM_NAME'];foreach($env as $k=>$e)if(empty($out[$k])&&getenv($e)!==false)$out[$k]=getenv($e);return $out;
    }
    private static function smtp(array $c,string $to,string $subject,string $html):bool {
        $host=(string)$c['mail_host'];$port=(int)($c['mail_port']??587);$enc=strtolower((string)($c['mail_encryption']??'tls'));$target=($enc==='ssl'?'ssl://':'').$host;
        $fp=@fsockopen($target,$port,$errno,$errstr,12);if(!$fp)return false;stream_set_timeout($fp,12);
        try{self::expect($fp,[220]);self::cmd($fp,'EHLO servicepro.local',[250]);if($enc==='tls'){self::cmd($fp,'STARTTLS',[220]);if(!stream_socket_enable_crypto($fp,true,STREAM_CRYPTO_METHOD_TLS_CLIENT))throw new \RuntimeException('TLS failed');self::cmd($fp,'EHLO servicepro.local',[250]);}
            if(!empty($c['mail_username'])){self::cmd($fp,'AUTH LOGIN',[334]);self::cmd($fp,base64_encode((string)$c['mail_username']),[334]);self::cmd($fp,base64_encode((string)($c['mail_password']??'')),[235]);}
            $from=(string)($c['mail_from_email']??$c['mail_username']??'noreply@localhost');$name=(string)($c['mail_from_name']??'ServicePro');self::cmd($fp,'MAIL FROM:<'.$from.'>',[250]);self::cmd($fp,'RCPT TO:<'.$to.'>',[250,251]);self::cmd($fp,'DATA',[354]);
            $msg="From: ".self::header($name)." <{$from}>\r\nTo: <{$to}>\r\nSubject: ".self::header($subject)."\r\nMIME-Version: 1.0\r\nContent-Type: text/html; charset=UTF-8\r\nDate: ".date(DATE_RFC2822)."\r\n\r\n".$html; $msg=preg_replace('/(?m)^\./','..',$msg);fwrite($fp,$msg."\r\n.\r\n");self::expect($fp,[250]);self::cmd($fp,'QUIT',[221]);fclose($fp);return true;
        }catch(\Throwable){@fclose($fp);return false;}
    }
    private static function cmd($fp,string $cmd,array $codes):void{fwrite($fp,$cmd."\r\n");self::expect($fp,$codes);}
    private static function expect($fp,array $codes):void{$last='';do{$line=fgets($fp,515);if($line===false)throw new \RuntimeException('SMTP connection closed');$last=$line;}while(strlen($line)>=4&&$line[3]==='-');$code=(int)substr($last,0,3);if(!in_array($code,$codes,true))throw new \RuntimeException('SMTP error '.$code);}
    private static function header(string $v):string{return '=?UTF-8?B?'.base64_encode($v).'?=';}
}
