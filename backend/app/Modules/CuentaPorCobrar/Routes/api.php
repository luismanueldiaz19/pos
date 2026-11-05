<?php
use Illuminate\Support\Facades\Route;
use App\Modules\CuentaPorCobrar\Http\Controllers\CuentaPorCobrarController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/cxc', [CuentaPorCobrarController::class, 'index']);
    Route::get('/cxc/pagos/reporte/pdf-token', [CuentaPorCobrarController::class, 'generarTokenReporte']);
    Route::get('/cxc/pagos/historial', [CuentaPorCobrarController::class, 'historialPagos']);
    Route::post('/cxc/{id}/pagar', [CuentaPorCobrarController::class, 'registrarPago']);
});
