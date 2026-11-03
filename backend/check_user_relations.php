<?php
require 'backend/vendor/autoload.php';
$app = require_once 'backend/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\DB;

foreach ([2, 3] as $uid) {
    $u = User::find($uid);
    if (!$u) continue;
    echo "=== USER $uid ({$u->name}) ===\n";

    // Check tables referencing user_id
    $tables = ['facturas', 'caja_sesions', 'compras', 'pagos', 'cotizaciones', 'pedidos', 'mesas'];
    foreach ($tables as $t) {
        try {
            $cnt = DB::table($t)->where('user_id', $uid)->count();
            if ($cnt > 0) echo "  $t: $cnt records\n";
        } catch (\Exception $e) {}
    }

    // Try deleting inside transaction
    DB::beginTransaction();
    try {
        $u->delete();
        echo "  [SUCCESS] Would delete successfully\n";
    } catch (\Exception $e) {
        echo "  [FAILED] " . $e->getMessage() . "\n";
    }
    DB::rollBack();
}

