<?php

declare(strict_types=1);

namespace App\Modules\Compra\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Compra\DTOs\CreateCompraDTO;
use App\Modules\Compra\Http\Requests\StoreCompraRequest;
use App\Modules\Compra\Services\CompraService;
use App\Modules\Compra\Services\CompraPdfService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use App\Models\Compra;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CompraController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly CompraService $compraService,
        private readonly CompraPdfService $compraPdfService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = $this->compraPdfService->buildFilteredQuery($request->all());

        $resumenQuery = clone $query;
        $totales = $resumenQuery->reorder()->selectRaw('
            COUNT(*) as cantidad,
            COALESCE(SUM(total), 0) as total_general,
            COALESCE(SUM(impuestos), 0) as total_itbis,
            COALESCE(SUM(subtotal), 0) as total_subtotal,
            COALESCE(SUM(CASE WHEN UPPER(tipo_compra) = \'CONTADO\' THEN total ELSE 0 END), 0) as total_contado,
            COALESCE(SUM(CASE WHEN UPPER(tipo_compra) = \'CREDITO\' THEN total ELSE 0 END), 0) as total_credito
        ')->first();

        $compras = $query->paginate((int)$request->input('per_page', 20));

        // Si se solicitan URLs de PDF para cada compra (igual que en Cotizaciones)
        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $compras->getCollection()->transform(function ($compra) use ($companyData) {
            $token = $this->compraPdfService->generarTokenCompra($compra->id, $companyData);
            $compra->pdf_url = "/d/{$token}";
            return $compra;
        });

        return $this->successResponse(
            data: array_merge($compras->toArray(), ['totales' => $totales]),
            message: 'Lista de compras'
        );
    }

    public function store(StoreCompraRequest $request): JsonResponse
    {
        try {
            $dto = CreateCompraDTO::fromRequest($request);
            $result = $this->compraService->create($dto);

            // Generar pdf_url para la compra recién creada
            $companyData = [
                'company_name'    => $request->company_name,
                'company_rnc'     => $request->company_rnc,
                'company_address' => $request->company_address,
                'company_phone'   => $request->company_phone,
            ];

            if (isset($result['id'])) {
                $token = $this->compraPdfService->generarTokenCompra((int)$result['id'], $companyData);
                $result['pdf_url'] = "/d/{$token}";
            }

            return $this->successResponse(
                data: $result,
                message: 'Compra registrada correctamente',
                code: 201
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al registrar la compra: ' . $e->getMessage(),
                code: 400
            );
        }
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $compra = Compra::with(['proveedor', 'detalles.producto', 'usuario', 'cuentaPorPagar', 'asiento.detalles.cuenta'])->find($id);

        if (!$compra) {
            return $this->errorResponse('Compra no encontrada', 404);
        }

        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $token = $this->compraPdfService->generarTokenCompra($compra->id, $companyData);
        $compra->pdf_url = "/d/{$token}";

        return $this->successResponse(
            data: $compra,
            message: 'Detalle de la compra'
        );
    }

    /**
     * Genera y transmite directamente el PDF del reporte filtrado de compras.
     */
    public function pdfReporte(Request $request)
    {
        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $pdf = $this->compraPdfService->generarReportePdf(
            $request->all(),
            $companyData,
            $request->user()?->name
        );

        return $pdf->stream('reporte_compras_' . now()->format('Ymd_His') . '.pdf');
    }

    /**
     * Genera un token temporal para abrir el reporte en navegador mediante /d/{token}.
     */
    public function generarTokenReporte(Request $request): JsonResponse
    {
        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $token = $this->compraPdfService->generarTokenReporte(
            $request->all(),
            $companyData,
            $request->user()?->name
        );

        return $this->successResponse(
            data: [
                'token'   => $token,
                'pdf_url' => "/d/{$token}",
            ],
            message: 'Enlace para reporte generado correctamente'
        );
    }

    /**
     * Genera y transmite directamente el PDF individual de una factura de compra.
     */
    public function pdf(Request $request, int $id)
    {
        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $pdf = $this->compraPdfService->generarCompraPdf($id, $companyData);

        return $pdf->stream("compra_{$id}.pdf");
    }

    /**
     * Genera un token temporal para abrir una factura individual mediante /d/{token}.
     */
    public function generarTokenCompra(Request $request, int $id): JsonResponse
    {
        $companyData = [
            'company_name'    => $request->company_name,
            'company_rnc'     => $request->company_rnc,
            'company_address' => $request->company_address,
            'company_phone'   => $request->company_phone,
        ];

        $token = $this->compraPdfService->generarTokenCompra($id, $companyData);

        return $this->successResponse(
            data: [
                'token'   => $token,
                'pdf_url' => "/d/{$token}",
            ],
            message: 'Enlace para factura de compra generado correctamente'
        );
    }
}
