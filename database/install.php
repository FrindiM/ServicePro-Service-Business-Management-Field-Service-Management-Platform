<?php
declare(strict_types=1);
if(PHP_SAPI!=='cli'){http_response_code(403);exit("CLI only\n");}
define('BASE_PATH',dirname(__DIR__));
require BASE_PATH.'/app/Core/Env.php';
\App\Core\Env::load(BASE_PATH.'/.env');
require BASE_PATH.'/app/Core/Database.php';
$db=\App\Core\Database::connection();
foreach(['schema.sql','demo.sql'] as $name){$file=BASE_PATH.'/database/'.$name;if(!is_file($file))continue;echo "Running {$name}...\n";$db->exec(file_get_contents($file));}
echo "ServicePro fresh database installed.\n";
