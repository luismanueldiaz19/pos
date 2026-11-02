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
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            color: #1e293b;
            font-size: 11px;
            background: #ffffff;
            line-height: 1.4;
        }
        .page {
            padding: 30px 36px;
        }

        /* ── TOP HEADER ── */
        .top-band {
            background: #1a2b4a;
            color: #ffffff;
            padding: 18px 24px;
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
        .invoice-badge {
            text-align: right;
        }
        .invoice-badge .label {
            font-size: 9.5px;
            color: #94a3b8;
            text-transform: uppercase;
            letter-spacing: 1.5px;
        }
        .invoice-badge .number {
            font-size: 18px;
            font-weight: 900;
            color: #ffffff;
            margin-top: 2px;
        }

        /* ── META INFO ── */
        .meta-strip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-top: none;
            padding: 10px 24px;
            margin-bottom: 16px;
            border-radius: 0 0 8px 8px;
        }
        .meta-table {
            width: 100%;
        }
        .meta-table td {
            font-size: 10px;
            color: #64748b;
        }
        .meta-table td strong {
            color: #0f172a;
        }

        /* ── SUPPLIER & DOC DETAILS ── */
        .info-cards {
            width: 100%;
            border-collapse: separate;
            border-spacing: 10px 0;
            margin-bottom: 16px;
        }
        .info-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 12px 14px;
            vertical-align: top;
            width: 50%;
        }
        .card-title {
            font-size: 9.5px;
            font-weight: 800;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 6px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
        }
        .card-name {
            font-size: 13px;
            font-weight: 800;
            color: #0f172a;
            margin-bottom: 3px;
        }
        .card-detail {
            font-size: 10.5px;
            color: #475569;
            line-height: 1.5;
        }

        /* ── ITEMS TABLE ── */
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 6px;
            font-size: 10.5px;
        }
        .items-table th {
            background: #334155;
            color: #ffffff;
            font-size: 9.5px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 8px 10px;
            text-align: left;
        }
        .items-table th.r,
        .items-table td.r {
            text-align: right;
        }
        .items-table th.c,
        .items-table td.c {
            text-align: center;
        }
        .items-table td {
            padding: 8px 10px;
            border-bottom: 1px solid #e2e8f0;
            color: #334155;
            vertical-align: middle;
        }
        .items-table tr:nth-child(even) td {
            background-color: #f8fafc;
        }

        /* ── TOTALS ── */
        .totals-container {
            width: 100%;
            margin-top: 14px;
        }
        .totals-table {
            width: 40%;
            float: right;
            border-collapse: collapse;
        }
        .totals-table td {
            padding: 4px 8px;
            font-size: 11px;
            color: #475569;
        }
        .totals-table td.lbl {
            text-align: right;
            font-weight: 600;
        }
        .totals-table td.val {
            text-align: right;
            font-weight: 700;
            color: #0f172a;
        }
        .totals-table tr.grand td {
            border-top: 2px solid #cbd5e1;
            padding-top: 8px;
            font-size: 13px;
            font-weight: 900;
            color: #1a2b4a;
        }

        /* ── NOTES ── */
        .notes-box {
            clear: both;
            margin-top: 40px;
            background: #fffbeb;
            border: 1px solid #fde68a;
            border-radius: 6px;
            padding: 10px 14px;
            font-size: 10.5px;
            color: #92400e;
        }
        .notes-box strong {
            color: #78350f;
        }

        /* ── FOOTER ── */
        .footer {
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #e2e8f0;
            text-align: center;
            font-size: 9.5px;
            color: #94a3b8;
            clear: both;
        }
    </style>
</head>
<body>
    <div class="page">
        <!-- CABECERA -->
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
                    <td style="width: 40%;" class="invoice-badge">
                        <div class="label">Registro de Compra</div>
                        <div class="number">Factura #{{ $compra->numero_factura_proveedor }}</div>
                        <div style="margin-top: 4px; font-size: 10px; color: #cbd5e1;">
                            NCF: {{ $compra->ncf ?: 'N/A' }}
                        </div>
                    </td>
                </tr>
            </table>
        </div>

        <!-- STRIP DE METADATOS -->
        <div class="meta-strip">
            <table class="meta-table">
                <tr>
                    <td><strong>Fecha de Compra:</strong> {{ \Carbon\Carbon::parse($compra->fecha_compra)->format('d/m/Y') }}</td>
                    <td><strong>Tipo de Pago:</strong> {{ $compra->tipo_compra }}</td>
                    <td><strong>Estado:</strong> {{ strtoupper($compra->estado) }}</td>
                    <td><strong>Registrado por:</strong> {{ $compra->usuario->name ?? 'Admin' }}</td>
                </tr>
            </table>
        </div>

        <!-- DATOS PROVEEDOR Y FACTURACIÓN -->
        <table class="info-cards">
            <tr>
                <td class="info-card">
                    <div class="card-title">INFORMACIÓN DEL PROVEEDOR</div>
                    <div class="card-name">{{ $compra->proveedor->nombre ?? 'Desconocido' }}</div>
                    <div class="card-detail">
                        <strong>RNC / Cédula:</strong> {{ $compra->proveedor->rnc_cedula ?? 'N/A' }}<br>
                        <strong>Teléfono:</strong> {{ $compra->proveedor->telefono ?? 'N/A' }}<br>
                        <strong>Dirección:</strong> {{ $compra->proveedor->direccion ?? 'N/A' }}
                    </div>
                </td>
                <td class="info-card">
                    <div class="card-title">CONDICIONES DE PAGO</div>
                    <div class="card-detail" style="margin-top: 4px;">
                        <strong>Condición:</strong> {{ $compra->tipo_compra }}<br>
                        @if($compra->fecha_vencimiento)
                            <strong>Fecha Vencimiento:</strong> {{ \Carbon\Carbon::parse($compra->fecha_vencimiento)->format('d/m/Y') }}<br>
                        @endif
                        <strong>Ítems Registrados:</strong> {{ $compra->detalles->count() }} artículo(s)<br>
                        <strong>Estado Factura:</strong> {{ $compra->estado }}
                    </div>
                </td>
            </tr>
        </table>

        <!-- ARTÍCULOS COMPRADOS -->
        <table class="items-table">
            <thead>
                <tr>
                    <th style="width: 5%;" class="c">#</th>
                    <th style="width: 45%;">PRODUCTO / DESCRIPCIÓN</th>
                    <th style="width: 10%;" class="c">CANT.</th>
                    <th style="width: 13%;" class="r">COSTO UNIT.</th>
                    <th style="width: 12%;" class="r">ITBIS</th>
                    <th style="width: 15%;" class="r">TOTAL RD$</th>
                </tr>
            </thead>
            <tbody>
                @foreach($compra->detalles as $i => $item)
                <tr>
                    <td class="c" style="color: #64748b;">{{ $i + 1 }}</td>
                    <td>
                        <strong>{{ $item->producto->nombre ?? $item->descripcion ?? 'Producto' }}</strong>
                    </td>
                    <td class="c"><strong>{{ $item->cantidad }}</strong></td>
                    <td class="r">RD$ {{ number_format($item->costo_unitario, 2) }}</td>
                    <td class="r">RD$ {{ number_format($item->impuesto_monto, 2) }}</td>
                    <td class="r"><strong>RD$ {{ number_format($item->total, 2) }}</strong></td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <!-- TOTALES -->
        <div class="totals-container">
            <table class="totals-table">
                <tr>
                    <td class="lbl">Subtotal:</td>
                    <td class="val">RD$ {{ number_format($compra->subtotal, 2) }}</td>
                </tr>
                <tr>
                    <td class="lbl">Impuestos (ITBIS):</td>
                    <td class="val">RD$ {{ number_format($compra->impuestos, 2) }}</td>
                </tr>
                <tr class="grand">
                    <td class="lbl">TOTAL DE COMPRA:</td>
                    <td class="val">RD$ {{ number_format($compra->total, 2) }}</td>
                </tr>
            </table>
        </div>

        <!-- NOTAS -->
        @if($compra->notas)
        <div class="notes-box">
            <strong>Notas:</strong> {{ $compra->notas }}
        </div>
        @endif

        <!-- PIE DE PÁGINA -->
        <div class="footer">
            Documento generado el {{ \Carbon\Carbon::now()->format('d/m/Y H:i') }} &nbsp;|&nbsp;
            {{ $company['nombre'] }}
        </div>
    </div>
</body>
</html>
