<?php

namespace App\Http\Controllers\Api\Facturacion;

use App\Http\Controllers\Controller;
use App\Models\Factura;
use App\Http\Requests\Api\Facturacion\StoreFacturaRequest;
use App\Services\FacturacionService;
use App\Traits\HasIdempotency;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FacturaController extends Controller {
    use HasIdempotency;

    public function store(StoreFacturaRequest $request, FacturacionService $facturacionService) {
        try {
            // ── IDEMPOTENCIA ────────────────────────────────────────────────────
            $cached = $this->checkIdempotency($request, 'factura.store');
            if ($cached) return $cached;
            // ─────────────────────────────────────────────────────────────────────

            $facturaData = $facturacionService->procesarVenta($request->validated(), auth()->id() ?? 1);
            $ecfSummary = $facturaData['ecf'] ?? null;

            $responseData = [
                'message'          => 'Factura creada correctamente',
                'status'           => 201,
                'factura_id'       => $facturaData['factura_id'],
                'ncf'              => $facturaData['ncf'],
                'tipo_factura'     => $facturaData['tipo_factura'],
                'ecf'              => $ecfSummary,
                'codigo_seguridad' => $ecfSummary['codigo_seguridad'] ?? null,
                'fecha_hora_firma' => $ecfSummary['fecha_hora_firma'] ?? null,
                'qr_url'           => $ecfSummary['qr_url'] ?? null,
                'track_id'         => $ecfSummary['track_id'] ?? null,
                'estado_dgii'      => $ecfSummary['estado_dgii'] ?? null,
            ];

            return $this->saveIdempotency($request, 'factura.store', $responseData, 201);

        } catch (\Exception $e) {
            $this->failIdempotency($request, 'factura.store');

            return response()->json([
                'message' => 'Error al crear factura',
                'error'   => $e->getMessage(),
                'status'  => 500
            ], 500);
        }
    }

    public function index(Request $request)
    {
        $query = Factura::with(['cliente', 'detalles', 'user', 'ecfDocumento', 'pagos'])
            ->orderBy('id', 'desc');

        // Si no es admin, solo puede ver sus propias facturas
        if (!$request->user()->hasRole('admin')) {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('search')) {
            $searchTerm = $request->search;
            $query->where(function ($q) use ($searchTerm) {
                $q->where('id', 'like', "%{$searchTerm}%")
                  ->orWhere('ncf', 'like', "%{$searchTerm}%")
                  ->orWhereHas('cliente', function ($q2) use ($searchTerm) {
                      $q2->where('nombre', 'like', "%{$searchTerm}%");
                  });
            });
        }

        if ($request->filled('fecha_desde')) {
            $query->where('fecha_emision', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_emision', '<=', $request->fecha_hasta . ' 23:59:59');
        }

        if ($request->filled('cliente_id')) {
            $query->where('cliente_id', $request->cliente_id);
        }

        if ($request->filled('estado') && strtolower((string)$request->estado) !== 'todos') {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('metodo_pago') && strtolower((string)$request->metodo_pago) !== 'todos') {
            $metodo = strtolower(trim((string)$request->metodo_pago));
            if ($metodo === 'credito' || $metodo === 'pendiente') {
                $query->where(function ($q) use ($metodo) {
                    $q->where('estado', 'pendiente')
                      ->orWhereHas('pagos', function ($qp) use ($metodo) {
                          $qp->whereRaw('LOWER(metodo_pago) = ?', [$metodo]);
                      });
                });
            } else {
                $query->whereHas('pagos', function ($q) use ($metodo) {
                    $q->whereRaw('LOWER(metodo_pago) = ?', [$metodo]);
                });
            }
        }

        if ($request->filled('caja_sesion_id')) {
            $query->where('caja_sesion_id', $request->caja_sesion_id);
        }

        // --- CÁLCULO DE RESUMEN FILTRADO ---
        $resumenQuery = clone $query;
        $totales = $resumenQuery->reorder()->selectRaw('
            COUNT(*) as cantidad_facturas, 
            SUM(total) as total_venta, 
            SUM(itbis) as total_itbis, 
            SUM(descuento_total) as total_descuento
        ')->first();

        // Obtener desglose por método de pago para las facturas filtradas
        $facturaIds = (clone $query)->pluck('id');
        $porMetodo = DB::table('pagos')
            ->whereIn('factura_id', $facturaIds)
            ->selectRaw('metodo_pago, sum(monto_pagado) as total')
            ->groupBy('metodo_pago')
            ->get();

        $facturas = $query->paginate($request->per_page ?? 15);

        return response()->json([
            'status' => true,
            'data'   => $facturas,
            'resumen' => [
                'totales' => $totales,
                'por_metodo' => $porMetodo
            ]
        ]);
    }

    /**
     * Reportes agrupados de ventas
     */
    public function reportes(Request $request)
    {
        try {
            $fechaDesde = $request->fecha_desde;
            $fechaHasta = $request->fecha_hasta ? $request->fecha_hasta . ' 23:59:59' : null;

            // 1. Agrupado por Método de Pago
            $porMetodo = DB::table('pagos')
                ->selectRaw('metodo_pago, count(*) as cantidad, sum(monto_pagado) as total')
                ->when($fechaDesde, fn($q) => $q->where('fecha_pago', '>=', $fechaDesde))
                ->when($fechaHasta, fn($q) => $q->where('fecha_pago', '<=', $fechaHasta))
                ->groupBy('metodo_pago')
                ->get();

            // 2. Agrupado por Cajero
            $porCajero = DB::table('facturas')
                ->join('users', 'users.id', '=', 'facturas.user_id')
                ->selectRaw('users.name as cajero, count(*) as cantidad, sum(facturas.total) as total')
                ->when($fechaDesde, fn($q) => $q->where('fecha_emision', '>=', $fechaDesde))
                ->when($fechaHasta, fn($q) => $q->where('fecha_emision', '<=', $fechaHasta))
                ->groupBy('users.name')
                ->get();

            // 3. Agrupado por Tipo de Factura
            $porTipo = DB::table('facturas')
                ->selectRaw('tipo_factura, count(*) as cantidad, sum(facturas.total) as total')
                ->when($fechaDesde, fn($q) => $q->where('fecha_emision', '>=', $fechaDesde))
                ->when($fechaHasta, fn($q) => $q->where('fecha_emision', '<=', $fechaHasta))
                ->groupBy('tipo_factura')
                ->get();

            return response()->json([
                'status' => true,
                'data'   => [
                    'por_metodo' => $porMetodo,
                    'por_cajero' => $porCajero,
                    'por_tipo'   => $porTipo,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error en reporte: ' . $e->getMessage()
            ], 500);
        }
    }

    public function show($id) {
        try {
            $factura = Factura::with([
                'cliente',
                'detalles',
                'user',
                'ecfDocumento',
            ])->find($id);

            if (!$factura) {
                return response()->json([
                    'message' => 'Factura no encontrada',
                    'status' => 404
                ], 404);
            }

            return response()->json([
                'message' => 'Factura encontrada',
                'status' => 200,
                'data' => $factura
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al obtener factura',
                'error' => $e->getMessage(),
                'status' => 500
            ], 500);
        }
    }

    public function pagar($id) {
        $factura = Factura::findOrFail($id);

        $factura->update([
            'estado' => 'pagada'
        ]);

        return response()->json([
            'status'  => true,
            'message' => 'Factura pagada'
        ]);
    }

    /**
     * Genera un token temporal para abrir el reporte de facturación en el navegador mediante /d/{token}.
     */
    public function generarTokenReporte(Request $request, \App\Services\FacturaPdfService $facturaPdfService)
    {
        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $token = $facturaPdfService->generarTokenReporte(
            $request->all(),
            $companyData,
            $request->user()?->name,
            $request->user()?->id
        );

        return response()->json([
            'status'  => true,
            'message' => 'Enlace para reporte generado correctamente',
            'data'    => [
                'token'   => $token,
                'pdf_url' => "/d/{$token}",
            ]
        ]);
    }
}
