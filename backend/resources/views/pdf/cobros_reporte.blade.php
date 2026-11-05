<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Cobros y Recibos</title>
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
        .badge-pago {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 8.5px;
            font-weight: 700;
            text-transform: uppercase;
        }
        .badge-pago-efectivo {
            background-color: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
        }
        .badge-pago-tarjeta {
            background-color: #eff6ff;
            color: #1d4ed8;
            border: 1px solid #bfdbfe;
        }
        .badge-pago-transferencia {
            background-color: #fff7ed;
            color: #c2410c;
            border: 1px solid #fed7aa;
        }
        .badge-pago-otro {
            background-color: #f1f5f9;
            color: #475569;
            border: 1px solid #cbd5e1;
        }

        /* ── TOTALES Y RESUMEN INFERIOR ── */
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
            padding: 6px 8px;
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
            font-size: 14px;
            font-weight: 900;
            color: #1e2e4a;
            padding: 8px 8px;
        }
        .totals-highlight td.val {
            font-size: 16px;
            font-weight: 900;
            color: #047857;
            padding: 8px 8px;
        }
    </style>
</head>
<body>
    <div class="main-document-flow">
        <!-- 1. ENCABEZADO GEOMÉTRICO -->
        @include('pdf.components.header_banner', [
            'titulo'          => 'REPORTE DE COBROS Y RECIBOS',
            'subtitulo'       => 'Historial de Cobros y Abonos a Cuentas por Cobrar (CxC)',
            'numeroDocumento' => count($pagos) . ' cobros',
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
                    <div class="meta-title">Historial de Cobros Recaudados</div>
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
                        <span class="meta-label">Método de pago:</span>
                        <strong>{{ !empty($filters['metodo_pago']) && strtolower($filters['metodo_pago']) !== 'todos' ? strtoupper($filters['metodo_pago']) : 'TODOS' }}</strong>
                    </div>
                    @if(!empty($filters['search']))
                        <div class="meta-line">
                            <span class="meta-label">Búsqueda aplicada:</span>
                            <strong>"{{ $filters['search'] }}"</strong>
                        </div>
                    @else
                        <div class="meta-line">
                            <span class="meta-label">Tipo:</span>
                            Ingresos por Cobranzas y Recuperación de Cartera
                        </div>
                    @endif
                </td>
            </tr>
        </table>

        <!-- 3. TABLA DETALLADA DE COBROS -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 8%;">Recibo #</th>
                    <th style="width: 10%;">Fecha</th>
                    <th style="width: 22%;">Cliente</th>
                    <th style="width: 16%;">Factura / NCF</th>
                    <th style="width: 12%;" class="c">Tipo de Pago</th>
                    <th style="width: 16%;">Cuenta Destino / Banco</th>
                    <th style="width: 16%;" class="r">Monto Cobrado RD$</th>
                </tr>
            </thead>
            <tbody>
                @forelse($pagos as $p)
                @php
                    $metodoStr = strtolower(trim((string)$p->metodo_pago));
                    $badgePagoClass = match(true) {
                        str_contains($metodoStr, 'efectivo')      => 'badge-pago-efectivo',
                        str_contains($metodoStr, 'tarjeta')       => 'badge-pago-tarjeta',
                        str_contains($metodoStr, 'transferencia') => 'badge-pago-transferencia',
                        default                                   => 'badge-pago-otro',
                    };
                    $clienteNombre = $p->cuentaPorCobrar->cliente->nombre ?? 'Cliente General';
                    $facturaNcf = $p->cuentaPorCobrar->factura->ncf ?? 'N/A';
                    $facturaId = $p->cuentaPorCobrar->factura->id ?? '';
                    $bancoNombre = $p->cuentaDestino->nombre ?? 'Caja / Banco';
                    $fechaCobro = \Carbon\Carbon::parse($p->fecha_pago)->format('d/m/Y');
                @endphp
                <tr>
                    <td><strong>#{{ $p->id }}</strong></td>
                    <td>{{ $fechaCobro }}</td>
                    <td>{{ $clienteNombre }}</td>
                    <td>
                        {{ $facturaNcf }}
                        @if($facturaId)
                            <span style="color: #64748b; font-size: 9px;">(#{{ $facturaId }})</span>
                        @endif
                    </td>
                    <td class="c">
                        <span class="badge-pago {{ $badgePagoClass }}">
                            {{ strtoupper($p->metodo_pago) }}
                        </span>
                    </td>
                    <td>
                        {{ $bancoNombre }}
                        @if(!empty($p->referencia))
                            <span style="color: #64748b; font-size: 9px;">(Ref: {{ $p->referencia }})</span>
                        @endif
                    </td>
                    <td class="r" style="color: #047857; font-weight: 800;">
                        RD$ {{ number_format((float)($p->monto_pagado ?? 0), 2) }}
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="7" style="text-align: center; padding: 25px; color: #94a3b8;">
                        No se encontraron cobros registrados para los filtros seleccionados.
                    </td>
                </tr>
                @endforelse

                @php $cantCobros = count($pagos); @endphp
                @if($cantCobros > 0 && $cantCobros < 3)
                    @for($i = $cantCobros; $i < 3; $i++)
                    <tr>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td class="c" style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td class="r" style="color: transparent;">&nbsp;</td>
                    </tr>
                    @endfor
                @endif
            </tbody>
        </table>

        <!-- 4. TOTALES AGRUPADOS Y RESUMEN INFERIOR -->
        <table class="summary-section">
            <tr>
                <!-- COLUMNA IZQUIERDA: RESUMEN Y MÉTODOS DE PAGO AGRUPADOS -->
                <td class="summary-left">
                    <div class="summary-title">Resumen de cobranzas</div>
                    <div class="summary-desc">
                        Se registraron <strong>{{ count($pagos) }} recibo(s) de cobro</strong> en el período consultado.<br>
                        Fondos ingresados a tesorería y cuentas bancarias registradas.
                    </div>

                    @if(!empty($desgloseMetodos) && count($desgloseMetodos) > 0)
                    <div style="margin-top: 14px; padding-top: 10px; border-top: 1px dashed #cbd5e1;">
                        <div style="font-size: 11.5px; font-weight: 800; color: #1e2e4a; margin-bottom: 6px;">
                            Cobros por Método de Pago:
                        </div>
                        <table style="width: 95%; border-collapse: collapse; font-size: 10.5px;">
                            @foreach($desgloseMetodos as $m)
                                @php
                                    $mNombre = strtoupper($m->metodo ?? 'OTRO');
                                    $mTotal = (float)($m->total ?? 0);
                                    $pct = ($totales['total_recaudado'] ?? 0) > 0 ? ($mTotal / $totales['total_recaudado']) * 100 : 0;
                                    $colorM = match(true) {
                                        str_contains(strtolower($mNombre), 'efectivo')      => '#047857',
                                        str_contains(strtolower($mNombre), 'tarjeta')       => '#1d4ed8',
                                        str_contains(strtolower($mNombre), 'transferencia') => '#c2410c',
                                        default                                             => '#334155',
                                    };
                                @endphp
                                <tr>
                                    <td style="padding: 4px 0; font-weight: 700; color: #334155; width: 42%;">
                                        <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background-color: {{ $colorM }}; margin-right: 5px;"></span>
                                        {{ $mNombre }} <span style="color: #64748b; font-weight: normal; font-size: 9.5px;">({{ $m->cantidad }} cobros)</span>
                                    </td>
                                    <td style="padding: 4px 0; text-align: right; font-weight: 700; color: {{ $colorM }}; width: 38%;">
                                        RD$ {{ number_format($mTotal, 2) }}
                                    </td>
                                    <td style="padding: 4px 0; text-align: right; color: #64748b; font-size: 9.5px; width: 20%;">
                                        ({{ number_format($pct, 1) }}%)
                                    </td>
                                </tr>
                            @endforeach
                        </table>
                    </div>
                    @endif
                </td>

                <!-- COLUMNA DERECHA: TOTALES -->
                <td class="summary-right">
                    <table class="invoice-totals-table">
                        <tr>
                            <td class="lbl">Total de Recibos Emitidos</td>
                            <td class="val">{{ $totales['cantidad'] ?? 0 }}</td>
                        </tr>
                        <tr>
                            <td class="lbl">Promedio por Cobro</td>
                            <td class="val">RD$ {{ number_format($totales['promedio_cobro'] ?? 0, 2) }}</td>
                        </tr>
                        <tr class="totals-highlight">
                            <td class="lbl">TOTAL RECAUDADO</td>
                            <td class="val">RD$ {{ number_format($totales['total_recaudado'] ?? 0, 2) }}</td>
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
