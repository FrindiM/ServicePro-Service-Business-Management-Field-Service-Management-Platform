<?php
namespace App\Controllers;
use App\Core\{Database,Auth};
final class MediaController {
    public function jobPhoto(string $id): never {$this->serve('job_photos','path',(int)$id);}
    public function signature(string $id): never {$this->serve('job_signatures','signature_path',(int)$id);}
    private function serve(string $table,string $field,int $id): never {$db=Database::connection();$s=$db->prepare("SELECT {$field} path FROM {$table} WHERE id=? AND tenant_id=?");$s->execute([$id,Auth::tenantId()]);$r=$s->fetch();if(!$r){http_response_code(404);exit;}$base=realpath(BASE_PATH.'/storage/uploads/'.Auth::tenantId());$file=realpath(BASE_PATH.'/'.$r['path']);if(!$base||!$file||!str_starts_with($file,$base)||!is_file($file)){http_response_code(404);exit;}$mime=(new \finfo(FILEINFO_MIME_TYPE))->file($file);header('Content-Type: '.$mime);header('Content-Length: '.filesize($file));readfile($file);exit;}
}
