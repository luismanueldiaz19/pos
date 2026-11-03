<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Facturación</title>
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

        /* ── INFORMACIÓN DEL REPORTE Y FILTROS (ESTILO FACTURA, SIN CUADRADOS) ── */
        .meta-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 6px;
            margin-bottom: 18px;
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
            font-size: 15px;
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
            font-size: 10.5px;
            margin-bottom: 18px;
        }
        .report-table th {
            background-color: #1e2e4a;
            color: #ffffff;
            font-size: 11px;
            font-weight: 700;
            padding: 9px 10px;
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
            padding: 8px 10px;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
            vertical-align: middle;
        }
        .report-table tr:nth-child(even) td {
            background-color: #f8fafc;
        }

        /* ── BADGES ── */
        .badge {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 9px;
            font-weight: 700;
            text-transform: uppercase;
        }
        .badge-pagada {
            background-color: #dcfce7;
            color: #15803d;
        }
        .badge-pendiente {
            background-color: #fef3c7;
            color: #b45309;
        }
        .badge-anulada {
            background-color: #fee2e2;
            color: #b91c1c;
        }

        /* ── TOTALES Y RESUMEN INFERIOR (ESTILO FINAL DE FACTURA) ── */
        .summary-section {
            width: 100%;
            border-collapse: collapse;
            margin-top: 8px;
            margin-bottom: 20px;
        }
        .summary-left {
            width: 55%;
            vertical-align: top;
            padding-right: 30px;
        }
        .summary-right {
            width: 45%;
            vertical-align: top;
            padding-left: 10px;
        }
        .summary-title {
            font-size: 14px;
            font-weight: 800;
            color: #1e2e4a;
            margin-bottom: 6px;
        }
        .summary-desc {
            font-size: 11px;
            color: #64748b;
            line-height: 1.6;
        }
        .invoice-totals-table {
            width: 100%;
            border-collapse: collapse;
        }
        .invoice-totals-table td {
            padding: 5px 8px;
            font-size: 12px;
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
            font-size: 15px;
            font-weight: 900;
            color: #1e2e4a;
            padding: 8px 8px;
        }
        .totals-highlight td.val {
            font-size: 16px;
            font-weight: 900;
            color: #1e2e4a;
            padding: 8px 8px;
        }
    </style>
</head>
<body>
    <div class="main-document-flow">
        <!-- 1. ENCABEZADO GEOMÉTRICO (MODELO SUAVE) -->
        @include('pdf.components.header_banner', [
            'titulo'          => 'REPORTE DE FACTURACIÓN',
            'subtitulo'       => 'Historial de Facturación y Comprobantes Fiscales (e-CF)',
            'numeroDocumento' => count($facturas) . ' facturas',
            'company'         => $company ?? [],
            'base64Logo'      => $base64Logo ?? null,
            'emisorNombre'    => 'Generado por: ' . ($usuarioName ?? 'Administrador'),
            'emisorTelefono'  => $company['telefono'] ?? config('company.telefono', '(809) 697-8028'),
            'emisorEmail'     => '---',
        ])

        <!-- 2. INFORMACIÓN DEL REPORTE Y FILTROS (LIMPIO, SIN CUADRADOS) -->
        <table class="meta-table">
            <tr>
                <td class="meta-left">
                    <div class="meta-title">Historial de Facturación</div>
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
                        <span class="meta-label">Estado de facturas:</span>
                        <strong>{{ !empty($filters['estado']) && strtolower($filters['estado']) !== 'todos' ? strtoupper($filters['estado']) : 'TODAS' }}</strong>
                    </div>
                    @if(!empty($filters['search']))
                        <div class="meta-line">
                            <span class="meta-label">Búsqueda aplicada:</span>
                            <strong>"{{ $filters['search'] }}"</strong>
                        </div>
                    @else
                        <div class="meta-line">
                            <span class="meta-label">Tipo:</span>
                            Ventas y Documentos Fiscales Emitidos
                        </div>
                    @endif
                </td>
            </tr>
        </table>

        <!-- 3. TABLA DETALLADA DE FACTURAS -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 10%;">Fecha</th>
                    <th style="width: 10%;">Factura #</th>
                    <th style="width: 15%;">NCF / e-CF</th>
                    <th style="width: 23%;">Cliente</th>
                    <th style="width: 13%;">Cajero / Usuario</th>
                    <th style="width: 9%;" class="c">Estado</th>
                    <th style="width: 9%;" class="r">ITBIS</th>
                    <th style="width: 11%;" class="r">Total RD$</th>
                </tr>
            </thead>
            <tbody>
                @forelse($facturas as $f)
                @php
                    $estadoStr = strtolower((string)$f->estado);
                    $badgeClass = match($estadoStr) {
                        'pagada'    => 'badge-pagada',
                        'pendiente' => 'badge-pendiente',
                        'anulada'   => 'badge-anulada',
                        default     => 'badge-pagada',
                    };
                    $ncfDisplay = !empty($f->ncf) ? $f->ncf : ($f->ecfDocumento->e_ncf ?? '---');
                @endphp
                <tr>
                    <td>{{ \Carbon\Carbon::parse($f->fecha_emision)->format('d/m/Y') }}</td>
                    <td><strong>#{{ $f->id }}</strong></td>
                    <td>{{ $ncfDisplay }}</td>
                    <td>{{ $f->cliente->nombre ?? 'Cliente Ocasional' }}</td>
                    <td>{{ $f->user->name ?? 'Sistema' }}</td>
                    <td class="c">
                        <span class="badge {{ $badgeClass }}">
                            {{ strtoupper($f->estado) }}
                        </span>
                    </td>
                    <td class="r">RD$ {{ number_format((float)($f->itbis ?? 0), 2) }}</td>
                    <td class="r"><strong>RD$ {{ number_format((float)($f->total ?? 0), 2) }}</strong></td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" style="text-align: center; padding: 25px; color: #94a3b8;">
                        No se encontraron facturas registradas para los filtros seleccionados.
                    </td>
                </tr>
                @endforelse

                @php $cantFacturas = count($facturas); @endphp
                @if($cantFacturas > 0 && $cantFacturas < 3)
                    @for($i = $cantFacturas; $i < 3; $i++)
                    <tr>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td class="c" style="color: transparent;">&nbsp;</td>
                        <td class="r" style="color: transparent;">&nbsp;</td>
                        <td class="r" style="color: transparent;">&nbsp;</td>
                    </tr>
                    @endfor
                @endif
            </tbody>
        </table>

        <!-- 4. TOTALES ESTILO FINAL DE FACTURA (SIMPLE, SIN CUADRADOS) -->
        <table class="summary-section">
            <tr>
                <!-- COLUMNA IZQUIERDA: RESUMEN -->
                <td class="summary-left">
                    <div class="summary-title">Resumen de facturación</div>
                    <div class="summary-desc">
                        Se procesaron <strong>{{ count($facturas) }} factura(s)</strong> en el período consultado.<br>
                        Documento generado para fines de control administrativo y fiscal.
                    </div>
                </td>

                <!-- COLUMNA DERECHA: TOTALES COMO EN FACTURA -->
                <td class="summary-right">
                    <table class="invoice-totals-table">
                        <tr>
                            <td class="lbl">Subtotal</td>
                            <td class="val">RD$ {{ number_format($totales['total_subtotal'] ?? 0, 2) }}</td>
                        </tr>
                        @if(($totales['total_descuento'] ?? 0) > 0)
                        <tr>
                            <td class="lbl">Descuento aplicado</td>
                            <td class="val">- RD$ {{ number_format($totales['total_descuento'] ?? 0, 2) }}</td>
                        </tr>
                        @endif
                        <tr>
                            <td class="lbl">ITBIS (18%)</td>
                            <td class="val">RD$ {{ number_format($totales['total_itbis'] ?? 0, 2) }}</td>
                        </tr>
                        <tr class="totals-highlight">
                            <td class="lbl">Total Facturado</td>
                            <td class="val">RD$ {{ number_format($totales['total_venta'] ?? 0, 2) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl" style="color: #64748b;">Total cobrado (Pagadas)</td>
                            <td class="val" style="color: #15803d;">RD$ {{ number_format($totales['total_pagado'] ?? 0, 2) }}</td>
                        </tr>
                        @if(($totales['total_pendiente'] ?? 0) > 0)
                        <tr>
                            <td class="lbl" style="color: #64748b;">Por cobrar (Pendientes)</td>
                            <td class="val" style="color: #b45309;">RD$ {{ number_format($totales['total_pendiente'] ?? 0, 2) }}</td>
                        </tr>
                        @endif
                        @if(($totales['total_anulado'] ?? 0) > 0)
                        <tr>
                            <td class="lbl" style="color: #64748b;">Facturas anuladas</td>
                            <td class="val" style="color: #b91c1c;">RD$ {{ number_format($totales['total_anulado'] ?? 0, 2) }}</td>
                        </tr>
                        @endif
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

