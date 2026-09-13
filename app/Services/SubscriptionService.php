<?php
namespace App\Services;
use App\Core\Database;
final class SubscriptionService {
    public static function current(int $tenantId): ?array {
        $db=Database::connection();
        $s=$db->prepare("SELECT s.*,p.code plan_code,p.name plan_name,p.user_limit,p.branch_limit,p.storage_limit_mb,p.features FROM subscriptions s JOIN subscription_plans p ON p.id=s.plan_id WHERE s.tenant_id=? ORDER BY s.id DESC LIMIT 1");
        $s->execute([$tenantId]);$r=$s->fetch();if(!$r)return null;
        $r['features']=is_string($r['features'])?(json_decode($r['features'],true)?:[]):($r['features']??[]);
        return $r;
    }
    public static function usable(?array $s): bool {
        if(!$s)return false;$now=time();
        if($s['status']==='trial') return !empty($s['trial_ends_at']) && strtotime($s['trial_ends_at']) >= $now;
        if($s['status']!=='active') return false;
        return empty($s['ends_at']) || strtotime($s['ends_at']) >= $now;
    }
    public static function featureEnabled(int $tenantId,string $feature): bool {
        $db=Database::connection();$o=$db->prepare("SELECT enabled FROM tenant_feature_overrides WHERE tenant_id=? AND feature_key=? LIMIT 1");$o->execute([$tenantId,$feature]);$override=$o->fetchColumn();if($override!==false)return (bool)$override;
        $s=self::current($tenantId);if(!self::usable($s))return false;$features=$s['features']??[];
        return in_array('all',$features,true)||in_array($feature,$features,true);
    }
    public static function userLimit(int $tenantId): ?int {$s=self::current($tenantId);return isset($s['user_limit'])&&$s['user_limit']!==null?(int)$s['user_limit']:null;}
    public static function branchLimit(int $tenantId): ?int {$s=self::current($tenantId);return isset($s['branch_limit'])&&$s['branch_limit']!==null?(int)$s['branch_limit']:null;}
    public static function storageLimitMb(int $tenantId): ?int {$s=self::current($tenantId);return isset($s['storage_limit_mb'])&&$s['storage_limit_mb']!==null?(int)$s['storage_limit_mb']:null;}
    public static function storageUsageMb(int $tenantId): float {
        $path=BASE_PATH.'/storage/uploads/'.$tenantId;if(!is_dir($path))return 0.0;$bytes=0;
        $it=new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($path,\FilesystemIterator::SKIP_DOTS));foreach($it as $f)if($f->isFile())$bytes+=$f->getSize();return $bytes/1048576;
    }
    public static function wouldExceedStorage(int $tenantId,int $additionalBytes): bool {$limit=self::storageLimitMb($tenantId);if($limit===null)return false;return self::storageUsageMb($tenantId)+($additionalBytes/1048576)>$limit;}
}
