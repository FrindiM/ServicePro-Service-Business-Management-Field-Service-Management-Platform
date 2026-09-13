<?php
namespace App\Services;
use App\Core\Database;
final class InventoryService {
    private static function lockBalance(\PDO $db,int $tenantId,int $warehouseId,int $itemId): float {
        $s=$db->prepare("SELECT quantity FROM stock_balances WHERE tenant_id=? AND warehouse_id=? AND item_id=? FOR UPDATE");$s->execute([$tenantId,$warehouseId,$itemId]);$v=$s->fetchColumn();return $v===false?0.0:(float)$v;
    }
    private static function ensureBalance(\PDO $db,int $tenantId,int $warehouseId,int $itemId): void {
        $db->prepare("INSERT IGNORE INTO stock_balances(tenant_id,warehouse_id,item_id,quantity,updated_at) VALUES(?,?,?,0,NOW())")->execute([$tenantId,$warehouseId,$itemId]);
    }
    public static function consume(int $tenantId,int $warehouseId,int $itemId,float $qty,int $jobId,?int $userId): void {
        if($qty<=0) throw new \InvalidArgumentException('Quantity must be positive.');$db=Database::connection();$db->beginTransaction();
        try{self::ensureBalance($db,$tenantId,$warehouseId,$itemId);$available=self::lockBalance($db,$tenantId,$warehouseId,$itemId);if($available<$qty)throw new \RuntimeException("Insufficient stock. Available: {$available}; Requested: {$qty}; Shortage: ".($qty-$available));
            $cost=$db->prepare("SELECT purchase_price FROM items WHERE id=? AND tenant_id=? AND deleted_at IS NULL");$cost->execute([$itemId,$tenantId]);$unitCost=(float)($cost->fetchColumn()?:0);
            $db->prepare("UPDATE stock_balances SET quantity=quantity-?,updated_at=NOW() WHERE tenant_id=? AND warehouse_id=? AND item_id=?")->execute([$qty,$tenantId,$warehouseId,$itemId]);
            $db->prepare("INSERT INTO stock_movements(tenant_id,warehouse_id,item_id,movement_type,quantity,reference_type,reference_id,created_by,created_at) VALUES(?,?,?,'usage',?,'job',?,?,NOW())")->execute([$tenantId,$warehouseId,$itemId,-$qty,$jobId,$userId]);
            $db->prepare("INSERT INTO job_materials(tenant_id,job_id,item_id,warehouse_id,technician_id,quantity,unit_cost,created_at) VALUES(?,?,?,?,?,?,?,NOW())")->execute([$tenantId,$jobId,$itemId,$warehouseId,$userId,$qty,$unitCost]);$db->commit();
        }catch(\Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
    }
    public static function adjust(int $tenantId,int $warehouseId,int $itemId,float $newQty,?int $userId,string $note='Adjustment'): void {
        if($newQty<0)throw new \InvalidArgumentException('Stock cannot be negative.');$db=Database::connection();$db->beginTransaction();try{self::ensureBalance($db,$tenantId,$warehouseId,$itemId);$old=self::lockBalance($db,$tenantId,$warehouseId,$itemId);$delta=$newQty-$old;$db->prepare("UPDATE stock_balances SET quantity=?,updated_at=NOW() WHERE tenant_id=? AND warehouse_id=? AND item_id=?")->execute([$newQty,$tenantId,$warehouseId,$itemId]);$db->prepare("INSERT INTO stock_movements(tenant_id,warehouse_id,item_id,movement_type,quantity,reference_type,reference_id,created_by,notes,created_at) VALUES(?,?,?,'adjustment',?,'adjustment',0,?,?,NOW())")->execute([$tenantId,$warehouseId,$itemId,$delta,$userId,$note]);$db->commit();}catch(\Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
    }
    public static function receive(int $tenantId,int $warehouseId,int $itemId,float $qty,float $unitCost,int $referenceId,?int $userId): void {
        if($qty<=0)throw new \InvalidArgumentException('Quantity must be positive.');$db=Database::connection();self::ensureBalance($db,$tenantId,$warehouseId,$itemId);$db->prepare("UPDATE stock_balances SET quantity=quantity+?,updated_at=NOW() WHERE tenant_id=? AND warehouse_id=? AND item_id=?")->execute([$qty,$tenantId,$warehouseId,$itemId]);$db->prepare("INSERT INTO stock_movements(tenant_id,warehouse_id,item_id,movement_type,quantity,reference_type,reference_id,created_by,created_at) VALUES(?,?,?,'receipt',?,'goods_receipt',?,?,NOW())")->execute([$tenantId,$warehouseId,$itemId,$qty,$referenceId,$userId]);if($unitCost>0)$db->prepare("UPDATE items SET purchase_price=?,updated_at=NOW() WHERE id=? AND tenant_id=?")->execute([$unitCost,$itemId,$tenantId]);
    }
    public static function transfer(int $tenantId,int $from,int $to,int $itemId,float $qty,int $transferId,?int $userId): void {
        if($from===$to)throw new \InvalidArgumentException('Warehouse asal dan tujuan harus berbeda.');if($qty<=0)throw new \InvalidArgumentException('Quantity must be positive.');$db=Database::connection();$owns=!$db->inTransaction();if($owns)$db->beginTransaction();try{self::ensureBalance($db,$tenantId,$from,$itemId);self::ensureBalance($db,$tenantId,$to,$itemId);$available=self::lockBalance($db,$tenantId,$from,$itemId);if($available<$qty)throw new \RuntimeException("Insufficient stock. Available: {$available}; Requested: {$qty}; Shortage: ".($qty-$available));self::lockBalance($db,$tenantId,$to,$itemId);$db->prepare("UPDATE stock_balances SET quantity=quantity-?,updated_at=NOW() WHERE tenant_id=? AND warehouse_id=? AND item_id=?")->execute([$qty,$tenantId,$from,$itemId]);$db->prepare("UPDATE stock_balances SET quantity=quantity+?,updated_at=NOW() WHERE tenant_id=? AND warehouse_id=? AND item_id=?")->execute([$qty,$tenantId,$to,$itemId]);foreach([[$from,-$qty,'transfer_out'],[$to,$qty,'transfer_in']] as [$w,$q,$mt])$db->prepare("INSERT INTO stock_movements(tenant_id,warehouse_id,item_id,movement_type,quantity,reference_type,reference_id,created_by,created_at) VALUES(?,?,?,?,?,'stock_transfer',?,?,NOW())")->execute([$tenantId,$w,$itemId,$mt,$q,$transferId,$userId]);if($owns)$db->commit();}catch(\Throwable $e){if($owns&&$db->inTransaction())$db->rollBack();throw $e;}
    }
}
