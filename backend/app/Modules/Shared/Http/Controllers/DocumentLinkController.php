<?php

declare(strict_types=1);

namespace App\Modules\Shared\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Cotizacion;
use App\Modules\Compra\Services\CompraPdfService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Barryvdh\DomPDF\Facade\Pdf;

class DocumentLinkController extends Controller
{
    public function show(Request $request, string $token)
    {
        $data = Cache::get("short_link_{$token}");

        if (!$data) {
            abort(404, 'El enlace ha expirado o no es válido.');
        }

        if ($data['type'] === 'cotizacion') {
            return $this->generarPdfCotizacion((int) $data['id'], $data['companyData'] ?? []);
        }

        if ($data['type'] === 'compras_reporte') {
            $compraPdfService = app(CompraPdfService::class);
            $pdf = $compraPdfService->generarReportePdf(
                $data['filters'] ?? [],
                $data['companyData'] ?? [],
                $data['usuarioName'] ?? null
            );
            return $pdf->stream('reporte_compras_' . now()->format('Ymd_His') . '.pdf');
        }

        if ($data['type'] === 'compra') {
            $compraPdfService = app(CompraPdfService::class);
            $pdf = $compraPdfService->generarCompraPdf(
                (int) $data['id'],
                $data['companyData'] ?? []
            );
            return $pdf->stream('factura_compra_' . $data['id'] . '.pdf');
        }

        abort(404, 'Tipo de documento no soportado.');
    }

    private function generarPdfCotizacion(int $id, array $companyData)
    {
        $cotizacion = Cotizacion::with(['cliente', 'detalles', 'user'])->findOrFail($id);

        $company = [
            'nombre'    => !empty($companyData['company_name']) ? $companyData['company_name'] : config('company.nombre'),
            'rnc'       => !empty($companyData['company_rnc']) ? $companyData['company_rnc'] : config('company.rnc'),
            'direccion' => !empty($companyData['company_address']) ? $companyData['company_address'] : config('company.direccion'),
            'telefono'  => !empty($companyData['company_phone']) ? $companyData['company_phone'] : config('company.telefono'),
            'email'     => !empty($companyData['company_email']) ? $companyData['company_email'] : config('company.email'),
        ];

        $pdf = Pdf::loadView('pdf.cotizacion', compact('cotizacion', 'company'));

        return $pdf->stream('cotizacion_'.$cotizacion->id.'.pdf');
    }
}
