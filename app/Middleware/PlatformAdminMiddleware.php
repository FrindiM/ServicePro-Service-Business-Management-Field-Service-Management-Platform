<?php
namespace App\Middleware;
use App\Core\Auth;
final class PlatformAdminMiddleware { public static function handle(): void { if (!Auth::isPlatformAdmin()) { http_response_code(403); require BASE_PATH.'/app/Views/errors/403.php'; exit; } } }
