<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Inventario\DTOs\FiltroKardexDTO;
use App\Modules\Inventario\DTOs\RegistrarAjusteDTO;
use App\Modules\Inventario\Exceptions\InventarioException;
use App\Modules\Inventario\Http\Requests\RegistrarAjusteRequest;
use App\Modules\Inventario\Services\InventarioService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InventarioController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly InventarioService $inventarioService
    ) {}

    /**
     * Obtener el historial de movimientos de inventario (Kardex).
     * Mantiene compatibilidad con el frontend retornando la lista en 'data' y metadatos en 'meta'.
     */
    public function movimientos(Request $request): JsonResponse
    {
        $dto = FiltroKardexDTO::fromRequest($request);
        $paginator = $this->inventarioService->getMovimientos($dto);

        return response()->json([
            'success' => true,
            'message' => 'Movimientos de inventario obtenidos correctamente',
            'data'    => $paginator->items(),
            'meta'    => [
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
                'per_page'     => $paginator->perPage(),
                'total'        => $paginator->total(),
            ],
        ], 200);
    }

    /**
     * Registrar un ajuste manual de inventario (Entrada o Salida)
     */
    public function ajuste(RegistrarAjusteRequest $request): JsonResponse
    {
        try {
            $dto = RegistrarAjusteDTO::fromRequest($request);
            $movimiento = $this->inventarioService->registrarAjuste($dto);

            return $this->successResponse(
                data: $movimiento,
                message: 'Ajuste de inventario guardado correctamente',
                code: 201
            );
        } catch (InventarioException $e) {
            return $this->errorResponse(
                message: $e->getMessage(),
                code: 400
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al registrar el ajuste: ' . $e->getMessage(),
                code: 500
            );
        }
    }

    /**
     * Obtener existencias actuales valorizadas (costo y venta)
     */
    public function existencias(Request $request): JsonResponse
    {
        try {
            $data = $this->inventarioService->getExistencias($request->all());

            return $this->successResponse(
                data: $data,
                message: 'Existencias de inventario obtenidas exitosamente'
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al consultar existencias: ' . $e->getMessage(),
                code: 500
            );
        }
    }

    /**
     * Obtener alertas de productos con existencias por debajo del stock mínimo
     */
    public function alertasStock(): JsonResponse
    {
        try {
            $productos = $this->inventarioService->getProductosBajoStockMinimo();

            return $this->successResponse(
                data: $productos,
                message: 'Alertas de stock mínimo obtenidas exitosamente'
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al consultar alertas de stock: ' . $e->getMessage(),
                code: 500
            );
        }
    }

    /**
     * Generar token de enlace corto para previsualizar / descargar reportes en PDF
     */
    public function generarTokenReporte(
        Request $request,
        \App\Modules\Inventario\Services\InventarioPdfService $inventarioPdfService
    ): JsonResponse {
        $tipoReporte = (string) $request->input('tipo_reporte', 'existencias');

        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $token = $inventarioPdfService->generarTokenReporte(
            $tipoReporte,
            $request->all(),
            $companyData,
            $request->user()?->name,
            $request->user()?->id
        );

        return $this->successResponse(
            data: [
                'token'   => $token,
                'pdf_url' => "/d/{$token}",
            ],
            message: "Enlace para reporte de inventario ({$tipoReporte}) generado correctamente"
        );
    }
}
