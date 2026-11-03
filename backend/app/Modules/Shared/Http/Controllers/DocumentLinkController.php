<?php

declare(strict_types=1);

namespace App\Modules\Shared\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Cotizacion;
use App\Models\User;
use App\Modules\Compra\Services\CompraPdfService;
use App\Services\FacturaPdfService;
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

        if ($data['type'] === 'facturas_reporte') {
            $facturaPdfService = app(FacturaPdfService::class);
            $user = !empty($data['userId']) ? User::find($data['userId']) : null;
            $pdf = $facturaPdfService->generarReportePdf(
                $data['filters'] ?? [],
                $data['companyData'] ?? [],
                $data['usuarioName'] ?? null,
                $user
            );
            return $pdf->stream('reporte_facturas_' . now()->format('Ymd_His') . '.pdf');
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

        $base64Logo = null;
        $logoPath = public_path('images/app_icon.png');
        if (file_exists($logoPath)) {
            $type = pathinfo($logoPath, PATHINFO_EXTENSION);
            $data = file_get_contents($logoPath);
            $base64Logo = 'data:image/' . $type . ';base64,' . base64_encode($data);
        }

        $pdf = Pdf::loadView('pdf.cotizacion', compact('cotizacion', 'company', 'base64Logo'));

        return $pdf->stream('cotizacion_'.$cotizacion->id.'.pdf');
    }
}
