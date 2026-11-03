<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Factura de Compra #{{ $compra->numero_factura_proveedor }}</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        @page {
            margin: 0px;
            size: letter portrait;
        }
        body {
            font-family: Arial, Helvetica, sans-serif;
            color: #1e293b;
            font-size: 12px;
            background: #ffffff;
            margin: 0;
            padding: 35px 38px 80px 38px;
        }
        .main-document-flow {
            width: 100%;
        }

        /* ── SECCIÓN INFO PROVEEDOR Y DOCUMENTO ── */
        .info-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .info-col-left {
            width: 50%;
            vertical-align: top;
            padding-right: 20px;
        }
        .info-col-right {
            width: 50%;
            vertical-align: top;
            padding-left: 20px;
        }
        .info-title {
            font-size: 18px;
            font-weight: 800;
            color: #1e2e4a;
            line-height: 1.2;
            margin-bottom: 8px;
            letter-spacing: -0.2px;
        }
        .info-doc-number {
            font-size: 15px;
            font-weight: 700;
            color: #334155;
        }
        .info-label {
            font-size: 11px;
            color: #64748b;
            margin-bottom: 2px;
        }
        .info-value {
            font-size: 13px;
            font-weight: 700;
            color: #1e293b;
            margin-bottom: 8px;
        }
        .info-provider-name {
            font-size: 14px;
            font-weight: 700;
            color: #1e293b;
            margin-bottom: 4px;
        }
        .info-provider-sub {
            font-size: 12px;
            color: #475569;
            line-height: 1.5;
        }

        /* ── TABLA DE ITEMS DE COMPRA ── */
        .compra-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 24px;
        }
        .compra-table th {
            background-color: #1e2e4a;
            color: #ffffff;
            font-weight: 700;
            font-size: 12px;
            padding: 10px 14px;
            text-align: left;
            border: none;
        }
        .compra-table th.c, .compra-table td.c {
            text-align: center;
        }
        .compra-table th.r, .compra-table td.r {
            text-align: right;
        }
        .compra-table td {
            padding: 10px 14px;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
            font-size: 12px;
            vertical-align: middle;
        }
        .compra-table tr:nth-child(even) td {
            background-color: #f8fafc;
        }
        .item-desc {
            font-weight: 600;
            color: #1e293b;
        }

        /* ── TOTALES Y CONDICIONES ── */
        .summary-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 8px;
            margin-bottom: 25px;
        }
        .summary-col-left {
            width: 55%;
            vertical-align: top;
            padding-right: 25px;
        }
        .summary-col-right {
            width: 45%;
            vertical-align: top;
            padding-left: 10px;
        }
        .summary-title {
            font-size: 15px;
            font-weight: 800;
            color: #1e2e4a;
            margin-bottom: 6px;
        }
        .summary-box {
            font-size: 11.5px;
            color: #475569;
            line-height: 1.6;
        }
        .totals-table {
            width: 100%;
            border-collapse: collapse;
        }
        .totals-table td {
            padding: 5px 8px;
            font-size: 12.5px;
        }
        .totals-table td.lbl {
            color: #475569;
            font-weight: 600;
            text-align: left;
        }
        .totals-table td.val {
            color: #1e293b;
            font-weight: 700;
            text-align: right;
        }
        .totals-highlight {
            background-color: #f1f5f9;
            border-radius: 4px;
        }
        .totals-highlight td.lbl {
            font-size: 16px;
            font-weight: 900;
            color: #1e2e4a;
            padding: 9px 8px;
        }
        .totals-highlight td.val {
            font-size: 17px;
            font-weight: 900;
            color: #1e2e4a;
            padding: 9px 8px;
        }
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }
        .badge-success {
            background-color: #dcfce7;
            color: #15803d;
        }
        .badge-warning {
            background-color: #fef3c7;
            color: #b45309;
        }
    </style>
</head>
<body>
    <div class="main-document-flow">
        <!-- 1. ENCABEZADO GEOMÉTRICO (MODELO SUAVE) -->
        @include('pdf.components.header_banner', [
            'titulo'          => 'FACTURA DE COMPRA',
            'subtitulo'       => !empty($compra->ncf) ? "NCF: {$compra->ncf}" : 'Adquisición de Bienes / Servicios',
            'numeroDocumento' => $compra->numero_factura_proveedor,
            'company'         => $company ?? [],
            'base64Logo'      => $base64Logo ?? null,
            'emisorNombre'    => 'Registrado por: ' . ($compra->usuario->name ?? 'Administrador'),
            'emisorTelefono'  => $company['telefono'] ?? config('company.telefono', '(809) 697-8028'),
            'emisorEmail'     => '---',
        ])

        <!-- 2. INFORMACIÓN DEL DOCUMENTO Y PROVEEDOR (EN 2 LÍNEAS) -->
        <table class="info-table">
            <tr>
                <!-- COLUMNA IZQUIERDA: DATOS DE LA COMPRA -->
                <td class="info-col-left">
                    <div class="info-title">
                        Factura de Compra<br>
                        <span class="info-doc-number"># {{ $compra->numero_factura_proveedor }}</span>
                    </div>

                    <div class="info-label">Fecha de compra / emisión:</div>
                    <div class="info-value">
                        {{ \Carbon\Carbon::parse($compra->fecha_compra)->translatedFormat('d \\d\\e F \\d\\e Y') }}
                    </div>

                    @if(!empty($compra->fecha_vencimiento))
                        <div class="info-label">Válida / Vence:</div>
                        <div class="info-value">
                            {{ \Carbon\Carbon::parse($compra->fecha_vencimiento)->translatedFormat('d \\d\\e F \\d\\e Y') }}
                        </div>
                    @endif
                </td>

                <!-- COLUMNA DERECHA: PROVEEDOR -->
                <td class="info-col-right">
                    <div class="info-title">Proveedor:</div>
                    <div class="info-provider-name">{{ $compra->proveedor->nombre ?? 'Proveedor General' }}</div>
                    <div class="info-provider-sub">
                        @if(!empty($compra->proveedor->rnc_cedula))
                            <div>RNC / Cédula: {{ $compra->proveedor->rnc_cedula }}</div>
                        @endif
                        @if(!empty($compra->proveedor->telefono))
                            <div>Teléfono: {{ $compra->proveedor->telefono }}</div>
                        @endif
                        @if(!empty($compra->proveedor->direccion))
                            <div>Dirección: {{ $compra->proveedor->direccion }}</div>
                        @endif
                        @if(!empty($compra->ncf))
                            <div>NCF: <strong>{{ $compra->ncf }}</strong></div>
                        @endif
                    </div>
                </td>
            </tr>
        </table>

        <!-- 3. CAJA DE DESCRIPCIÓN O NOTA DE COMPRA -->
        @if(!empty($compra->notas))
        @include('pdf.components.description_box', [
            'tituloDescripcion' => 'Concepto / Observaciones:',
            'descripcion'       => $compra->notas,
        ])
        @endif

        <!-- 4. TABLA DE ÍTEMS / ARTÍCULOS COMPRADOS -->
        <table class="compra-table">
            <thead>
                <tr>
                    <th style="width: 44%;">Producto / Descripción</th>
                    <th style="width: 12%;" class="c">Cantidad</th>
                    <th style="width: 15%;" class="r">Costo Unit.</th>
                    <th style="width: 13%;" class="r">ITBIS</th>
                    <th style="width: 16%;" class="r">Total RD$</th>
                </tr>
            </thead>
            <tbody>
                @forelse($compra->detalles as $item)
                @php
                    $nombreProd = $item->producto->nombre ?? ($item->descripcion ?? 'Artículo de Compra');
                    $cant = $item->cantidad ?? 1;
                    $costo = $item->costo_unitario ?? 0;
                    $itbis = $item->impuesto_monto ?? 0;
                    $lineaTot = $item->total ?? ($cant * $costo);
                @endphp
                <tr>
                    <td class="item-desc">{{ $nombreProd }}</td>
                    <td class="c">{{ (float)$cant == (int)$cant ? (int)$cant : number_format($cant, 2) }}</td>
                    <td class="r">RD$ {{ number_format($costo, 2) }}</td>
                    <td class="r">RD$ {{ number_format($itbis, 2) }}</td>
                    <td class="r"><strong>RD$ {{ number_format($lineaTot, 2) }}</strong></td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" style="text-align: center; padding: 25px; color: #94a3b8;">
                        No hay artículos registrados en esta compra.
                    </td>
                </tr>
                @endforelse

                @php $cantItems = count($compra->detalles ?? []); @endphp
                @if($cantItems > 0 && $cantItems < 3)
                    @for($i = $cantItems; $i < 3; $i++)
                    <tr>
                        <td style="color: transparent;">&nbsp;</td>
                        <td class="c" style="color: transparent;">&nbsp;</td>
                        <td class="r" style="color: transparent;">&nbsp;</td>
                        <td class="r" style="color: transparent;">&nbsp;</td>
                        <td class="r" style="color: transparent;">&nbsp;</td>
                    </tr>
                    @endfor
                @endif
            </tbody>
        </table>

        <!-- 5. CONDICIONES DE PAGO Y TOTALES -->
        <table class="summary-table">
            <tr>
                <!-- COLUMNA IZQUIERDA: CONDICIONES DE PAGO Y REGISTRO -->
                <td class="summary-col-left">
                    <div class="summary-title">Condiciones de pago</div>
                    <div class="summary-box">
                        <div style="margin-bottom: 4px;">
                            <strong>Condición de compra:</strong>
                            <span class="badge {{ strtoupper($compra->tipo_compra) == 'CONTADO' ? 'badge-success' : 'badge-warning' }}">
                                {{ $compra->tipo_compra }}
                            </span>
                        </div>
                        <div style="margin-bottom: 4px;">
                            <strong>Estado del pago:</strong>
                            <span class="badge {{ strtoupper($compra->estado) == 'PAGADA' ? 'badge-success' : 'badge-warning' }}">
                                {{ strtoupper($compra->estado) }}
                            </span>
                        </div>
                        <div>Comprobante fiscal: {{ $compra->ncf ?: 'Gasto / Comprobante Interno' }}</div>
                    </div>
                </td>

                <!-- COLUMNA DERECHA: TOTALES -->
                <td class="summary-col-right">
                    <table class="totals-table">
                        <tr>
                            <td class="lbl">Subtotal</td>
                            <td class="val">RD$ {{ number_format($compra->subtotal, 2) }}</td>
                        </tr>
                        <tr>
                            <td class="lbl">ITBIS (18%)</td>
                            <td class="val">RD$ {{ number_format($compra->impuestos, 2) }}</td>
                        </tr>
                        <tr class="totals-highlight">
                            <td class="lbl">Total Compra</td>
                            <td class="val">RD$ {{ number_format($compra->total, 2) }}</td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>

        <!-- 6. BANNER INFERIOR SUAVE (FOOTER) -->
        @include('pdf.components.footer_banner', [
            'company' => $company ?? [],
        ])
    </div>
</body>
</html>
