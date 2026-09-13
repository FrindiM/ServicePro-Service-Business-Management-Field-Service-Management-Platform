<?php
namespace App\Core;
final class Csrf {
    public static function token(): string {
        $token = Session::get('_csrf');
        if (!$token) { $token = bin2hex(random_bytes(32)); Session::put('_csrf',$token); }
        return $token;
    }
    public static function verify(?string $token): bool {
        $known = Session::get('_csrf');
        return is_string($known) && is_string($token) && hash_equals($known,$token);
    }
}
