<?php
namespace App\Models;
use App\Core\TenantModel;
final class Invoice extends TenantModel { protected string $table='invoices'; }
