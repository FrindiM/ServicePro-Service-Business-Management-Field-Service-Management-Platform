<?php
namespace App\Models;
use App\Core\TenantModel;
final class Customer extends TenantModel { protected string $table='customers'; }
