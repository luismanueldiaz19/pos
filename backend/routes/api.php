<?php

use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\Facturacion\ClienteController;
use App\Http\Controllers\Api\Facturacion\FacturaController;
use App\Http\Controllers\Api\Facturacion\NcfSecuenciaController;
use App\Modules\Caja\Http\Controllers\CajaController;
use App\Http\Controllers\Api\Inventario\ProductoController;
use App\Http\Controllers\Api\Compras\OrdenCompraController;
use App\Http\Controllers\Api\RRHH\NominaController;
use App\Http\Controllers\Api\RRHH\EmpleadoController;
use App\Http\Controllers\Api\Compras\ProveedorController;
use App\Http\Controllers\Api\Finanzas\CxpController;
use App\Http\Controllers\Api\Finanzas\CxcController;
use App\Http\Controllers\Api\Impuestos\DgiiController;
use App\Modules\Inventario\Http\Controllers\InventarioController;
use App\Modules\Inventario\Http\Controllers\RecetaController;
use App\Http\Controllers\Api\Facturacion\NotaCreditoController;
// use App\Http\Controllers\Api\Restaurante\PedidoController; // Migrado a V2
use App\Http\Controllers\Api\Inventario\CategoriaController;
use App\Http\Controllers\Api\Inventario\MarcaController;
use App\Http\Controllers\Api\Inventario\UnidadMedidaController;
use App\Http\Controllers\Api\Impuestos\ImpuestoController;
use App\Http\Controllers\Api\Finanzas\BankController;
use App\Http\Controllers\Api\Finanzas\BankAccountController;
use App\Http\Controllers\Api\Finanzas\BankTransactionController;
use App\Http\Controllers\Api\AiAgentController;
use Illuminate\Support\Facades\Route;

// públicas
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/documentos/ver/{token}', [\App\Http\Controllers\Api\DocumentoVisorController::class, 'ver'])->name('documentos.ver');
Route::get('/notas-credito/{id}/pdf', [NotaCreditoController::class, 'pdf'])->name('notas-credito.pdf');

Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);

// Webhook para Chatbot (Sin Auth de usuario)
Route::post('/pedidos/bot', [\App\Modules\Pedido\Http\Controllers\PedidoController::class, 'storeWebhook']);
Route::get('/pedidos/bot/productos', [ProductoController::class, 'index']);

Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::get('/admin', function () {
        return 'Solo admin';
    });
});

Route::middleware(['auth:sanctum'])->group(function () {

    // ================= AI AGENT =================
    Route::post('/ai/chat', [AiAgentController::class, 'chat']);

    // Compras Module
    Route::apiResource('proveedores', ProveedorController::class);

    // ================= FACTURAS =================
    Route::post('/facturas', [FacturaController::class, 'store'])
        ->middleware('permission:crear_facturas');

    Route::get('/facturas', [FacturaController::class, 'index'])
        ->middleware('permission:ver_facturas');

    Route::get('/facturas/reportes', [FacturaController::class, 'reportes'])
        ->middleware('permission:ver_facturas');

    Route::get('/facturas/reporte/pdf-token', [FacturaController::class, 'generarTokenReporte'])
        ->middleware('permission:ver_facturas');

    Route::get('/facturas/{id}', [FacturaController::class, 'show'])
        ->middleware('permission:ver_facturas');

    Route::post('/facturas/{id}/pagar', [FacturaController::class, 'pagar'])
        ->middleware('permission:editar_facturas');

    Route::post('/facturas/{id}/nota-credito', [NotaCreditoController::class, 'store'])
        ->middleware('permission:editar_facturas');

    Route::get('/notas-credito', [NotaCreditoController::class, 'index'])
        ->middleware('permission:ver_facturas');

    Route::get('/notas-credito/{id}/pdf-url', [NotaCreditoController::class, 'pdfUrl'])
        ->middleware('permission:ver_facturas');

    Route::get('/documentos/{tipo}/{id}/url-temporal', [\App\Http\Controllers\Api\DocumentoVisorController::class, 'generarUrl'])
        ->middleware('permission:ver_facturas');

    // ================= COMPROBANTES FISCALES =================
    Route::get('/ncf-secuencias', [NcfSecuenciaController::class, 'index']);
    Route::get('/ncf-secuencias/{id}', [NcfSecuenciaController::class, 'show']);
    Route::post('/ncf-secuencias', [NcfSecuenciaController::class, 'store']);
    Route::put('/ncf-secuencias/{id}', [NcfSecuenciaController::class, 'update']);
    Route::patch('/ncf-secuencias/{id}/toggle', [NcfSecuenciaController::class, 'toggleActivo']);

    // ================= INVENTARIO (Módulo Inventario) =================
    Route::post('/inventario/ajuste', [InventarioController::class, 'ajuste'])
        ->middleware('permission:ver_inventario');

    Route::get('/inventario/movimientos', [InventarioController::class, 'movimientos'])
        ->middleware('permission:ver_inventario');

    Route::get('/inventario/existencias', [InventarioController::class, 'existencias'])
        ->middleware('permission:ver_inventario');

    Route::get('/inventario/alertas-stock', [InventarioController::class, 'alertasStock'])
        ->middleware('permission:ver_inventario');

    Route::get('/inventario/reporte/pdf-token', [InventarioController::class, 'generarTokenReporte'])
        ->middleware('permission:ver_inventario');

    // ================= CAJA Y TURNOS (Módulo Caja) =================
    Route::get('/cajas', [CajaController::class, 'index']);
    Route::get('/turnos', [CajaController::class, 'turnos']);
    Route::get('/caja/estado', [CajaController::class, 'estadoActual']);
    Route::get('/caja/resumen', [CajaController::class, 'resumen']);
    Route::post('/caja/cerrar', [CajaController::class, 'cerrar']);
    Route::get('/caja/historial', [CajaController::class, 'historial']);

    // ================= RECETAS =================
    Route::get('/recetas', [RecetaController::class, 'index'])
        ->middleware('permission:gestionar_recetas');
    Route::get('/recetas/{id}', [RecetaController::class, 'show'])
        ->middleware('permission:gestionar_recetas');
    Route::put('/recetas/{id}', [RecetaController::class, 'update'])
        ->middleware('permission:gestionar_recetas');

    // ================= NÓMINA =================
    Route::get('/empleados', [NominaController::class, 'getEmpleados'])
        ->middleware('permission:ver_nomina');

    Route::get('/nominas', [NominaController::class, 'index'])
        ->middleware('permission:ver_nomina');

    Route::post('/nominas', [NominaController::class, 'store'])
        ->middleware('permission:ver_nomina');

    Route::patch('/nominas/{id}/status', [NominaController::class, 'updateStatus'])
        ->middleware('permission:ver_nomina');

    // ================= EMPLEADOS =================
    Route::get('/empleados/all', [EmpleadoController::class, 'index'])
        ->middleware('permission:ver_nomina');

    Route::post('/empleados', [EmpleadoController::class, 'store'])
        ->middleware('permission:ver_nomina');

    Route::put('/empleados/{id}', [EmpleadoController::class, 'update'])
        ->middleware('permission:ver_nomina');

    Route::patch('/empleados/{id}/toggle', [EmpleadoController::class, 'toggleStatus'])
        ->middleware('permission:ver_nomina');

    // ================= METODOS DE PAGO =================
    Route::get('/metodos-pagos/activos', [\App\Http\Controllers\Api\Finanzas\MetodoPagoController::class, 'activos']);
    Route::apiResource('metodos-pagos', \App\Http\Controllers\Api\Finanzas\MetodoPagoController::class);

    // ================= CATÁLOGOS PRODUCTOS =================
    Route::apiResource('categorias', CategoriaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('marcas', MarcaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('unidades-medida', UnidadMedidaController::class)->middleware('permission:ver_inventario');
    Route::apiResource('impuestos', ImpuestoController::class)->middleware('permission:ver_inventario');

    // ================= DGII / IMPUESTOS =================
    Route::get('/dgii/balance', [DgiiController::class, 'getBalance']);
    Route::get('/dgii/pagos', [DgiiController::class, 'getPagos']);
    Route::post('/dgii/pagar', [DgiiController::class, 'registrarPago']);
    Route::get('/dgii/preview-606', [DgiiController::class, 'preview606']);
    Route::get('/dgii/preview-607', [DgiiController::class, 'preview607']);
    Route::get('/dgii/exportar-606', [DgiiController::class, 'exportar606']);
    Route::get('/dgii/exportar-607', [DgiiController::class, 'exportar607']);

    // ================= ORDENES DE COMPRA =================
    Route::apiResource('ordenes-compras', OrdenCompraController::class);
    Route::patch('ordenes-compras/{id}/estado', [OrdenCompraController::class, 'updateStatus']);
    Route::get('ordenes-compras/{id}/pdf', [OrdenCompraController::class, 'generatePdf']);

    // ================= FINANZAS / BANCOS =================
    Route::apiResource('bancos', BankController::class);
    Route::apiResource('cuentas-bancarias', BankAccountController::class);
    Route::post('transacciones-bancarias/conciliar', [BankTransactionController::class, 'reconcile']);
    Route::apiResource('transacciones-bancarias', BankTransactionController::class)->only(['index', 'store']);

    // ================= USUARIOS Y ROLES =================
    Route::get('/usuarios/roles', [\App\Http\Controllers\Api\UsuarioController::class, 'roles']);
    Route::apiResource('usuarios', \App\Http\Controllers\Api\UsuarioController::class);

});

// ================= MODULOS API V2 =================
Route::prefix('v2')->group(function () {
    require base_path('app/Modules/Auth/Routes/api.php');
    require base_path('app/Modules/Cliente/Routes/api.php');
    require base_path('app/Modules/Producto/Routes/api.php');
    require base_path('app/Modules/Caja/Routes/api.php');
    require base_path('app/Modules/Cotizacion/Routes/api.php');
    require base_path('app/Modules/Compra/Routes/api.php');
    require base_path('app/Modules/CuentaPorPagar/Routes/api.php');
    require base_path('app/Modules/CuentaPorCobrar/Routes/api.php');
    require base_path('app/Modules/Pago/Routes/api.php');
    require base_path('app/Modules/Pedido/Routes/api.php');
    require base_path('app/Modules/Mesa/Routes/api.php');
    require base_path('app/Modules/Contabilidad/Routes/api.php');
    require base_path('app/Modules/Inventario/Routes/api.php');
    require base_path('app/Modules/Ecf/Routes/api.php');
});
