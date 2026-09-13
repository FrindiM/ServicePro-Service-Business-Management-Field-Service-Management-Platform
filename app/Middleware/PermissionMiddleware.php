<?php
namespace App\Middleware;
use App\Core\Auth;
final class PermissionMiddleware {
    public static string $permission='';
    public static function handle(): void { if (self::$permission && !Auth::can(self::$permission)) { http_response_code(403); require BASE_PATH.'/app/Views/errors/403.php'; exit; } }
}
