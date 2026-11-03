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
        .badge-contado {
            background-color: #f1f5f9;
            color: #475569;
        }
        .badge-credito {
            background-color: #ffedd5;
            color: #c2410c;
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
            'titulo'          => 'REPORTE DE COMPRAS',
            'subtitulo'       => 'Historial de Compras y Adquisiciones',
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
                    <div class="meta-title">Historial de Compras</div>
                    <div class="meta-line">
                        <span class="meta-label">Período evaluado:</span>
                        <strong>{{ !empty($filters['fecha_desde']) ? \Carbon\Carbon::parse($filters['fecha_desde'])->format('d/m/Y') : 'Inicio' }}</strong> al <strong>{{ !empty($filters['fecha_hasta']) ? \Carbon\Carbon::parse($filters['fecha_hasta'])->format('d/m/Y') : 'Hoy' }}</strong>
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
                        <strong>{{ strtoupper($filters['tipo_compra'] ?? 'TODAS') }}</strong>
                        &nbsp;&nbsp;&bull;&nbsp;&nbsp;
                        <span class="meta-label">Estado:</span>
                        <strong>{{ strtoupper($filters['estado'] ?? 'TODOS') }}</strong>
                    </div>
                    @if(!empty($filters['search']))
                        <div class="meta-line">
                            <span class="meta-label">Búsqueda:</span>
                            <strong>"{{ $filters['search'] }}"</strong>
                        </div>
                    @else
                        <div class="meta-line">
                            <span class="meta-label">Tipo:</span>
                            Adquisiciones y Compras a Proveedores
                        </div>
                    @endif
                </td>
            </tr>
        </table>

        <!-- 3. TABLA DETALLADA DE COMPRAS -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 10%;">Fecha</th>
                    <th style="width: 15%;">Factura Prov.</th>
                    <th style="width: 14%;">NCF</th>
                    <th style="width: 25%;">Proveedor</th>
                    <th style="width: 10%;" class="c">Tipo</th>
                    <th style="width: 9%;" class="c">Estado</th>
                    <th style="width: 8%;" class="r">ITBIS</th>
                    <th style="width: 9%;" class="r">Total RD$</th>
                </tr>
            </thead>
            <tbody>
                @forelse($compras as $c)
                <tr>
                    <td>{{ \Carbon\Carbon::parse($c->fecha_compra)->format('d/m/Y') }}</td>
                    <td><strong>{{ $c->numero_factura_proveedor }}</strong></td>
                    <td>{{ $c->ncf ?: '---' }}</td>
                    <td>{{ $c->proveedor->nombre ?? 'Proveedor General' }}</td>
                    <td class="c">
                        <span class="badge {{ strtoupper($c->tipo_compra) == 'CONTADO' ? 'badge-contado' : 'badge-credito' }}">
                            {{ $c->tipo_compra }}
                        </span>
                    </td>
                    <td class="c">
                        <span class="badge {{ strtoupper($c->estado) == 'PAGADA' ? 'badge-pagada' : 'badge-pendiente' }}">
                            {{ strtoupper($c->estado) }}
                        </span>
                    </td>
                    <td class="r">RD$ {{ number_format($c->impuestos, 2) }}</td>
                    <td class="r"><strong>RD$ {{ number_format($c->total, 2) }}</strong></td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" style="text-align: center; padding: 25px; color: #94a3b8;">
                        No se encontraron registros de compras para los filtros seleccionados.
                    </td>
                </tr>
                @endforelse

                @php $cantCompras = count($compras); @endphp
                @if($cantCompras > 0 && $cantCompras < 3)
                    @for($i = $cantCompras; $i < 3; $i++)
                    <tr>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td style="color: transparent;">&nbsp;</td>
                        <td class="c" style="color: transparent;">&nbsp;</td>
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
                    <div class="summary-title">Resumen del reporte</div>
                    <div class="summary-desc">
                        Se procesaron <strong>{{ count($compras) }} factura(s)</strong> de compra en el período consultado.<br>
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
                            <td class="lbl">ITBIS (18%)</td>
                            <td class="val">RD$ {{ number_format($totales['total_impuestos'] ?? 0, 2) }}</td>
                        </tr>
                        <tr class="totals-highlight">
                            <td class="lbl">Total</td>
                            <td class="val">RD$ {{ number_format($totales['total_compras'] ?? 0, 2) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl" style="color: #64748b;">Compras al contado</td>
                            <td class="val" style="color: #15803d;">RD$ {{ number_format($totales['total_contado'] ?? 0, 2) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl" style="color: #64748b;">Compras a crédito (CxP)</td>
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
