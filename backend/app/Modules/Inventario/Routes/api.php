<?php

declare(strict_types=1);

use App\Modules\Inventario\Http\Controllers\InventarioController;
use App\Modules\Inventario\Http\Controllers\RecetaController;
use Illuminate\Support\Facades\Route;

Route::middleware(['auth:sanctum'])->group(function () {
    // Inventario general y movimientos (Kardex, existencias, alertas)
    Route::prefix('inventario')->group(function () {
        Route::get('/movimientos', [InventarioController::class, 'movimientos']);
        Route::post('/ajuste', [InventarioController::class, 'ajuste']);
        Route::get('/existencias', [InventarioController::class, 'existencias']);
        Route::get('/alertas-stock', [InventarioController::class, 'alertasStock']);
        Route::get('/reporte/pdf-token', [InventarioController::class, 'generarTokenReporte']);
    });

    // Gestión de recetas y escandallos
    Route::prefix('recetas')->group(function () {
        Route::get('/', [RecetaController::class, 'index']);
        Route::get('/{id}', [RecetaController::class, 'show']);
        Route::put('/{id}', [RecetaController::class, 'update']);
    });
});
