<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Compras</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            color: #1e293b;
            font-size: 11px;
            background: #ffffff;
            line-height: 1.4;
        }
        .page {
            padding: 24px 30px;
        }

        /* ── HEADER BANNER ── */
        .top-band {
            background: #1a2b4a;
            color: #ffffff;
            padding: 16px 20px;
            border-radius: 8px 8px 0 0;
        }
        .top-band-inner {
            width: 100%;
        }
        .top-band-inner td {
            vertical-align: middle;
        }
        .company-name {
            font-size: 20px;
            font-weight: 900;
            letter-spacing: 1px;
            color: #ffffff;
        }
        .company-sub {
            font-size: 10.5px;
            color: #cbd5e1;
            margin-top: 3px;
            line-height: 1.4;
        }
        .report-badge {
            text-align: right;
        }
        .report-badge .label {
            font-size: 10px;
            color: #94a3b8;
            text-transform: uppercase;
            letter-spacing: 1.5px;
        }
        .report-badge .title {
            font-size: 20px;
            font-weight: 900;
            color: #ffffff;
            margin-top: 2px;
        }
        .report-badge .date {
            font-size: 10px;
            color: #cbd5e1;
            margin-top: 3px;
        }

        /* ── FILTER META ROW ── */
        .filter-row {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-top: none;
            padding: 10px 20px;
            margin-bottom: 16px;
            border-radius: 0 0 8px 8px;
        }
        .filter-table {
            width: 100%;
        }
        .filter-table td {
            font-size: 10.5px;
            color: #64748b;
            padding: 2px 0;
        }
        .filter-table td strong {
            color: #0f172a;
        }

        /* ── KPI METRICS CARDS ── */
        .kpi-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 8px 0;
            margin-bottom: 16px;
        }
        .kpi-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 10px 14px;
            text-align: left;
            vertical-align: middle;
        }
        .kpi-card.highlight {
            background: #eff6ff;
            border-color: #bfdbfe;
        }
        .kpi-label {
            font-size: 9px;
            font-weight: 700;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .kpi-value {
            font-size: 15px;
            font-weight: 800;
            color: #0f172a;
            margin-top: 2px;
        }
        .kpi-value.primary {
            color: #2563eb;
        }
        .kpi-value.success {
            color: #059669;
        }
        .kpi-value.warning {
            color: #d97706;
        }

        /* ── ITEMS TABLE ── */
        .report-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 8px;
            font-size: 10px;
        }
        .report-table th {
            background: #334155;
            color: #ffffff;
            font-size: 9.5px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 8px 8px;
            text-align: left;
            border-top: 1px solid #334155;
            border-bottom: 1px solid #334155;
        }
        .report-table th.r,
        .report-table td.r {
            text-align: right;
        }
        .report-table th.c,
        .report-table td.c {
            text-align: center;
        }
        .report-table td {
            padding: 7px 8px;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
            vertical-align: middle;
        }
        .report-table tr:nth-child(even) td {
            background-color: #f8fafc;
        }

        /* ── BADGES ── */
        .status-badge {
            display: inline-block;
            padding: 2px 7px;
            border-radius: 4px;
            font-size: 8.5px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }
        .badge-pagada {
            background: #dcfce7;
            color: #15803d;
            border: 1px solid #bbf7d0;
        }
        .badge-pendiente {
            background: #fef3c7;
            color: #b45309;
            border: 1px solid #fde68a;
        }
        .badge-anulada {
            background: #fee2e2;
            color: #b91c1c;
            border: 1px solid #fecaca;
        }

        /* ── TOTALS FOOTER ROW ── */
        .totals-row td {
            background: #f1f5f9 !important;
            font-weight: 800;
            font-size: 10.5px;
            color: #0f172a;
            border-top: 2px solid #cbd5e1;
            border-bottom: 2px solid #cbd5e1;
            padding: 9px 8px;
        }

        /* ── FOOTER ── */
        .footer {
            margin-top: 24px;
            padding-top: 10px;
            border-top: 1px solid #e2e8f0;
            text-align: center;
            font-size: 9.5px;
            color: #94a3b8;
        }
    </style>
</head>
<body>
    <div class="page">
        <!-- CABECERA PRINCIPAL -->
        <div class="top-band">
            <table class="top-band-inner">
                <tr>
                    <td style="width: 60%;">
                        @if(!empty($base64Logo))
                            <img src="{{ $base64Logo }}" style="max-height: 48px; margin-bottom: 6px;" alt="Logo"><br>
                        @endif
                        <div class="company-name">{{ $company['nombre'] }}</div>
                        <div class="company-sub">
                            RNC: {{ $company['rnc'] }} &nbsp;|&nbsp; Tel: {{ $company['telefono'] }}<br>
                            {{ $company['direccion'] }}
                        </div>
                    </td>
                    <td style="width: 40%;" class="report-badge">
                        <div class="label">Módulo de Compras</div>
                        <div class="title">REPORTE DE COMPRAS</div>
                        <div class="date">
                            Emisión: {{ $fechaGeneracion->format('d/m/Y h:i A') }}<br>
                            Usuario: {{ $usuarioName }}
                        </div>
                    </td>
                </tr>
            </table>
        </div>

        <!-- FILTROS APLICADOS -->
        <div class="filter-row">
            <table class="filter-table">
                <tr>
                    <td style="width: 35%;">
                        <strong>Período:</strong> 
                        @if(!empty($filters['fecha_desde']) && !empty($filters['fecha_hasta']))
                            {{ \Carbon\Carbon::parse($filters['fecha_desde'])->format('d/m/Y') }} al {{ \Carbon\Carbon::parse($filters['fecha_hasta'])->format('d/m/Y') }}
                        @elseif(!empty($filters['fecha_desde']))
                            Desde {{ \Carbon\Carbon::parse($filters['fecha_desde'])->format('d/m/Y') }}
                        @elseif(!empty($filters['fecha_hasta']))
                            Hasta {{ \Carbon\Carbon::parse($filters['fecha_hasta'])->format('d/m/Y') }}
                        @else
                            Histórico Completo (Todas las fechas)
                        @endif
                    </td>
                    <td style="width: 30%;">
                        <strong>Estado:</strong> 
                        {{ !empty($filters['estado']) && strtolower($filters['estado']) !== 'todos' ? strtoupper($filters['estado']) : 'TODOS' }}
                    </td>
                    <td style="width: 35%;">
                        @if(!empty($filters['search']))
                            <strong>Criterio de Búsqueda:</strong> "{{ $filters['search'] }}"
                        @else
                            <strong>Tipo de Compra:</strong> 
                            {{ !empty($filters['tipo_compra']) && strtolower($filters['tipo_compra']) !== 'todos' ? strtoupper($filters['tipo_compra']) : 'TODAS' }}
                        @endif
                    </td>
                </tr>
            </table>
        </div>

        <!-- TARJETAS DE RESUMEN KPI -->
        <table class="kpi-table">
            <tr>
                <td class="kpi-card highlight" style="width: 25%;">
                    <div class="kpi-label">TOTAL FACTURAS</div>
                    <div class="kpi-value primary">{{ $totales['cantidad'] }}</div>
                </td>
                <td class="kpi-card" style="width: 25%;">
                    <div class="kpi-label">MONTO TOTAL COMPRAS</div>
                    <div class="kpi-value">RD$ {{ number_format($totales['total_compras'], 2) }}</div>
                </td>
                <td class="kpi-card" style="width: 25%;">
                    <div class="kpi-label">TOTAL PAGADO</div>
                    <div class="kpi-value success">RD$ {{ number_format($totales['total_pagado'], 2) }}</div>
                </td>
                <td class="kpi-card" style="width: 25%;">
                    <div class="kpi-label">TOTAL PENDIENTE</div>
                    <div class="kpi-value warning">RD$ {{ number_format($totales['total_pendiente'], 2) }}</div>
                </td>
            </tr>
        </table>

        <!-- TABLA DE ARTICULOS / COMPRAS -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 4%;" class="c">#</th>
                    <th style="width: 9%;">FECHA</th>
                    <th style="width: 12%;">FACTURA PROV.</th>
                    <th style="width: 13%;">NCF</th>
                    <th style="width: 24%;">PROVEEDOR</th>
                    <th style="width: 8%;" class="c">TIPO</th>
                    <th style="width: 8%;" class="c">ESTADO</th>
                    <th style="width: 11%;" class="r">SUBTOTAL</th>
                    <th style="width: 11%;" class="r">TOTAL RD$</th>
                </tr>
            </thead>
            <tbody>
                @forelse($compras as $index => $compra)
                <tr>
                    <td class="c" style="color: #64748b;">{{ $index + 1 }}</td>
                    <td>{{ \Carbon\Carbon::parse($compra->fecha_compra)->format('d/m/Y') }}</td>
                    <td><strong>{{ $compra->numero_factura_proveedor ?: 'S/N' }}</strong></td>
                    <td style="color: #475569;">{{ $compra->ncf ?: 'N/A' }}</td>
                    <td>
                        <strong>{{ $compra->proveedor->nombre ?? 'Desconocido' }}</strong>
                        @if(!empty($compra->proveedor->rnc_cedula))
                            <span style="font-size: 8.5px; color: #64748b;">({{ $compra->proveedor->rnc_cedula }})</span>
                        @endif
                    </td>
                    <td class="c">
                        <span style="font-size: 9px; font-weight: 600;">{{ $compra->tipo_compra }}</span>
                    </td>
                    <td class="c">
                        @php
                            $estado = strtoupper($compra->estado);
                            $badgeClass = 'badge-pendiente';
                            if ($estado === 'PAGADA') $badgeClass = 'badge-pagada';
                            elseif ($estado === 'ANULADA') $badgeClass = 'badge-anulada';
                        @endphp
                        <span class="status-badge {{ $badgeClass }}">{{ $estado }}</span>
                    </td>
                    <td class="r">RD$ {{ number_format($compra->subtotal, 2) }}</td>
                    <td class="r"><strong>RD$ {{ number_format($compra->total, 2) }}</strong></td>
                </tr>
                @empty
                <tr>
                    <td colspan="9" style="text-align: center; padding: 24px; color: #94a3b8;">
                        No se encontraron registros de compras para los filtros aplicados.
                    </td>
                </tr>
                @endforelse

                @if($compras->isNotEmpty())
                <tr class="totals-row">
                    <td colspan="7" style="text-align: right; text-transform: uppercase;">
                        TOTALES GENERALES ({{ $totales['cantidad'] }} Facturas):
                    </td>
                    <td class="r">RD$ {{ number_format($totales['total_subtotal'], 2) }}</td>
                    <td class="r" style="color: #1a2b4a; font-size: 11px;">
                        RD$ {{ number_format($totales['total_compras'], 2) }}
                    </td>
                </tr>
                @endif
            </tbody>
        </table>

        <!-- PIE DE PÁGINA -->
        <div class="footer">
            Reporte generado automáticamente el {{ $fechaGeneracion->format('d/m/Y H:i:s') }} &nbsp;|&nbsp;
            {{ $company['nombre'] }}
        </div>
    </div>
</body>
</html>
