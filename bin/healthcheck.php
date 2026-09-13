<?php
declare(strict_types=1);
if(PHP_SAPI!=='cli'){http_response_code(403);exit("CLI only\n");}
define('BASE_PATH',dirname(__DIR__));
require BASE_PATH.'/app/Core/Env.php';
\App\Core\Env::load(BASE_PATH.'/.env');
$checks=[];$ok=true;
$add=function(string $name,bool $pass,string $detail='')use(&$checks,&$ok){$checks[]=[$name,$pass,$detail];if(!$pass)$ok=false;};
$add('PHP >= 8.2',version_compare(PHP_VERSION,'8.2.0','>='),PHP_VERSION);
foreach(['pdo','pdo_mysql','fileinfo','json','openssl'] as $ext)$add('Extension '.$ext,extension_loaded($ext),extension_loaded($ext)?'loaded':'missing');
$add('mbstring recommended',extension_loaded('mbstring'),extension_loaded('mbstring')?'loaded':'missing (recommended)',);
foreach(['storage','storage/logs','storage/uploads','storage/documents','storage/cache','storage/backups'] as $dir){$path=BASE_PATH.'/'.$dir;if(!is_dir($path))@mkdir($path,0775,true);$add($dir.' writable',is_dir($path)&&is_writable($path),$path);}
$envFile=BASE_PATH.'/.env';$add('.env exists',is_file($envFile),$envFile);
$appKey=(string)\App\Core\Env::get('APP_KEY','');$add('APP_KEY configured',$appKey!==''&&!str_contains($appKey,'change-me'),$appKey!==''?'set':'missing');
$dbChecked=false;
if(extension_loaded('pdo_mysql')&&\App\Core\Env::get('DB_NAME')){
    try{require BASE_PATH.'/app/Core/Database.php';$db=\App\Core\Database::connection();$dbChecked=true;$add('Database connection',true,(string)\App\Core\Env::get('DB_NAME'));
        $required=['tenants','users','roles','permissions','customers','service_requests','jobs','items','invoices','contracts','audit_logs'];$stmt=$db->query('SHOW TABLES');$tables=$stmt->fetchAll(PDO::FETCH_COLUMN);foreach($required as $table)$add('Table '.$table,in_array($table,$tables,true),in_array($table,$tables,true)?'present':'missing');
    }catch(Throwable $e){$dbChecked=true;$add('Database connection',false,$e->getMessage());}
}
if(!$dbChecked)$checks[]=['Database connection',null,'not tested (configure .env and install pdo_mysql)'];
foreach($checks as [$name,$pass,$detail]){$tag=$pass===true?'PASS':($pass===false?'FAIL':'SKIP');echo sprintf("[%s] %-32s %s\n",$tag,$name,$detail);}
echo "\n".($ok?'Healthcheck passed.':'Healthcheck has failures.')."\n";exit($ok?0:1);
