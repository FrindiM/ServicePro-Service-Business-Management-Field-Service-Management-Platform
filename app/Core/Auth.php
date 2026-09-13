<?php
namespace App\Core;
final class Auth {
    public static function check(): bool { return (bool) Session::get('user'); }
    public static function user(): ?array { return Session::get('user'); }
    public static function id(): ?int { return self::user()['id'] ?? null; }
    public static function tenantId(): ?int { return self::user()['tenant_id'] ?? null; }
    public static function isPlatformAdmin(): bool { return (bool)(self::user()['is_platform_admin'] ?? false); }
    public static function permissions(): array { return self::user()['permissions'] ?? []; }
    public static function can(string $permission): bool { return self::isPlatformAdmin() || in_array('*', self::permissions(), true) || in_array($permission, self::permissions(), true); }
}
