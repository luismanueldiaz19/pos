<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Existencias y Valorización</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        @page {
            margin: 0px;
            size: letter landscape;
        }
        body {
            font-family: Arial, Helvetica, sans-serif;
            color: #1e293b;
            font-size: 11px;
            background: #ffffff;
            margin: 0;
            padding: 28px 32px 75px 32px;
        }
        .main-document-flow {
            width: 100%;
        }

        /* ── INFORMACIÓN DEL REPORTE Y FILTROS ── */
        .meta-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 6px;
            margin-bottom: 16px;
        }
        .meta-left {
            width: 55%;
            vertical-align: top;
            padding-right: 20px;
        }
        .meta-right {
            width: 45%;
            vertical-align: top;
            padding-left: 10px;
        }
        .meta-title {
            font-size: 14px;
            font-weight: 800;
            color: #1e2e4a;
            margin-bottom: 4px;
        }
        .meta-line {
            font-size: 11px;
            color: #475569;
            line-height: 1.5;
        }
        .meta-label {
            color: #64748b;
        }

        /* ── TABLA DE REPORTE ── */
        .report-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 10px;
            margin-bottom: 16px;
        }
        .report-table th {
            background-color: #1e2e4a;
            color: #ffffff;
            font-size: 10.5px;
            font-weight: 700;
            padding: 8px 8px;
            text-align: left;
            border: none;
        }
        .report-table th.c, .report-table td.c {
            text-align: center;
        }
        .report-table th.r, .report-table td.r {
            text-align: right;
        }
        .report-table td {
            padding: 6px 8px;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
            vertical-align: middle;
        }
        .report-table tr:nth-child(even) td {
            background-color: #f8fafc;
        }

        /* ── BADGES STOCK ── */
        .badge-stock {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 9px;
            font-weight: 700;
        }
        .badge-stock-normal {
            background-color: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
        }
        .badge-stock-alerta {
            background-color: #fffbeb;
            color: #b45309;
            border: 1px solid #fde68a;
        }
        .badge-stock-deficit {
            background-color: #fef2f2;
            color: #b91c1c;
            border: 1px solid #fecaca;
        }

        /* ── TOTALES Y RESUMEN INFERIOR ── */
        .summary-section {
            width: 100%;
            border-collapse: collapse;
            margin-top: 6px;
            margin-bottom: 16px;
        }
        .summary-left {
            width: 55%;
            vertical-align: top;
            padding-right: 25px;
        }
        .summary-right {
            width: 45%;
            vertical-align: top;
            padding-left: 10px;
        }
        .summary-title {
            font-size: 13px;
            font-weight: 800;
            color: #1e2e4a;
            margin-bottom: 4px;
        }
        .summary-desc {
            font-size: 10.5px;
            color: #64748b;
            line-height: 1.5;
        }
        .invoice-totals-table {
            width: 100%;
            border-collapse: collapse;
        }
        .invoice-totals-table td {
            padding: 5px 8px;
            font-size: 11.5px;
        }
        .invoice-totals-table td.lbl {
            color: #475569;
            font-weight: 600;
            text-align: left;
        }
        .invoice-totals-table td.val {
            color: #1e293b;
            font-weight: 700;
            text-align: right;
        }
        .totals-highlight {
            background-color: #f1f5f9;
        }
        .totals-highlight td.lbl {
            font-size: 13px;
            font-weight: 900;
            color: #1e2e4a;
            padding: 7px 8px;
        }
        .totals-highlight td.val {
            font-size: 14.5px;
            font-weight: 900;
            color: #047857;
            padding: 7px 8px;
        }
    </style>
</head>
<body>
    <div class="main-document-flow">
        <!-- 1. ENCABEZADO GEOMÉTRICO -->
        @include('pdf.components.header_banner', [
            'titulo'          => 'EXISTENCIAS Y VALORIZACIÓN',
            'subtitulo'       => 'Inventario Físico de Productos y Valorización Monetaria de Almacén',
            'numeroDocumento' => count($productos) . ' productos',
            'company'         => $company ?? [],
            'base64Logo'      => $base64Logo ?? null,
            'emisorNombre'    => 'Generado por: ' . ($usuarioName ?? 'Administrador'),
            'emisorTelefono'  => $company['telefono'] ?? config('company.telefono', '(809) 697-8028'),
            'emisorEmail'     => '---',
        ])

        <!-- 2. INFORMACIÓN DEL REPORTE Y FILTROS -->
        <table class="meta-table">
            <tr>
                <td class="meta-left">
                    <div class="meta-title">Inventario General Valorizado</div>
                    <div class="meta-line">
                        <span class="meta-label">Total Ítems Inventariables:</span>
                        <strong>{{ number_format($totales['total_items'] ?? 0) }}</strong>
                    </div>
                    <div class="meta-line">
                        <span class="meta-label">Fecha de corte / emisión:</span>
                        {{ \Carbon\Carbon::now()->format('d/m/Y h:i A') }}
                    </div>
                </td>
                <td class="meta-right">
                    <div class="meta-title">Criterios de consulta:</div>
                    @if(!empty($filters['categoria_id']))
                        <div class="meta-line">
                            <span class="meta-label">Categoría ID:</span>
                            <strong>#{{ $filters['categoria_id'] }}</strong>
                        </div>
                    @else
                        <div class="meta-line">
                            <span class="meta-label">Categorías:</span>
                            <strong>Todas las categorías</strong>
                        </div>
                    @endif
                    @if(!empty($filters['search']))
                        <div class="meta-line">
                            <span class="meta-label">Búsqueda aplicada:</span>
                            <strong>"{{ $filters['search'] }}"</strong>
                        </div>
                    @else
                        <div class="meta-line">
                            <span class="meta-label">Alcance:</span>
                            Productos activos con control de existencias
                        </div>
                    @endif
                </td>
            </tr>
        </table>

        <!-- 3. TABLA DE EXISTENCIAS -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 8%;">Código</th>
                    <th style="width: 25%;">Producto</th>
                    <th style="width: 14%;">Categoría</th>
                    <th style="width: 7%;" class="c">U.M.</th>
                    <th style="width: 9%;" class="c">Stock Actual</th>
                    <th style="width: 7%;" class="r">Mínimo</th>
                    <th style="width: 9%;" class="r">Costo Unit.</th>
                    <th style="width: 11%;" class="r">Valor Costo RD$</th>
                    <th style="width: 10%;" class="r">Valor Venta RD$</th>
                </tr>
            </thead>
            <tbody>
                @forelse($productos as $p)
                @php
                    $stock = (float) $p->stock_actual;
                    $minimo = (float) $p->stock_minimo;
                    $costo = (float) $p->costo;
                    $precio = (float) $p->precio_venta;
                    $valorCosto = round($stock * $costo, 2);
                    $valorVenta = round($stock * $precio, 2);

                    $badgeClass = 'badge-stock-normal';
                    $badgeText = number_format($stock, 1);
                    if ($stock < 0) {
                        $badgeClass = 'badge-stock-deficit';
                        $badgeText = number_format($stock, 1) . ' (Déficit)';
                    } elseif ($stock == 0) {
                        $badgeClass = 'badge-stock-deficit';
                        $badgeText = '0.0 (Agotado)';
                    } elseif ($stock <= $minimo) {
                        $badgeClass = 'badge-stock-alerta';
                        $badgeText = number_format($stock, 1) . ' (Bajo)';
                    }
                @endphp
                <tr>
                    <td><strong>{{ $p->codigo ?? ('#' . $p->id) }}</strong></td>
                    <td><strong>{{ $p->nombre }}</strong></td>
                    <td>{{ $p->categoria->nombre ?? '--' }}</td>
                    <td class="c">{{ $p->unidadMedida->nombre ?? 'un.' }}</td>
                    <td class="c">
                        <span class="badge-stock {{ $badgeClass }}">{{ $badgeText }}</span>
                    </td>
                    <td class="r">{{ number_format($minimo, 1) }}</td>
                    <td class="r">RD$ {{ number_format($costo, 2) }}</td>
                    <td class="r" style="font-weight: 700; color: #1e2e4a;">RD$ {{ number_format($valorCosto, 2) }}</td>
                    <td class="r" style="color: #047857; font-weight: 700;">RD$ {{ number_format($valorVenta, 2) }}</td>
                </tr>
                @empty
                <tr>
                    <td colspan="9" style="text-align: center; padding: 20px; color: #94a3b8;">
                        No se encontraron productos registrados en inventario para los filtros seleccionados.
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>

        <!-- 4. TOTALES Y DESGLOSE POR CATEGORÍA -->
        <table class="summary-section">
            <tr>
                <!-- COLUMNA IZQUIERDA: DESGLOSE POR CATEGORÍA -->
                <td class="summary-left">
                    <div class="summary-title">Desglose por Categoría</div>
                    <div class="summary-desc">
                        Distribución de existencias y valorización según clasificación del catálogo.
                    </div>

                    @if(!empty($desgloseCategorias) && count($desgloseCategorias) > 0)
                    <div style="margin-top: 10px; padding-top: 8px; border-top: 1px dashed #cbd5e1;">
                        <table style="width: 100%; border-collapse: collapse; font-size: 10px;">
                            <thead>
                                <tr style="border-bottom: 1px solid #e2e8f0; color: #64748b; font-weight: 700;">
                                    <th style="text-align: left; padding: 3px 0;">Categoría</th>
                                    <th style="text-align: center; padding: 3px 0;">Ítems</th>
                                    <th style="text-align: right; padding: 3px 0;">Unidades</th>
                                    <th style="text-align: right; padding: 3px 0;">Valor Costo</th>
                                    <th style="text-align: right; padding: 3px 0;">% Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($desgloseCategorias as $cat)
                                @php
                                    $pct = ($totales['valor_total_costo'] ?? 0) > 0
                                        ? (($cat->valor_costo / $totales['valor_total_costo']) * 100)
                                        : 0;
                                @endphp
                                <tr>
                                    <td style="padding: 4px 0; font-weight: 700; color: #334155;">{{ $cat->categoria }}</td>
                                    <td style="padding: 4px 0; text-align: center; color: #64748b;">{{ $cat->cantidad_items }}</td>
                                    <td style="padding: 4px 0; text-align: right; color: #334155;">{{ number_format($cat->unidades, 1) }}</td>
                                    <td style="padding: 4px 0; text-align: right; font-weight: 700; color: #1e2e4a;">RD$ {{ number_format($cat->valor_costo, 2) }}</td>
                                    <td style="padding: 4px 0; text-align: right; color: #64748b;">{{ number_format($pct, 1) }}%</td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                    @endif
                </td>

                <!-- COLUMNA DERECHA: GRANDES TOTALES -->
                <td class="summary-right">
                    <table class="invoice-totals-table">
                        <tr>
                            <td class="lbl">Total Ítems Inventariados</td>
                            <td class="val">{{ number_format($totales['total_items'] ?? 0) }} productos</td>
                        </tr>
                        <tr>
                            <td class="lbl">Unidades Totales en Almacén</td>
                            <td class="val">{{ number_format($totales['total_unidades'] ?? 0, 1) }} unidades</td>
                        </tr>
                        <tr>
                            <td class="lbl">Productos en Alerta / Déficit</td>
                            <td class="val" style="color: {{ ($totales['items_bajo_minimo'] ?? 0) > 0 ? '#b91c1c' : '#047857' }};">
                                {{ number_format($totales['items_bajo_minimo'] ?? 0) }}
                            </td>
                        </tr>
                        <tr>
                            <td class="lbl">Valorización Total a Precio Venta</td>
                            <td class="val" style="color: #047857;">RD$ {{ number_format($totales['valor_total_venta'] ?? 0, 2) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl">Margen Bruto Estimado</td>
                            <td class="val">{{ number_format($totales['margen_estimado'] ?? 0, 1) }}%</td>
                        </tr>
                        <tr class="totals-highlight">
                            <td class="lbl">VALORIZACIÓN TOTAL A COSTO</td>
                            <td class="val">RD$ {{ number_format($totales['valor_total_costo'] ?? 0, 2) }}</td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>

        <!-- 5. BANNER INFERIOR SUAVE (FOOTER) -->
        @include('pdf.components.footer_banner', [
            'company' => $company ?? [],
        ])
    </div>
</body>
</html>

