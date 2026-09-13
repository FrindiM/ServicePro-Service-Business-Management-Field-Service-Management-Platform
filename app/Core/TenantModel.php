<?php
namespace App\Core;
use PDO;
abstract class TenantModel {
    protected PDO $db;
    protected string $table;
    public function __construct(){ $this->db=Database::connection(); }
    protected function tenantId(): int {
        $id = Auth::tenantId(); if (!$id) throw new \RuntimeException('Tenant context unavailable.'); return $id;
    }
    public function all(string $order='id DESC'): array {
        $stmt=$this->db->prepare("SELECT * FROM {$this->table} WHERE tenant_id=? AND deleted_at IS NULL ORDER BY {$order}"); $stmt->execute([$this->tenantId()]); return $stmt->fetchAll();
    }
    public function find(int $id): ?array {
        $stmt=$this->db->prepare("SELECT * FROM {$this->table} WHERE id=? AND tenant_id=? AND deleted_at IS NULL LIMIT 1"); $stmt->execute([$id,$this->tenantId()]); return $stmt->fetch() ?: null;
    }
}
