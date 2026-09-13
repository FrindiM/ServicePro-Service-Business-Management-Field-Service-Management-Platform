<?php
namespace App\Services;
use App\Core\Database;
final class NumberService {
    public static function next(int $tenantId,string $type,string $prefix): string {
        $db=Database::connection();$year=(int)date('Y');$owns=!$db->inTransaction();if($owns)$db->beginTransaction();
        try{$s=$db->prepare("SELECT id,current_value FROM number_sequences WHERE tenant_id=? AND type=? AND year=? FOR UPDATE");$s->execute([$tenantId,$type,$year]);$row=$s->fetch();if($row){$next=(int)$row['current_value']+1;$db->prepare("UPDATE number_sequences SET current_value=?,updated_at=NOW() WHERE id=?")->execute([$next,$row['id']]);}else{$next=1;$db->prepare("INSERT INTO number_sequences(tenant_id,type,year,current_value,created_at,updated_at) VALUES(?,?,?,?,NOW(),NOW())")->execute([$tenantId,$type,$year,$next]);}if($owns)$db->commit();return sprintf('%s-%d-%06d',$prefix,$year,$next);}catch(\Throwable $e){if($owns&&$db->inTransaction())$db->rollBack();throw $e;}
    }
}
