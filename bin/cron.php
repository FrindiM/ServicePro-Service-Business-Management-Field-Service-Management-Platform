<?php
declare(strict_types=1);
define('BASE_PATH',dirname(__DIR__));require BASE_PATH.'/app/Core/Env.php';\App\Core\Env::load(BASE_PATH.'/.env');spl_autoload_register(function(string $class){$p='App\\';if(!str_starts_with($class,$p))return;$f=BASE_PATH.'/app/'.str_replace('\\','/',substr($class,strlen($p))).'.php';if(is_file($f))require $f;});
$db=\App\Core\Database::connection();$tenants=$db->query("SELECT id FROM tenants WHERE status='active'")->fetchAll();foreach($tenants as $t){try{$r=\App\Services\ScheduledService::runTenant((int)$t['id']);$w=\App\Services\WebhookService::deliverDue((int)$t['id'],100);echo 'Tenant '.$t['id'].': '.json_encode($r).' webhooks='.json_encode($w).PHP_EOL;}catch(Throwable $e){echo "Tenant {$t['id']}: ERROR {$e->getMessage()}\n";}}
