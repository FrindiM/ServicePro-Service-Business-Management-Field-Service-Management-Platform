<?php
namespace App\Controllers;
use App\Core\{Controller,Database,Session,Response,Request};
final class AuthController extends Controller {
    public function showLogin(): void {
        if (Session::get('user')) Response::redirect((Session::get('user')['is_platform_admin']??false)?'/platform':'/dashboard');
        $this->view('auth/login',['title'=>'Sign in']);
    }
    public function login(): void {
        $this->requireCsrf();
        $email=strtolower(trim((string)Request::input('email'))); $password=(string)Request::input('password');
        $db=Database::connection();
        $limit=$db->prepare("SELECT COUNT(*) FROM login_attempts WHERE email=? AND succeeded=0 AND created_at>=DATE_SUB(NOW(),INTERVAL 15 MINUTE)");
        $limit->execute([$email]);
        if ((int)$limit->fetchColumn() >= 8) { Session::flash('error','Terlalu banyak percobaan login. Coba lagi beberapa menit lagi.'); Response::redirect('/login'); }
        $stmt=$db->prepare("SELECT u.*, t.name tenant_name, t.status tenant_status, t.primary_color tenant_color FROM users u LEFT JOIN tenants t ON t.id=u.tenant_id WHERE u.email=? AND u.status='active' AND u.deleted_at IS NULL LIMIT 1");
        $stmt->execute([$email]); $user=$stmt->fetch();
        if (!$user || !password_verify($password,$user['password_hash'])) {
            $db->prepare("INSERT INTO login_attempts(email,ip_address,succeeded,created_at) VALUES(?,?,0,NOW())")->execute([$email,$_SERVER['REMOTE_ADDR']??null]);
            Session::flash('error','Email atau password salah.'); Response::redirect('/login');
        }
        if (!$user['is_platform_admin'] && ($user['tenant_status'] ?? null) !== 'active') {
            Session::flash('error','Akun perusahaan sedang tidak aktif.'); Response::redirect('/login');
        }
        $permissions=[];
        if ($user['is_platform_admin']) $permissions=['*']; else {
            $p=$db->prepare("SELECT DISTINCT p.code FROM user_roles ur JOIN role_permissions rp ON rp.role_id=ur.role_id JOIN permissions p ON p.id=rp.permission_id WHERE ur.user_id=? AND ur.tenant_id=?");
            $p->execute([$user['id'],$user['tenant_id']]); $permissions=array_column($p->fetchAll(),'code');
        }
        Session::regenerate();
        Session::put('user',[
            'id'=>(int)$user['id'],'tenant_id'=>$user['tenant_id']?(int)$user['tenant_id']:null,'name'=>$user['name'],'email'=>$user['email'],
            'is_platform_admin'=>(bool)$user['is_platform_admin'],'tenant_name'=>$user['tenant_name']??'Platform','permissions'=>$permissions,'photo'=>$user['photo']??null,'language'=>$user['language']??'id','theme'=>$user['theme']??'system','tenant_color'=>$user['tenant_color']??'#335CFF'
        ]);
        $sessionHash=hash('sha256',session_id());Session::put('session_ref',$sessionHash);$db->prepare("INSERT INTO user_sessions(user_id,session_hash,ip_address,user_agent,last_seen_at,created_at) VALUES(?,?,?,?,NOW(),NOW())")->execute([$user['id'],$sessionHash,$_SERVER['REMOTE_ADDR']??null,substr((string)($_SERVER['HTTP_USER_AGENT']??''),0,500)]);$db->prepare("UPDATE users SET last_login_at=NOW() WHERE id=?")->execute([$user['id']]);
        $db->prepare("INSERT INTO login_attempts(email,ip_address,succeeded,created_at) VALUES(?,?,1,NOW())")->execute([$email,$_SERVER['REMOTE_ADDR']??null]);
        Response::redirect($user['is_platform_admin']?'/platform':'/dashboard');
    }
    public function logout(): void {
        $this->requireCsrf(); $ref=Session::get('session_ref');if($ref&&Session::get('user'))Database::connection()->prepare("UPDATE user_sessions SET revoked_at=NOW() WHERE user_id=? AND session_hash=? AND revoked_at IS NULL")->execute([Session::get('user')['id'],$ref]); $_SESSION=[]; if (ini_get('session.use_cookies')) { $p=session_get_cookie_params(); setcookie(session_name(),'',time()-42000,$p['path'],$p['domain']??'',(bool)$p['secure'],(bool)$p['httponly']); }
        session_destroy(); Response::redirect('/login');
    }
}
