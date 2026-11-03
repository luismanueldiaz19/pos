<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Gastos Operativos</title>
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
            font-size: 10px;
            margin-bottom: 18px;
        }
        .report-table th {
            background-color: #1e2e4a;
            color: #ffffff;
            font-size: 10px;
            font-weight: 700;
            padding: 8px 10px;
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
            padding: 7px 10px;
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
        .badge-contado {
            background-color: #dcfce7;
            color: #15803d;
        }
        .badge-credito {
            background-color: #fef3c7;
            color: #b45309;
        }
        .badge-cuenta {
            background-color: #f1f5f9;
            color: #1e2e4a;
            border: 1px solid #cbd5e1;
            font-weight: 700;
            padding: 2px 5px;
            border-radius: 3px;
            font-size: 9px;
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
            'titulo'          => 'GASTOS OPERATIVOS',
            'subtitulo'       => 'Contabilidad · Clase 6 (Gastos y Servicios)',
            'numeroDocumento' => count($compras) . ' registros',
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
                    <div class="meta-title">Gastos Operativos</div>
                    <div class="meta-line">
                        <span class="meta-label">Período:</span>
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
                        <span class="meta-label">Condición:</span>
                        <strong>{{ !empty($filters['tipo_compra']) && strtolower($filters['tipo_compra']) !== 'todos' ? strtoupper($filters['tipo_compra']) : 'TODAS' }}</strong>
                        &nbsp;&nbsp;&bull;&nbsp;&nbsp;
                        <span class="meta-label">Tipo:</span>
                        Gastos sin inventario (Clase 6)
                    </div>
                    @if(!empty($filters['search']))
                        <div class="meta-line">
                            <span class="meta-label">Búsqueda:</span>
                            <strong>"{{ $filters['search'] }}"</strong>
                        </div>
                    @endif
                </td>
            </tr>
        </table>

        <!-- 3. TABLA DETALLADA DE GASTOS -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 4%;" class="c">#</th>
                    <th style="width: 9%;">Fecha</th>
                    <th style="width: 14%;">Factura Prov.</th>
                    <th style="width: 13%;">NCF Fiscal</th>
                    <th style="width: 23%;">Beneficiario / Concepto</th>
                    <th style="width: 17%;">Cuenta Contable (Clase 6)</th>
                    <th style="width: 8%;" class="c">Condición</th>
                    <th style="width: 6%;" class="r">ITBIS</th>
                    <th style="width: 8%;" class="r">Total RD$</th>
                </tr>
            </thead>
            <tbody>
                @forelse($compras as $index => $gasto)
                @php
                    $primerDetalle = $gasto->detalles->first();
                    $cuentaContable = $primerDetalle?->cuentaContable;
                    $cuentaTexto = $cuentaContable 
                        ? "{$cuentaContable->codigo} - {$cuentaContable->nombre}" 
                        : ($primerDetalle?->descripcion ?: 'Gasto General');
                    $esContado = strtoupper((string)$gasto->tipo_compra) === 'CONTADO';
                @endphp
                <tr>
                    <td class="c" style="color: #64748b;">{{ $index + 1 }}</td>
                    <td>{{ \Carbon\Carbon::parse($gasto->fecha_compra)->format('d/m/Y') }}</td>
                    <td><strong>{{ $gasto->numero_factura_proveedor ?: 'S/N' }}</strong></td>
                    <td>{{ $gasto->ncf ?: '---' }}</td>
                    <td>
                        <strong>{{ $gasto->proveedor->nombre ?? 'Beneficiario Ocasional' }}</strong>
                        @if($primerDetalle && !empty($primerDetalle->descripcion) && $primerDetalle->descripcion !== ($gasto->proveedor->nombre ?? ''))
                            <div style="font-size: 8.5px; color: #64748b; margin-top: 1px;">
                                {{ $primerDetalle->descripcion }}
                            </div>
                        @endif
                    </td>
                    <td>
                        <span class="badge-cuenta">{{ $cuentaTexto }}</span>
                    </td>
                    <td class="c">
                        <span class="badge {{ $esContado ? 'badge-contado' : 'badge-credito' }}">
                            {{ $esContado ? 'CONTADO' : 'CRÉDITO' }}
                        </span>
                    </td>
                    <td class="r">
                        {{ $gasto->impuestos > 0 ? 'RD$ ' . number_format($gasto->impuestos, 2) : '-' }}
                    </td>
                    <td class="r">
                        <strong>RD$ {{ number_format($gasto->total, 2) }}</strong>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="9" style="text-align: center; padding: 25px; color: #94a3b8;">
                        No se encontraron registros de gastos operativos para los filtros seleccionados.
                    </td>
                </tr>
                @endforelse

                @php $cantGastos = count($compras); @endphp
                @if($cantGastos > 0 && $cantGastos < 3)
                    @for($i = $cantGastos; $i < 3; $i++)
                    <tr>
                        <td class="c" style="color: transparent;">&nbsp;</td>
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
                    <div class="summary-title">Resumen de gastos</div>
                    <div class="summary-desc">
                        Se procesaron <strong>{{ count($compras) }} registro(s)</strong> de gastos operativos en el período consultado.<br>
                        Documento generado para fines de control administrativo y fiscal.
                    </div>
                </td>

                <!-- COLUMNA DERECHA: TOTALES COMO EN FACTURA -->
                <td class="summary-right">
                    <table class="invoice-totals-table">
                        <tr>
                            <td class="lbl">Subtotal</td>
                            <td class="val">RD$ {{ number_format($totales['total_subtotal'] ?? ($totales['total_compras'] - $totales['total_impuestos']), 2) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl">ITBIS Crédito Fiscal</td>
                            <td class="val">RD$ {{ number_format($totales['total_impuestos'] ?? 0, 2) }}</td>
                        </tr>
                        <tr class="totals-highlight">
                            <td class="lbl">Total Gastos</td>
                            <td class="val">RD$ {{ number_format($totales['total_compras'] ?? 0, 2) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl" style="color: #64748b;">Gastos pagados (Contado)</td>
                            <td class="val" style="color: #15803d;">RD$ {{ number_format($totales['total_contado'] ?? 0, 2) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl" style="color: #64748b;">Gastos a crédito (CxP)</td>
                            <td class="val" style="color: #b45309;">RD$ {{ number_format($totales['total_credito'] ?? 0, 2) }}</td>
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
