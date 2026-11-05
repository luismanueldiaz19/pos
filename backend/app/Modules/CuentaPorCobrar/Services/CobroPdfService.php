<?php

declare(strict_types=1);

namespace App\Modules\CuentaPorCobrar\Services;

use App\Models\PagoCxc;
use Barryvdh\DomPDF\Facade\Pdf;
use Barryvdh\DomPDF\PDF as DomPdfWrapper;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class CobroPdfService
{
    /**
     * Construye la consulta filtrada de cobros (pagos de CxC).
     */
    public function buildFilteredQuery(array $filters = []): Builder
    {
        $query = PagoCxc::with([
            'cuentaPorCobrar.cliente',
            'cuentaPorCobrar.factura',
            'cuentaDestino',
            'usuario'
        ])
        ->orderBy('fecha_pago', 'desc')
        ->orderBy('id', 'desc');

        if (!empty($filters['fecha_desde'])) {
            $query->where('fecha_pago', '>=', $filters['fecha_desde']);
        }

        if (!empty($filters['fecha_hasta'])) {
            $query->where('fecha_pago', '<=', $filters['fecha_hasta'] . ' 23:59:59');
        }

        if (!empty($filters['metodo_pago']) && strtolower((string)$filters['metodo_pago']) !== 'todos') {
            $metodo = strtolower(trim((string)$filters['metodo_pago']));
            $query->whereRaw('LOWER(metodo_pago) = ?', [$metodo]);
        }

        if (!empty($filters['search'])) {
            $s = trim((string)$filters['search']);
            $query->where(function (Builder $q) use ($s) {
                $q->where('id', 'like', "%{$s}%")
                  ->orWhere('referencia', 'like', "%{$s}%")
                  ->orWhere('metodo_pago', 'like', "%{$s}%")
                  ->orWhereHas('cuentaPorCobrar.cliente', function (Builder $qc) use ($s) {
                      $qc->where('nombre', 'like', "%{$s}%")
                         ->orWhere('rnc_cedula', 'like', "%{$s}%");
                  })
                  ->orWhereHas('cuentaPorCobrar.factura', function (Builder $qf) use ($s) {
                      $qf->where('ncf', 'like', "%{$s}%")
                         ->orWhere('id', 'like', "%{$s}%");
                  });
            });
        }

        return $query;
    }

    /**
     * Genera el PDF del Reporte de Cobros con los filtros aplicados.
     */
    public function generarReportePdf(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null,
        $user = null
    ): DomPdfWrapper {
        $pagos = $this->buildFilteredQuery($filters)->get();

        $totalRecaudado = (float) $pagos->sum('monto_pagado');
        $cantidad = $pagos->count();
        $promedio = $cantidad > 0 ? ($totalRecaudado / $cantidad) : 0.0;

        $totales = [
            'cantidad'        => $cantidad,
            'total_recaudado' => $totalRecaudado,
            'promedio_cobro'  => $promedio,
        ];

        // Desglose agrupado por método de pago
        $desgloseMetodos = $pagos->groupBy(fn($p) => strtoupper(trim((string)$p->metodo_pago)))
            ->map(function ($items, $metodo) {
                return (object) [
                    'metodo'   => $metodo,
                    'total'    => (float) $items->sum('monto_pagado'),
                    'cantidad' => $items->count(),
                ];
            })
            ->sortByDesc('total')
            ->values();

        $company = $this->prepareCompanyData($companyData);
        $base64Logo = $this->getCompanyLogoBase64();
        $fechaGeneracion = Carbon::now();

        $pdf = Pdf::loadView('pdf.cobros_reporte', [
            'pagos'           => $pagos,
            'totales'         => $totales,
            'desgloseMetodos' => $desgloseMetodos,
            'filters'         => $filters,
            'company'         => $company,
            'base64Logo'      => $base64Logo,
            'fechaGeneracion' => $fechaGeneracion,
            'usuarioName'     => $usuarioName ?? 'Administrador',
        ]);

        $pdf->setPaper('letter', 'landscape');

        return $pdf;
    }

    /**
     * Crea un token de enlace corto (24 horas) para el Reporte de Cobros.
     */
    public function generarTokenReporte(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null,
        ?int $userId = null
    ): string {
        $token = Str::random(40);

        Cache::put("short_link_{$token}", [
            'type'        => 'cobros_reporte',
            'filters'     => $filters,
            'companyData' => $companyData,
            'usuarioName' => $usuarioName,
            'userId'      => $userId,
        ], now()->addHours(24));

        return $token;
    }

    /**
     * Prepara la información de la empresa con valores por defecto.
     */
    private function prepareCompanyData(array $companyData): array
    {
        return [
            'nombre'    => !empty($companyData['company_name']) ? $companyData['company_name'] : config('company.nombre'),
            'rnc'       => !empty($companyData['company_rnc']) ? $companyData['company_rnc'] : config('company.rnc'),
            'direccion' => !empty($companyData['company_address']) ? $companyData['company_address'] : config('company.direccion'),
            'telefono'  => !empty($companyData['company_phone']) ? $companyData['company_phone'] : config('company.telefono', '(809) 697-8028'),
            'email'     => !empty($companyData['company_email']) ? $companyData['company_email'] : config('company.email', '---'),
        ];
    }

    /**
     * Obtiene el logo institucional en Base64 para incrustar en el PDF.
     */
    private function getCompanyLogoBase64(): string
    {
        $logoPath = public_path('images/app_icon.png');
        if (file_exists($logoPath)) {
            $type = pathinfo($logoPath, PATHINFO_EXTENSION);
            $data = file_get_contents($logoPath);
            return 'data:image/' . $type . ';base64,' . base64_encode($data);
        }

        return '';
    }
}
