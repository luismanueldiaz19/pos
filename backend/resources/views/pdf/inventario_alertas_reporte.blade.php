<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Alertas de Reposición y Déficit</title>
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

        /* ── BADGES PRIORIDAD ── */
        .badge-prioridad {
            display: inline-block;
            padding: 2px 7px;
            border-radius: 4px;
            font-size: 9px;
            font-weight: 700;
            text-transform: uppercase;
        }
        .badge-prioridad-deficit {
            background-color: #fef2f2;
            color: #991b1b;
            border: 1px solid #f87171;
        }
        .badge-prioridad-agotado {
            background-color: #fff1f2;
            color: #e11d48;
            border: 1px solid #fecdd3;
        }
        .badge-prioridad-bajo {
            background-color: #fffbeb;
            color: #b45309;
            border: 1px solid #fde68a;
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
            background-color: #fef2f2;
        }
        .totals-highlight td.lbl {
            font-size: 13px;
            font-weight: 900;
            color: #991b1b;
            padding: 7px 8px;
        }
        .totals-highlight td.val {
            font-size: 14.5px;
            font-weight: 900;
            color: #991b1b;
            padding: 7px 8px;
        }
    </style>
</head>
<body>
    <div class="main-document-flow">
        <!-- 1. ENCABEZADO GEOMÉTRICO -->
        @include('pdf.components.header_banner', [
            'titulo'          => 'ALERTAS Y REPOSICIÓN DE STOCK',
            'subtitulo'       => 'Productos con Existencias en Déficit o por Debajo del Stock Mínimo',
            'numeroDocumento' => count($productos) . ' alertas',
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
                    <div class="meta-title">Planificación de Reabastecimiento</div>
                    <div class="meta-line">
                        <span class="meta-label">Total Ítems en Alerta:</span>
                        <strong style="color: #b91c1c;">{{ number_format($totales['total_alertas'] ?? 0) }} productos</strong>
                    </div>
                    <div class="meta-line">
                        <span class="meta-label">Fecha de corte:</span>
                        {{ \Carbon\Carbon::now()->format('d/m/Y h:i A') }}
                    </div>
                </td>
                <td class="meta-right">
                    <div class="meta-title">Criterios de consulta:</div>
                    @if(!empty($filters['estado_alerta']))
                        <div class="meta-line">
                            <span class="meta-label">Filtro de severidad:</span>
                            <strong>{{ strtoupper($filters['estado_alerta']) }}</strong>
                        </div>
                    @else
                        <div class="meta-line">
                            <span class="meta-label">Alcance:</span>
                            Todos los productos con existencias ≤ stock mínimo
                        </div>
                    @endif
                    @if(!empty($filters['search']))
                        <div class="meta-line">
                            <span class="meta-label">Búsqueda aplicada:</span>
                            <strong>"{{ $filters['search'] }}"</strong>
                        </div>
                    @endif
                </td>
            </tr>
        </table>

        <!-- 3. TABLA DE ALERTAS -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 8%;">Código</th>
                    <th style="width: 24%;">Producto</th>
                    <th style="width: 14%;">Categoría</th>
                    <th style="width: 7%;" class="c">U.M.</th>
                    <th style="width: 8%;" class="r">Stock Actual</th>
                    <th style="width: 7%;" class="r">Mínimo</th>
                    <th style="width: 9%;" class="r">A Reponer</th>
                    <th style="width: 9%;" class="r">Costo Unit.</th>
                    <th style="width: 10%;" class="r">Inversión Estimada</th>
                    <th style="width: 11%;" class="c">Severidad</th>
                </tr>
            </thead>
            <tbody>
                @forelse($productos as $p)
                @php
                    $stock = (float) $p->stock_actual;
                    $minimo = (float) $p->stock_minimo;
                    $costo = (float) $p->costo;
                    $faltante = max(0.0, $minimo - $stock);
                    $inversion = round($faltante * $costo, 2);

                    if ($stock < 0) {
                        $prioridadClass = 'badge-prioridad-deficit';
                        $prioridadText = 'DÉFICIT CRÍTICO';
                    } elseif ($stock == 0.0) {
                        $prioridadClass = 'badge-prioridad-agotado';
                        $prioridadText = 'AGOTADO (0)';
                    } else {
                        $prioridadClass = 'badge-prioridad-bajo';
                        $prioridadText = 'BAJO MÍNIMO';
                    }
                @endphp
                <tr>
                    <td><strong>{{ $p->codigo ?? ('#' . $p->id) }}</strong></td>
                    <td><strong>{{ $p->nombre }}</strong></td>
                    <td>{{ $p->categoria->nombre ?? '--' }}</td>
                    <td class="c">{{ $p->unidadMedida->nombre ?? 'un.' }}</td>
                    <td class="r" style="font-weight: 700; color: {{ $stock < 0 ? '#b91c1c' : ($stock == 0 ? '#e11d48' : '#b45309') }};">
                        {{ number_format($stock, 1) }}
                    </td>
                    <td class="r">{{ number_format($minimo, 1) }}</td>
                    <td class="r" style="font-weight: 700; color: #b91c1c;">
                        +{{ number_format($faltante, 1) }}
                    </td>
                    <td class="r">RD$ {{ number_format($costo, 2) }}</td>
                    <td class="r" style="font-weight: 700; color: #1e2e4a;">
                        RD$ {{ number_format($inversion, 2) }}
                    </td>
                    <td class="c">
                        <span class="badge-prioridad {{ $prioridadClass }}">{{ $prioridadText }}</span>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="10" style="text-align: center; padding: 20px; color: #94a3b8;">
                        ¡Excelente! No hay productos en déficit o bajo stock mínimo según los filtros aplicados.
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>

        <!-- 4. TOTALES Y RESUMEN INFERIOR -->
        <table class="summary-section">
            <tr>
                <!-- COLUMNA IZQUIERDA: RESUMEN DE SEVERIDAD -->
                <td class="summary-left">
                    <div class="summary-title">Desglose de Criticidad</div>
                    <div class="summary-desc">
                        Clasificación de productos que requieren reposición prioritaria para evitar desabastecimiento.
                    </div>

                    <div style="margin-top: 10px; padding-top: 8px; border-top: 1px dashed #cbd5e1;">
                        <table style="width: 90%; border-collapse: collapse; font-size: 10.5px;">
                            <tr>
                                <td style="padding: 4px 0; font-weight: 700; color: #991b1c; width: 60%;">
                                    <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background-color: #991b1c; margin-right: 5px;"></span>
                                    Déficit Crítico (Stock Negativo)
                                </td>
                                <td style="padding: 4px 0; text-align: right; font-weight: 700; color: #991b1c; width: 40%;">
                                    {{ $totales['total_deficit'] ?? 0 }} productos
                                </td>
                            </tr>
                            <tr>
                                <td style="padding: 4px 0; font-weight: 700; color: #e11d48; width: 60%;">
                                    <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background-color: #e11d48; margin-right: 5px;"></span>
                                    Completamente Agotados (Stock 0)
                                </td>
                                <td style="padding: 4px 0; text-align: right; font-weight: 700; color: #e11d48; width: 40%;">
                                    {{ $totales['total_agotados'] ?? 0 }} productos
                                </td>
                            </tr>
                            <tr>
                                <td style="padding: 4px 0; font-weight: 700; color: #b45309; width: 60%;">
                                    <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background-color: #b45309; margin-right: 5px;"></span>
                                    Bajo Stock Mínimo Establecido
                                </td>
                                <td style="padding: 4px 0; text-align: right; font-weight: 700; color: #b45309; width: 40%;">
                                    {{ $totales['total_bajo_minimo'] ?? 0 }} productos
                                </td>
                            </tr>
                        </table>
                    </div>
                </td>

                <!-- COLUMNA DERECHA: TOTALES -->
                <td class="summary-right">
                    <table class="invoice-totals-table">
                        <tr>
                            <td class="lbl">Total Productos en Alerta</td>
                            <td class="val">{{ number_format($totales['total_alertas'] ?? 0) }} ítems</td>
                        </tr>
                        <tr>
                            <td class="lbl">Unidades Faltantes Estimadas</td>
                            <td class="val" style="color: #b91c1c;">+{{ number_format($totales['unidades_faltantes_total'] ?? 0, 1) }} un.</td>
                        </tr>
                        <tr class="totals-highlight">
                            <td class="lbl">INVERSIÓN ESTIMADA REQUERIDA</td>
                            <td class="val">RD$ {{ number_format($totales['inversion_estimada_total'] ?? 0, 2) }}</td>
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

