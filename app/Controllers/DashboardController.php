<?php
namespace App\Controllers;
use App\Core\{Controller,Database,Auth};
final class DashboardController extends Controller {
    public function index(): void {
        $db=Database::connection();$t=Auth::tenantId();$uid=Auth::id();
        $role=$db->prepare("SELECT GROUP_CONCAT(r.code) FROM user_roles ur JOIN roles r ON r.id=ur.role_id WHERE ur.tenant_id=? AND ur.user_id=?");$role->execute([$t,$uid]);$roles=explode(',',(string)$role->fetchColumn());
        if(in_array('technician',$roles,true)){$this->technician($db,$t,$uid);return;}
        $scalar=function(string $sql,array $args=[]) use($db){$s=$db->prepare($sql);$s->execute($args);return $s->fetchColumn();};
        $kpi=[
          'requests_today'=>(int)$scalar("SELECT COUNT(*) FROM service_requests WHERE tenant_id=? AND DATE(created_at)=CURDATE() AND deleted_at IS NULL",[$t]),
          'open_jobs'=>(int)$scalar("SELECT COUNT(*) FROM jobs WHERE tenant_id=? AND status NOT IN('Closed','Cancelled','Completed') AND deleted_at IS NULL",[$t]),
          'in_progress'=>(int)$scalar("SELECT COUNT(*) FROM jobs WHERE tenant_id=? AND status='In Progress' AND deleted_at IS NULL",[$t]),
          'completed'=>(int)$scalar("SELECT COUNT(*) FROM jobs WHERE tenant_id=? AND status IN('Completed','Closed') AND MONTH(updated_at)=MONTH(CURDATE()) AND YEAR(updated_at)=YEAR(CURDATE()) AND deleted_at IS NULL",[$t]),
          'overdue'=>(int)$scalar("SELECT COUNT(*) FROM jobs WHERE tenant_id=? AND scheduled_date<NOW() AND status NOT IN('Completed','Closed','Cancelled') AND deleted_at IS NULL",[$t]),
          'sla_breached'=>(int)$scalar("SELECT COUNT(*) FROM service_requests WHERE tenant_id=? AND resolution_deadline<NOW() AND status NOT IN('Completed','Closed','Cancelled') AND deleted_at IS NULL",[$t]),
          'active_tech'=>(int)$scalar("SELECT COUNT(*) FROM technicians WHERE tenant_id=? AND status NOT IN('Leave','Offline')",[$t]),
          'pending_quotes'=>(int)$scalar("SELECT COUNT(*) FROM quotations WHERE tenant_id=? AND status IN('Draft','Internal Review','Sent','Viewed') AND deleted_at IS NULL",[$t]),
          'approved_quotes'=>(int)$scalar("SELECT COUNT(*) FROM quotations WHERE tenant_id=? AND status='Approved' AND MONTH(updated_at)=MONTH(CURDATE()) AND YEAR(updated_at)=YEAR(CURDATE()) AND deleted_at IS NULL",[$t]),
          'low_stock'=>(int)$scalar("SELECT COUNT(*) FROM items i WHERE i.tenant_id=? AND i.deleted_at IS NULL AND COALESCE((SELECT SUM(sb.quantity) FROM stock_balances sb WHERE sb.tenant_id=i.tenant_id AND sb.item_id=i.id),0)<=i.minimum_stock",[$t]),
          'outstanding'=>(float)$scalar("SELECT COALESCE(SUM(balance),0) FROM invoices WHERE tenant_id=? AND status IN('Sent','Partial','Overdue') AND deleted_at IS NULL",[$t]),
          'revenue'=>(float)$scalar("SELECT COALESCE(SUM(total),0) FROM invoices WHERE tenant_id=? AND MONTH(invoice_date)=MONTH(CURDATE()) AND YEAR(invoice_date)=YEAR(CURDATE()) AND status<>'Cancelled' AND deleted_at IS NULL",[$t]),
          'expenses'=>(float)$scalar("SELECT COALESCE(SUM(amount),0) FROM job_expenses WHERE tenant_id=? AND MONTH(expense_date)=MONTH(CURDATE()) AND YEAR(expense_date)=YEAR(CURDATE())",[$t]),
          'material_cost'=>(float)$scalar("SELECT COALESCE(SUM(quantity*unit_cost),0) FROM job_materials WHERE tenant_id=? AND MONTH(created_at)=MONTH(CURDATE()) AND YEAR(created_at)=YEAR(CURDATE())",[$t]),
        ];$kpi['gross_profit']=$kpi['revenue']-$kpi['expenses']-$kpi['material_cost'];
        $jobs=$this->fetch($db,"SELECT j.id,j.job_number,j.status,j.priority,j.scheduled_date,j.service_category,c.name customer_name,GROUP_CONCAT(u.name SEPARATOR ', ') technicians FROM jobs j JOIN customers c ON c.id=j.customer_id AND c.tenant_id=j.tenant_id LEFT JOIN job_technicians jt ON jt.job_id=j.id AND jt.tenant_id=j.tenant_id LEFT JOIN users u ON u.id=jt.user_id WHERE j.tenant_id=? AND j.deleted_at IS NULL AND j.status NOT IN('Closed','Cancelled') GROUP BY j.id ORDER BY j.scheduled_date IS NULL,j.scheduled_date ASC LIMIT 10",[$t]);
        $lowStock=$this->fetch($db,"SELECT i.item_name,i.unit,i.minimum_stock,COALESCE(SUM(sb.quantity),0) stock FROM items i LEFT JOIN stock_balances sb ON sb.item_id=i.id AND sb.tenant_id=i.tenant_id WHERE i.tenant_id=? AND i.deleted_at IS NULL GROUP BY i.id HAVING stock<=i.minimum_stock ORDER BY stock ASC LIMIT 6",[$t]);
        $expiring=$this->fetch($db,"SELECT 'Contract' kind,contract_number reference,end_date expiry FROM contracts WHERE tenant_id=? AND status='Active' AND end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(),INTERVAL 30 DAY) AND deleted_at IS NULL UNION ALL SELECT 'Warranty',CONCAT('Warranty #',id),warranty_end FROM warranties WHERE tenant_id=? AND status='Active' AND warranty_end BETWEEN CURDATE() AND DATE_ADD(CURDATE(),INTERVAL 30 DAY) ORDER BY expiry LIMIT 8",[$t,$t]);
        $monthly=$this->fetch($db,"SELECT DATE_FORMAT(d.month,'%Y-%m') label,COALESCE(SUM(i.total),0) value FROM (SELECT DATE_FORMAT(DATE_SUB(CURDATE(),INTERVAL n MONTH),'%Y-%m-01') month FROM (SELECT 0 n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) x) d LEFT JOIN invoices i ON i.tenant_id=? AND DATE_FORMAT(i.invoice_date,'%Y-%m')=DATE_FORMAT(d.month,'%Y-%m') AND i.status<>'Cancelled' AND i.deleted_at IS NULL GROUP BY d.month ORDER BY d.month",[$t]);
        $statuses=$this->fetch($db,"SELECT status label,COUNT(*) value FROM jobs WHERE tenant_id=? AND deleted_at IS NULL GROUP BY status ORDER BY value DESC",[$t]);
        $this->view('dashboard/index',['title'=>'Dashboard','mode'=>'management','kpi'=>$kpi,'jobs'=>$jobs,'lowStock'=>$lowStock,'expiring'=>$expiring,'monthly'=>$monthly,'statuses'=>$statuses]);
    }
    private function technician(\PDO $db,int $t,int $uid):void{
        $jobs=$this->fetch($db,"SELECT j.id,j.job_number,j.status,j.priority,j.scheduled_date,j.description,c.name customer_name,cs.site_name,cs.address FROM job_technicians jt JOIN jobs j ON j.id=jt.job_id AND j.tenant_id=jt.tenant_id JOIN customers c ON c.id=j.customer_id AND c.tenant_id=j.tenant_id LEFT JOIN customer_sites cs ON cs.id=j.site_id AND cs.tenant_id=j.tenant_id WHERE jt.tenant_id=? AND jt.user_id=? AND j.deleted_at IS NULL AND j.status NOT IN('Closed','Cancelled') ORDER BY j.scheduled_date IS NULL,j.scheduled_date LIMIT 20",[$t,$uid]);
        $done=$this->fetch($db,"SELECT COUNT(*) value FROM job_technicians jt JOIN jobs j ON j.id=jt.job_id AND j.tenant_id=jt.tenant_id WHERE jt.tenant_id=? AND jt.user_id=? AND j.status IN('Completed','Closed') AND MONTH(j.updated_at)=MONTH(CURDATE()) AND YEAR(j.updated_at)=YEAR(CURDATE())",[$t,$uid]);
        $this->view('dashboard/index',['title'=>'My Field Dashboard','mode'=>'technician','jobs'=>$jobs,'completedMonth'=>(int)($done[0]['value']??0)]);
    }
    private function fetch(\PDO $db,string $sql,array $args):array{$s=$db->prepare($sql);$s->execute($args);return $s->fetchAll();}
}
