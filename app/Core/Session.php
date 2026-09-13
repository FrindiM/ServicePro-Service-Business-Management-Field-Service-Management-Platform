<?php
namespace App\Core;
final class Session {
    public static function start(): void {
        if (session_status() === PHP_SESSION_ACTIVE) return;
        session_name('servicepro_session');
        session_set_cookie_params([
            'httponly' => true,
            'secure' => filter_var(Env::get('SESSION_SECURE','false'), FILTER_VALIDATE_BOOL),
            'samesite' => 'Lax',
            'path' => '/',
        ]);
        session_start();
    }
    public static function get(string $key, mixed $default=null): mixed { return $_SESSION[$key] ?? $default; }
    public static function put(string $key, mixed $value): void { $_SESSION[$key] = $value; }
    public static function forget(string $key): void { unset($_SESSION[$key]); }
    public static function regenerate(): void { session_regenerate_id(true); }
    public static function flash(string $key, mixed $value): void { $_SESSION['_flash'][$key] = $value; }
    public static function consume(string $key, mixed $default=null): mixed {
        $v = $_SESSION['_flash'][$key] ?? $default; unset($_SESSION['_flash'][$key]); return $v;
    }
}
