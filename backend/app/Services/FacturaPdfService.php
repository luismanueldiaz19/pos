<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Factura;
use Barryvdh\DomPDF\Facade\Pdf;
use Barryvdh\DomPDF\PDF as DomPdfWrapper;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class FacturaPdfService
{
    /**
     * Construye la consulta de facturas aplicando los filtros especificados y control de acceso.
     */
    public function buildFilteredQuery(array $filters = [], $user = null): Builder
    {
        $query = Factura::with(['cliente', 'user', 'ecfDocumento', 'detalles'])
            ->orderBy('fecha_emision', 'desc')
            ->orderBy('id', 'desc');

        // Si el usuario no es admin, solo ve sus propias facturas
        if ($user && method_exists($user, 'hasRole') && !$user->hasRole('admin')) {
            $query->where('user_id', $user->id);
        }

        if (!empty($filters['search'])) {
            $searchTerm = trim((string)$filters['search']);
            $query->where(function (Builder $q) use ($searchTerm) {
                $q->where('id', 'like', "%{$searchTerm}%")
                  ->orWhere('ncf', 'like', "%{$searchTerm}%")
                  ->orWhereHas('cliente', function (Builder $q2) use ($searchTerm) {
                      $q2->where('nombre', 'like', "%{$searchTerm}%")
                         ->orWhere('rnc_cedula', 'like', "%{$searchTerm}%");
                  });
            });
        }

        if (!empty($filters['fecha_desde'])) {
            $query->where('fecha_emision', '>=', $filters['fecha_desde']);
        }

        if (!empty($filters['fecha_hasta'])) {
            $query->where('fecha_emision', '<=', $filters['fecha_hasta'] . ' 23:59:59');
        }

        if (!empty($filters['estado']) && strtolower((string)$filters['estado']) !== 'todos') {
            $estado = strtolower(trim((string)$filters['estado']));
            $query->whereRaw('LOWER(estado) = ?', [$estado]);
        }

        if (!empty($filters['cliente_id'])) {
            $query->where('cliente_id', $filters['cliente_id']);
        }

        if (!empty($filters['caja_sesion_id'])) {
            $query->where('caja_sesion_id', $filters['caja_sesion_id']);
        }

        return $query;
    }

    /**
     * Genera el PDF del Reporte de Facturación con los filtros aplicados.
     */
    public function generarReportePdf(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null,
        $user = null
    ): DomPdfWrapper {
        $facturas = $this->buildFilteredQuery($filters, $user)->get();

        $validas = $facturas->filter(fn($f) => strtolower((string)$f->estado) !== 'anulada');

        $totales = [
            'cantidad'        => $facturas->count(),
            'total_venta'     => (float) $validas->sum('total'),
            'total_subtotal'  => (float) $validas->sum('subtotal'),
            'total_itbis'     => (float) $validas->sum('itbis'),
            'total_descuento' => (float) $validas->sum('descuento_total'),
            'total_pagado'    => (float) $facturas->filter(fn($f) => strtolower((string)$f->estado) === 'pagada')->sum('total'),
            'total_pendiente' => (float) $facturas->filter(fn($f) => strtolower((string)$f->estado) === 'pendiente')->sum('total'),
            'total_anulado'   => (float) $facturas->filter(fn($f) => strtolower((string)$f->estado) === 'anulada')->sum('total'),
        ];

        $company = $this->prepareCompanyData($companyData);
        $base64Logo = $this->getCompanyLogoBase64();
        $fechaGeneracion = Carbon::now();

        $pdf = Pdf::loadView('pdf.facturas_reporte', [
            'facturas'        => $facturas,
            'totales'         => $totales,
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
     * Crea un token de enlace corto (24 horas) para el Reporte de Facturas.
     */
    public function generarTokenReporte(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null,
        ?int $userId = null
    ): string {
        $token = Str::random(40);

        Cache::put("short_link_{$token}", [
            'type'        => 'facturas_reporte',
            'filters'     => $filters,
            'companyData' => $companyData,
            'usuarioName' => $usuarioName,
            'userId'      => $userId,
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

