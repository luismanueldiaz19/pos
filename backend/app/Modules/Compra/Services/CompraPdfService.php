<?php

declare(strict_types=1);

namespace App\Modules\Compra\Services;

use App\Models\Compra;
use Barryvdh\DomPDF\Facade\Pdf;
use Barryvdh\DomPDF\PDF as DomPdfWrapper;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class CompraPdfService
{
    /**
     * Construye la consulta de compras aplicando los filtros especificados.
     */
    public function buildFilteredQuery(array $filters): Builder
    {
        $query = Compra::with(['proveedor', 'usuario', 'detalles.producto', 'detalles.cuentaContable', 'cuentaPorPagar', 'asiento.detalles.cuenta'])
            ->orderBy('fecha_compra', 'desc')
            ->orderBy('id', 'desc');

        if (!empty($filters['fecha_desde'])) {
            $query->where('fecha_compra', '>=', $filters['fecha_desde']);
        }

        if (!empty($filters['fecha_hasta'])) {
            $query->where('fecha_compra', '<=', $filters['fecha_hasta'] . ' 23:59:59');
        }

        if (!empty($filters['estado']) && strtolower((string)$filters['estado']) !== 'todos') {
            $query->where('estado', strtoupper((string)$filters['estado']));
        }

        if (!empty($filters['tipo_compra']) && strtolower((string)$filters['tipo_compra']) !== 'todos') {
            $query->where('tipo_compra', strtoupper((string)$filters['tipo_compra']));
        }

        if (!empty($filters['proveedor_id'])) {
            $query->where('proveedor_id', $filters['proveedor_id']);
        }

        if (isset($filters['es_gasto']) && $filters['es_gasto'] !== '') {
            $esGasto = filter_var($filters['es_gasto'], FILTER_VALIDATE_BOOLEAN);
            if ($esGasto) {
                // Gastos operativos: detalles sin producto_id
                $query->whereHas('detalles', function (Builder $d) {
                    $d->whereNull('producto_id');
                });
            } else {
                // Compras de inventario: detalles con producto_id
                $query->whereHas('detalles', function (Builder $d) {
                    $d->whereNotNull('producto_id');
                });
            }
        }

        if (!empty($filters['cuenta_contable_id'])) {
            $query->whereHas('detalles', function (Builder $d) use ($filters) {
                $d->where('cuenta_contable_id', $filters['cuenta_contable_id']);
            });
        }

        if (!empty($filters['search'])) {
            $search = strtolower(trim((string)$filters['search']));
            $query->where(function (Builder $q) use ($search) {
                $q->whereRaw('LOWER(numero_factura_proveedor) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(ncf) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(notas) LIKE ?', ["%{$search}%"])
                  ->orWhereHas('proveedor', function (Builder $p) use ($search) {
                      $p->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                        ->orWhereRaw('LOWER(rnc) LIKE ?', ["%{$search}%"]);
                  })
                  ->orWhereHas('detalles', function (Builder $d) use ($search) {
                      $d->whereRaw('LOWER(descripcion) LIKE ?', ["%{$search}%"]);
                  });
            });
        }

        return $query;
    }

    /**
     * Genera el PDF del Reporte de Compras con los filtros aplicados.
     */
    public function generarReportePdf(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null
    ): DomPdfWrapper {
        $compras = $this->buildFilteredQuery($filters)->get();

        $totales = [
            'cantidad'        => $compras->count(),
            'total_compras'   => (float) $compras->sum('total'),
            'total_subtotal'  => (float) $compras->sum('subtotal'),
            'total_impuestos' => (float) $compras->sum('impuestos'),
            'total_pagado'    => (float) $compras->where('estado', 'PAGADA')->sum('total'),
            'total_pendiente' => (float) $compras->where('estado', 'PENDIENTE')->sum('total'),
        ];

        $company = $this->prepareCompanyData($companyData);
        $base64Logo = $this->getCompanyLogoBase64();
        $fechaGeneracion = Carbon::now();

        $pdf = Pdf::loadView('pdf.compras_reporte', [
            'compras'         => $compras,
            'totales'         => $totales,
            'filters'         => $filters,
            'company'         => $company,
            'base64Logo'      => $base64Logo,
            'fechaGeneracion' => $fechaGeneracion,
            'usuarioName'     => $usuarioName ?? 'Sistema',
        ]);

        $pdf->setPaper('letter', 'landscape');

        return $pdf;
    }

    /**
     * Genera el PDF individual de una factura de compra.
     */
    public function generarCompraPdf(int $id, array $companyData = []): DomPdfWrapper
    {
        $compra = Compra::with(['proveedor', 'detalles.producto', 'usuario', 'cuentaPorPagar'])
            ->findOrFail($id);

        $company = $this->prepareCompanyData($companyData);
        $base64Logo = $this->getCompanyLogoBase64();

        $pdf = Pdf::loadView('pdf.compra', [
            'compra'     => $compra,
            'company'    => $company,
            'base64Logo' => $base64Logo,
        ]);

        $pdf->setPaper('letter', 'portrait');

        return $pdf;
    }

    /**
     * Crea un token de enlace corto (24 horas) para el Reporte de Compras.
     */
    public function generarTokenReporte(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null
    ): string {
        $token = Str::random(40);

        Cache::put("short_link_{$token}", [
            'type'        => 'compras_reporte',
            'filters'     => $filters,
            'companyData' => $companyData,
            'usuarioName' => $usuarioName,
        ], now()->addHours(24));

        return $token;
    }

    /**
     * Crea un token de enlace corto (24 horas) para una factura de compra individual.
     */
    public function generarTokenCompra(int $id, array $companyData = []): string
    {
        $token = Str::random(40);

        Cache::put("short_link_{$token}", [
            'type'        => 'compra',
            'id'          => $id,
            'companyData' => $companyData,
        ], now()->addHours(24));

        return $token;
    }

    /**
     * Prepara la información de la empresa con valores por defecto si no se especifican.
     */
    private function prepareCompanyData(array $companyData): array
    {
        return [
            'nombre'    => !empty($companyData['company_name']) ? $companyData['company_name'] : config('company.nombre'),
            'rnc'       => !empty($companyData['company_rnc']) ? $companyData['company_rnc'] : config('company.rnc'),
            'direccion' => !empty($companyData['company_address']) ? $companyData['company_address'] : config('company.direccion'),
            'telefono'  => !empty($companyData['company_phone']) ? $companyData['company_phone'] : config('company.telefono'),
            'email'     => !empty($companyData['company_email']) ? $companyData['company_email'] : config('company.email'),
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
