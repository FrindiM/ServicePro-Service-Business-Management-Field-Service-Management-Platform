<?php
namespace App\Core;
use PDO;
final class Database {
    private static ?PDO $pdo = null;
    public static function connection(): PDO {
        if (self::$pdo) return self::$pdo;
        $host = Env::get('DB_HOST','127.0.0.1');
        $port = Env::get('DB_PORT','3306');
        $name = Env::get('DB_NAME','servicepro');
        $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";
        self::$pdo = new PDO($dsn, Env::get('DB_USER','root'), Env::get('DB_PASSWORD',''), [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
        return self::$pdo;
    }
}
