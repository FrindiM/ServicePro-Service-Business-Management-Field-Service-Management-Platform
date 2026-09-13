<?php
declare(strict_types=1);
define('BASE_PATH', dirname(__DIR__));
require BASE_PATH.'/app/Core/Env.php';
\App\Core\Env::load(BASE_PATH.'/.env');

spl_autoload_register(function(string $class){
    $prefix='App\\'; if (!str_starts_with($class,$prefix)) return;
    $file=BASE_PATH.'/app/'.str_replace('\\','/',substr($class,strlen($prefix))).'.php'; if (is_file($file)) require $file;
});

\App\Core\Session::start();
$app = require BASE_PATH.'/config/app.php';
date_default_timezone_set($app['timezone']);

// Baseline browser hardening. CSP is intentionally not forced here because tenants may
// configure external branding/CDN integrations; deployers can add a stricter CSP at the web server.
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: SAMEORIGIN');
header('Referrer-Policy: strict-origin-when-cross-origin');
header('Permissions-Policy: camera=(), microphone=(), geolocation=(self)');

function config(string $key, mixed $default=null): mixed { global $app; return $app[$key] ?? $default; }
function url(string $path=''): string { $base=rtrim((string)config('url'),'/' ); return $base.'/'.ltrim($path,'/'); }
function e(mixed $v): string { return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8'); }
function csrf_field(): string { return '<input type="hidden" name="_token" value="'.e(\App\Core\Csrf::token()).'">'; }
function money(float|int|string $value): string { return 'Rp'.number_format((float)$value,0,',','.'); }

set_exception_handler(function(Throwable $e){
    $ref='ERR-'.strtoupper(bin2hex(random_bytes(4)));
    @file_put_contents(BASE_PATH.'/storage/logs/app.log', '['.date('c')."] {$ref} {$e}\n", FILE_APPEND);
    if (config('env')==='development') { http_response_code(500); echo '<pre>'.e((string)$e).'</pre>'; return; }
    http_response_code(500); require BASE_PATH.'/app/Views/errors/500.php';
});

$router = new \App\Core\Router();
require BASE_PATH.'/routes/web.php';
$router->dispatch();
