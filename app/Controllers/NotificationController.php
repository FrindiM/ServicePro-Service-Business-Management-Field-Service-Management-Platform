<?php
namespace App\Controllers;
use App\Core\{Controller,Database,Auth,Response};
final class NotificationController extends Controller {
    public function index(): void {if(!Auth::can('notification.view')&&!Auth::check()){$this->forbidden();return;}$db=Database::connection();$s=$db->prepare("SELECT * FROM notifications WHERE tenant_id=? AND (user_id IS NULL OR user_id=?) ORDER BY id DESC LIMIT 200");$s->execute([Auth::tenantId(),Auth::id()]);$this->view('notifications/index',['title'=>'Notifications','notifications'=>$s->fetchAll()]);}
    public function read(string $id): void {$this->requireCsrf();$db=Database::connection();$db->prepare("UPDATE notifications SET read_at=NOW() WHERE id=? AND tenant_id=? AND (user_id IS NULL OR user_id=?)")->execute([(int)$id,Auth::tenantId(),Auth::id()]);Response::json(['success'=>true,'message'=>'Notification marked read.','data'=>['reload'=>true]]);}
    private function forbidden():void{http_response_code(403);require BASE_PATH.'/app/Views/errors/403.php';}
}
