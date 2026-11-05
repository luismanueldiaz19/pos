<?php

declare(strict_types=1);

namespace App\Modules\Inventario\Services;

use App\Models\MovimientoInventario;
use App\Models\Producto;
use Barryvdh\DomPDF\Facade\Pdf;
use Barryvdh\DomPDF\PDF as DomPdfWrapper;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class InventarioPdfService
{
    /**
     * Genera el PDF del Reporte de Existencias y Valorización de Inventario.
     */
    public function generarReporteExistenciasPdf(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null,
        $user = null
    ): DomPdfWrapper {
        $query = Producto::with(['categoria', 'unidadMedida', 'marca'])
            ->where('maneja_inventario', true)
            ->where('tipo_producto', '!=', 'SERVICIO')
            ->where('activo', true);

        if (!empty($filters['categoria_id'])) {
            $query->where('categoria_id', $filters['categoria_id']);
        }

        if (!empty($filters['search'])) {
            $term = trim((string) $filters['search']);
            $query->where(function (Builder $q) use ($term) {
                $q->where('nombre', 'like', "%{$term}%")
                  ->orWhere('codigo', 'like', "%{$term}%");
            });
        }

        $productos = $query->orderBy('categoria_id', 'asc')
            ->orderBy('nombre', 'asc')
            ->get();

        $totalUnidades = 0.0;
        $valorTotalCosto = 0.0;
        $valorTotalVenta = 0.0;
        $itemsBajoMinimo = 0;

        foreach ($productos as $p) {
            $stock = (float) $p->stock_actual;
            $minimo = (float) $p->stock_minimo;
            $costo = (float) $p->costo;
            $precio = (float) $p->precio_venta;

            $totalUnidades += $stock;
            $valorTotalCosto += round($stock * $costo, 2);
            $valorTotalVenta += round($stock * $precio, 2);

            if ($stock <= $minimo) {
                $itemsBajoMinimo++;
            }
        }

        $margenEstimado = $valorTotalVenta > 0
            ? round((($valorTotalVenta - $valorTotalCosto) / $valorTotalVenta) * 100, 2)
            : 0.0;

        $totales = [
            'total_items'       => $productos->count(),
            'total_unidades'    => $totalUnidades,
            'valor_total_costo' => $valorTotalCosto,
            'valor_total_venta' => $valorTotalVenta,
            'margen_estimado'   => $margenEstimado,
            'items_bajo_minimo' => $itemsBajoMinimo,
        ];

        // Desglose agrupado por categoría
        $desgloseCategorias = $productos->groupBy(fn($p) => $p->categoria?->nombre ?? 'Sin Categoría')
            ->map(function ($items, $categoriaNombre) {
                $unidadesCat = (float) $items->sum('stock_actual');
                $costoCat = (float) $items->sum(fn($p) => ((float) $p->stock_actual) * ((float) $p->costo));
                $ventaCat = (float) $items->sum(fn($p) => ((float) $p->stock_actual) * ((float) $p->precio_venta));

                return (object) [
                    'categoria'       => $categoriaNombre,
                    'cantidad_items'  => $items->count(),
                    'unidades'        => $unidadesCat,
                    'valor_costo'     => $costoCat,
                    'valor_venta'     => $ventaCat,
                ];
            })
            ->sortByDesc('valor_costo')
            ->values();

        $company = $this->prepareCompanyData($companyData);
        $base64Logo = $this->getCompanyLogoBase64();
        $fechaGeneracion = Carbon::now();

        $pdf = Pdf::loadView('pdf.inventario_existencias_reporte', [
            'productos'          => $productos,
            'totales'            => $totales,
            'desgloseCategorias' => $desgloseCategorias,
            'filters'            => $filters,
            'company'            => $company,
            'base64Logo'         => $base64Logo,
            'fechaGeneracion'    => $fechaGeneracion,
            'usuarioName'        => $usuarioName ?? 'Administrador',
        ]);

        $pdf->setPaper('letter', 'landscape');

        return $pdf;
    }

    /**
     * Genera el PDF del Reporte de Kardex y Movimientos de Inventario.
     */
    public function generarReporteKardexPdf(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null,
        $user = null
    ): DomPdfWrapper {
        $query = MovimientoInventario::with(['producto.categoria', 'producto.unidadMedida'])
            ->orderBy('fecha', 'desc')
            ->orderBy('id', 'desc');

        if (!empty($filters['producto_id'])) {
            $query->where('producto_id', $filters['producto_id']);
        }

        if (!empty($filters['tipo']) && strtoupper((string) $filters['tipo']) !== 'TODOS') {
            $query->where('tipo', strtoupper((string) $filters['tipo']));
        }

        if (!empty($filters['fecha_desde'])) {
            $query->where('fecha', '>=', $filters['fecha_desde'] . ' 00:00:00');
        }

        if (!empty($filters['fecha_hasta'])) {
            $query->where('fecha', '<=', $filters['fecha_hasta'] . ' 23:59:59');
        }

        if (!empty($filters['search'])) {
            $term = trim((string) $filters['search']);
            $query->where(function (Builder $q) use ($term) {
                $q->where('referencia', 'like', "%{$term}%")
                  ->orWhereHas('producto', function (Builder $qp) use ($term) {
                      $qp->where('nombre', 'like', "%{$term}%")
                         ->orWhere('codigo', 'like', "%{$term}%");
                  });
            });
        }

        $movimientos = $query->get();

        $totalEntradas = 0.0;
        $totalSalidas = 0.0;
        $cantEntradas = 0;
        $cantSalidas = 0;

        foreach ($movimientos as $m) {
            $cant = (float) $m->cantidad;
            if (strtoupper((string) $m->tipo) === 'ENTRADA') {
                $totalEntradas += $cant;
                $cantEntradas++;
            } else {
                $totalSalidas += $cant;
                $cantSalidas++;
            }
        }

        $totales = [
            'total_movimientos' => $movimientos->count(),
            'total_entradas'    => $totalEntradas,
            'cant_entradas'     => $cantEntradas,
            'total_salidas'     => $totalSalidas,
            'cant_salidas'      => $cantSalidas,
            'saldo_neto'        => $totalEntradas - $totalSalidas,
        ];

        $company = $this->prepareCompanyData($companyData);
        $base64Logo = $this->getCompanyLogoBase64();
        $fechaGeneracion = Carbon::now();

        $pdf = Pdf::loadView('pdf.inventario_kardex_reporte', [
            'movimientos'     => $movimientos,
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
     * Genera el PDF del Reporte de Alertas de Reposición y Déficit.
     */
    public function generarReporteAlertasPdf(
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null,
        $user = null
    ): DomPdfWrapper {
        $query = Producto::with(['categoria', 'unidadMedida'])
            ->where('maneja_inventario', true)
            ->where('tipo_producto', '!=', 'SERVICIO')
            ->where('activo', true)
            ->whereColumn('stock_actual', '<=', 'stock_minimo');

        if (!empty($filters['categoria_id'])) {
            $query->where('categoria_id', $filters['categoria_id']);
        }

        if (!empty($filters['search'])) {
            $term = trim((string) $filters['search']);
            $query->where(function (Builder $q) use ($term) {
                $q->where('nombre', 'like', "%{$term}%")
                  ->orWhere('codigo', 'like', "%{$term}%");
            });
        }

        if (!empty($filters['estado_alerta'])) {
            $estado = strtolower(trim((string) $filters['estado_alerta']));
            if ($estado === 'deficit') {
                $query->where('stock_actual', '<', 0);
            } elseif ($estado === 'agotado') {
                $query->where('stock_actual', '=', 0);
            } elseif ($estado === 'bajo_minimo') {
                $query->where('stock_actual', '>', 0);
            }
        }

        $productos = $query->orderBy('stock_actual', 'asc')->get();

        $totalDeficit = 0;
        $totalAgotados = 0;
        $totalBajoMinimo = 0;
        $unidadesFaltantesTotal = 0.0;
        $inversionEstimadaTotal = 0.0;

        foreach ($productos as $p) {
            $stock = (float) $p->stock_actual;
            $minimo = (float) $p->stock_minimo;
            $costo = (float) $p->costo;

            if ($stock < 0) {
                $totalDeficit++;
            } elseif ($stock == 0.0) {
                $totalAgotados++;
            } else {
                $totalBajoMinimo++;
            }

            $faltante = max(0.0, $minimo - $stock);
            $unidadesFaltantesTotal += $faltante;
            $inversionEstimadaTotal += round($faltante * $costo, 2);
        }

        $totales = [
            'total_alertas'            => $productos->count(),
            'total_deficit'            => $totalDeficit,
            'total_agotados'           => $totalAgotados,
            'total_bajo_minimo'        => $totalBajoMinimo,
            'unidades_faltantes_total' => $unidadesFaltantesTotal,
            'inversion_estimada_total' => $inversionEstimadaTotal,
        ];

        $company = $this->prepareCompanyData($companyData);
        $base64Logo = $this->getCompanyLogoBase64();
        $fechaGeneracion = Carbon::now();

        $pdf = Pdf::loadView('pdf.inventario_alertas_reporte', [
            'productos'       => $productos,
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
     * Crea un token de enlace corto (24 horas) para el Reporte de Inventario solicitado.
     */
    public function generarTokenReporte(
        string $tipoReporte,
        array $filters = [],
        array $companyData = [],
        ?string $usuarioName = null,
        ?int $userId = null
    ): string {
        $token = Str::random(40);

        $mappedType = match (strtolower(trim($tipoReporte))) {
            'kardex', 'movimientos' => 'inventario_kardex_reporte',
            'alertas', 'reposicion' => 'inventario_alertas_reporte',
            default                 => 'inventario_existencias_reporte',
        };

        Cache::put("short_link_{$token}", [
            'type'        => $mappedType,
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

