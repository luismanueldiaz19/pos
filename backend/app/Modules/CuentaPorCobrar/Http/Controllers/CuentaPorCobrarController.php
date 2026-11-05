<?php
declare(strict_types=1);

namespace App\Modules\CuentaPorCobrar\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\CuentaPorCobrar\DTOs\RegistrarCobroDTO;
use App\Modules\CuentaPorCobrar\Http\Requests\RegistrarCobroRequest;
use App\Modules\CuentaPorCobrar\Services\CuentaPorCobrarService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use App\Traits\HasIdempotency;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CuentaPorCobrarController extends Controller
{
    use ApiResponseTrait;
    use HasIdempotency;

    public function __construct(
        private readonly CuentaPorCobrarService $cxcService
    ) {}

    public function index(): JsonResponse
    {
        $cxcs = $this->cxcService->getPending();
        return $this->successResponse(
            data: $cxcs,
            message: 'Lista de cuentas por cobrar pendientes'
        );
    }

    public function registrarPago(RegistrarCobroRequest $request, int $id): JsonResponse
    {
        // ── IDEMPOTENCIA ─────────────────────────────────────────────────────
        $cached = $this->checkIdempotency($request, 'cxc.pago');
        if ($cached) return $cached;
        // ─────────────────────────────────────────────────────────────────────

        try {
            $dto = RegistrarCobroDTO::fromRequest($request, $id);
            $pago = $this->cxcService->registrarCobro($dto);

            $responseData = ['pago' => $pago];
            return $this->saveIdempotency($request, 'cxc.pago', $responseData, 200, 'Cobro registrado con éxito');
        } catch (\Exception $e) {
            $this->failIdempotency($request, 'cxc.pago');
            return $this->errorResponse(
                message: 'Error al registrar el cobro: ' . $e->getMessage(),
                code: 400
            );
        }
    }

    public function historialPagos(Request $request): JsonResponse
    {
        $pagos = $this->cxcService->getHistorialPagos($request->all());
        return $this->successResponse(
            data: $pagos,
            message: 'Historial de cobros realizados'
        );
    }

    public function generarTokenReporte(Request $request, \App\Modules\CuentaPorCobrar\Services\CobroPdfService $cobroPdfService): JsonResponse
    {
        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $token = $cobroPdfService->generarTokenReporte(
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
            message: 'Enlace para reporte de cobros generado correctamente'
        );
    }
}
