<?php
namespace App\Middleware;
use App\Core\{Auth,Database,Response,Session};
final class AuthMiddleware {
    public static function handle(): void {
        if(!Auth::check())Response::redirect('/login');
        $ref=Session::get('session_ref');
        if($ref){$db=Database::connection();$s=$db->prepare("SELECT id FROM user_sessions WHERE user_id=? AND session_hash=? AND revoked_at IS NULL LIMIT 1");$s->execute([Auth::id(),$ref]);$sid=$s->fetchColumn();if(!$sid){Session::forget('user');Session::forget('session_ref');Response::redirect('/login');}$db->prepare("UPDATE user_sessions SET last_seen_at=NOW() WHERE id=? AND last_seen_at<DATE_SUB(NOW(),INTERVAL 2 MINUTE)")->execute([$sid]);}
    }
}
