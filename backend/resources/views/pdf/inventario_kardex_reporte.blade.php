<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Movimientos de Inventario</title>
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

        /* ── BADGES MOVIMIENTO ── */
        .badge-mov {
            display: inline-block;
            padding: 2px 7px;
            border-radius: 4px;
            font-size: 9px;
            font-weight: 700;
            text-transform: uppercase;
        }
        .badge-mov-entrada {
            background-color: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
        }
        .badge-mov-salida {
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
            padding: 7px 8px;
        }
    </style>
</head>
<body>
    <div class="main-document-flow">
        <!-- 1. ENCABEZADO GEOMÉTRICO -->
        @include('pdf.components.header_banner', [
            'titulo'          => 'MOVIMIENTOS DE INVENTARIO',
            'subtitulo'       => 'Trazabilidad de Entradas, Salidas y Ajustes de Stock',
            'numeroDocumento' => count($movimientos) . ' movimientos',
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
                    <div class="meta-title">Historial de Operaciones de Stock</div>
                    <div class="meta-line">
                        <span class="meta-label">Período evaluado:</span>
                        @if(!empty($filters['fecha_desde']) && !empty($filters['fecha_hasta']))
                            <strong>{{ \Carbon\Carbon::parse($filters['fecha_desde'])->format('d/m/Y') }}</strong> al <strong>{{ \Carbon\Carbon::parse($filters['fecha_hasta'])->format('d/m/Y') }}</strong>
                        @elseif(!empty($filters['fecha_desde']))
                            Desde <strong>{{ \Carbon\Carbon::parse($filters['fecha_desde'])->format('d/m/Y') }}</strong>
                        @elseif(!empty($filters['fecha_hasta']))
                            Hasta <strong>{{ \Carbon\Carbon::parse($filters['fecha_hasta'])->format('d/m/Y') }}</strong>
                        @else
                            <strong>Histórico Completo</strong>
                        @endif
                    </div>
                    <div class="meta-line">
                        <span class="meta-label">Fecha de emisión:</span>
                        {{ \Carbon\Carbon::now()->format('d/m/Y h:i A') }}
                    </div>
                </td>
                <td class="meta-right">
                    <div class="meta-title">Criterios de consulta:</div>
                    <div class="meta-line">
                        <span class="meta-label">Tipo de movimiento:</span>
                        <strong>{{ !empty($filters['tipo']) && strtoupper($filters['tipo']) !== 'TODOS' ? strtoupper($filters['tipo']) : 'TODOS (ENTRADAS Y SALIDAS)' }}</strong>
                    </div>
                    @if(!empty($filters['search']))
                        <div class="meta-line">
                            <span class="meta-label">Búsqueda aplicada:</span>
                            <strong>"{{ $filters['search'] }}"</strong>
                        </div>
                    @else
                        <div class="meta-line">
                            <span class="meta-label">Alcance:</span>
                            Registro cronológico de operaciones de inventario
                        </div>
                    @endif
                </td>
            </tr>
        </table>

        <!-- 3. TABLA DE MOVIMIENTOS -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 12%;">Fecha y Hora</th>
                    <th style="width: 9%;">Código</th>
                    <th style="width: 25%;">Producto</th>
                    <th style="width: 14%;">Categoría</th>
                    <th style="width: 10%;" class="c">Movimiento</th>
                    <th style="width: 10%;" class="r">Cantidad</th>
                    <th style="width: 20%;">Referencia / Motivo</th>
                </tr>
            </thead>
            <tbody>
                @forelse($movimientos as $m)
                @php
                    $isEntrada = strtoupper((string)$m->tipo) === 'ENTRADA';
                    $fechaStr = $m->fecha ? \Carbon\Carbon::parse($m->fecha)->format('d/m/Y h:i A') : '--';
                    $prodCodigo = $m->producto->codigo ?? ('#' . $m->producto_id);
                    $prodNombre = $m->producto->nombre ?? ('Producto #' . $m->producto_id);
                    $categoria = $m->producto->categoria->nombre ?? '--';
                    $cant = (float) $m->cantidad;
                @endphp
                <tr>
                    <td>{{ $fechaStr }}</td>
                    <td><strong>{{ $prodCodigo }}</strong></td>
                    <td><strong>{{ $prodNombre }}</strong></td>
                    <td>{{ $categoria }}</td>
                    <td class="c">
                        <span class="badge-mov {{ $isEntrada ? 'badge-mov-entrada' : 'badge-mov-salida' }}">
                            {{ $isEntrada ? 'ENTRADA (+)' : 'SALIDA (-)' }}
                        </span>
                    </td>
                    <td class="r" style="font-weight: 700; color: {{ $isEntrada ? '#047857' : '#b91c1c' }};">
                        {{ $isEntrada ? '+' : '-' }}{{ number_format($cant, 1) }}
                    </td>
                    <td>{{ $m->referencia ?? '--' }}</td>
                </tr>
                @empty
                <tr>
                    <td colspan="7" style="text-align: center; padding: 20px; color: #94a3b8;">
                        No se registraron movimientos de inventario para los filtros aplicados.
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>

        <!-- 4. TOTALES AGRUPADOS -->
        <table class="summary-section">
            <tr>
                <!-- COLUMNA IZQUIERDA: RESUMEN DE FLUJO -->
                <td class="summary-left">
                    <div class="summary-title">Balance de Flujo de Inventario</div>
                    <div class="summary-desc">
                        Consolidado de entradas y salidas de mercancías en el intervalo evaluado.
                    </div>

                    <div style="margin-top: 10px; padding-top: 8px; border-top: 1px dashed #cbd5e1;">
                        <table style="width: 90%; border-collapse: collapse; font-size: 10.5px;">
                            <tr>
                                <td style="padding: 4px 0; font-weight: 700; color: #047857; width: 45%;">
                                    <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background-color: #047857; margin-right: 5px;"></span>
                                    Total Entradas (Compras/Ajustes +)
                                </td>
                                <td style="padding: 4px 0; text-align: right; color: #64748b; width: 25%;">
                                    {{ $totales['cant_entradas'] ?? 0 }} registros
                                </td>
                                <td style="padding: 4px 0; text-align: right; font-weight: 700; color: #047857; width: 30%;">
                                    +{{ number_format($totales['total_entradas'] ?? 0, 1) }} un.
                                </td>
                            </tr>
                            <tr>
                                <td style="padding: 4px 0; font-weight: 700; color: #b91c1c;">
                                    <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background-color: #b91c1c; margin-right: 5px;"></span>
                                    Total Salidas (Ventas/Ajustes -)
                                </td>
                                <td style="padding: 4px 0; text-align: right; color: #64748b;">
                                    {{ $totales['cant_salidas'] ?? 0 }} registros
                                </td>
                                <td style="padding: 4px 0; text-align: right; font-weight: 700; color: #b91c1c;">
                                    -{{ number_format($totales['total_salidas'] ?? 0, 1) }} un.
                                </td>
                            </tr>
                        </table>
                    </div>
                </td>

                <!-- COLUMNA DERECHA: TOTALES -->
                <td class="summary-right">
                    <table class="invoice-totals-table">
                        <tr>
                            <td class="lbl">Total Operaciones Registradas</td>
                            <td class="val">{{ number_format($totales['total_movimientos'] ?? 0) }} transacciones</td>
                        </tr>
                        <tr>
                            <td class="lbl">Unidades Ingresadas</td>
                            <td class="val" style="color: #047857;">+{{ number_format($totales['total_entradas'] ?? 0, 1) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl">Unidades Egresadas</td>
                            <td class="val" style="color: #b91c1c;">-{{ number_format($totales['total_salidas'] ?? 0, 1) }}</td>
                        </tr>
                        <tr class="totals-highlight">
                            <td class="lbl">SALDO NETO DEL PERÍODO</td>
                            <td class="val" style="color: {{ ($totales['saldo_neto'] ?? 0) >= 0 ? '#047857' : '#b91c1c' }};">
                                {{ ($totales['saldo_neto'] ?? 0) >= 0 ? '+' : '' }}{{ number_format($totales['saldo_neto'] ?? 0, 1) }} unidades
                            </td>
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

