<?php
namespace App\Core;
final class Request {
    public static function method(): string { return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET'); }
    public static function path(): string {
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $script = str_replace('\\','/', dirname($_SERVER['SCRIPT_NAME'] ?? ''));
        if ($script !== '/' && $script !== '.' && str_starts_with($uri,$script)) $uri = substr($uri,strlen($script));
        return '/' . trim($uri,'/');
    }
    public static function input(string $key, mixed $default=null): mixed { return $_POST[$key] ?? $_GET[$key] ?? $default; }
    public static function all(): array { return array_merge($_GET,$_POST); }
    public static function wantsJson(): bool { return str_contains(strtolower($_SERVER['HTTP_ACCEPT'] ?? ''),'application/json') || strtolower($_SERVER['HTTP_X_REQUESTED_WITH'] ?? '') === 'xmlhttprequest'; }
}
