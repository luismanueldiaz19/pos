<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Cotización #{{ str_pad($cotizacion->id, 6, '0', STR_PAD_LEFT) }}</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            color: #2c3e50;
            font-size: 12px;
            background: #fff;
        }
        .page { padding: 36px 40px; }

        /* ── TOP HEADER BAND ── */
        .top-band {
            background: #1a2b4a;
            color: #fff;
            padding: 22px 28px;
            border-radius: 10px 10px 0 0;
        }
        .top-band-inner { width: 100%; }
        .top-band-inner td { vertical-align: middle; }
        .company-name {
            font-size: 19px;
            font-weight: 800;
            letter-spacing: 0.3px;
            color: #fff;
            line-height: 1.25;
        }
        .company-sub {
            font-size: 11px;
            color: #a8bbd1;
            margin-top: 4px;
            line-height: 1.6;
        }
        .quote-badge {
            text-align: right;
        }
        .quote-badge .label {
            font-size: 11px;
            color: #a8bbd1;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        .quote-badge .number {
            font-size: 28px;
            font-weight: 900;
            color: #fff;
            line-height: 1.1;
        }
        .quote-badge .estado-pill {
            display: inline-block;
            margin-top: 6px;
            padding: 3px 12px;
            border-radius: 20px;
            font-size: 10px;
            font-weight: bold;
            letter-spacing: 1px;
            text-transform: uppercase;
        }

        /* ── META ROW (dates) ── */
        .meta-row {
            background: #f0f4f8;
            border: 1px solid #dce4ef;
            border-top: none;
            padding: 12px 28px;
        }
        .meta-row table { width: 100%; }
        .meta-row td { font-size: 11px; color: #5d7186; padding: 2px 0; }
        .meta-row td strong { color: #1a2b4a; }

        /* ── VIGENCIA BANNER ── */
        .vigencia-banner {
            background: #fff8e6;
            border: 1px solid #f6d860;
            border-top: none;
            padding: 9px 28px;
            font-size: 11px;
            color: #7d5c00;
        }
        .vigencia-banner strong { color: #b8860b; }

        /* ── TWO-COLUMN: CLIENT + PREPARED BY ── */
        .info-section {
            margin-top: 20px;
            width: 100%;
            border-collapse: separate;
            border-spacing: 14px 0;
        }
        .info-box {
            width: 50%;
            vertical-align: top;
            border: 1px solid #dce4ef;
            border-radius: 8px;
            padding: 14px 18px;
        }
        .info-box-title {
            font-size: 10px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 1.2px;
            color: #8fa4bc;
            margin-bottom: 8px;
            padding-bottom: 6px;
            border-bottom: 1px solid #dce4ef;
        }
        .info-value-lg {
            font-size: 15px;
            font-weight: 800;
            color: #1a2b4a;
            margin-bottom: 4px;
        }
        .info-value {
            font-size: 11px;
            color: #5d7186;
            line-height: 1.7;
        }
        .info-value span { color: #1a2b4a; font-weight: 600; }

        /* ── ITEMS TABLE ── */
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 22px;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid #dce4ef;
        }
        .items-table thead tr {
            background: #1a2b4a;
            color: #fff;
        }
        .items-table th {
            padding: 10px 14px;
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            text-align: left;
        }
        .items-table th.r { text-align: right; }
        .items-table tbody tr:nth-child(even) { background: #f7f9fc; }
        .items-table td {
            padding: 10px 14px;
            border-bottom: 1px solid #ecf0f1;
            font-size: 11.5px;
            color: #34495e;
        }
        .items-table tr:last-child td { border-bottom: none; }
        .items-table td.r { text-align: right; }
        .item-desc { font-weight: 600; color: #1a2b4a; }
        .exento-badge {
            font-size: 9px;
            background: #e8f5e9;
            color: #388e3c;
            padding: 1px 6px;
            border-radius: 4px;
            margin-left: 4px;
            font-weight: bold;
        }

        /* ── TOTALS ── */
        .totals-wrap { width: 100%; margin-top: 18px; }
        .totals-table {
            width: 42%;
            float: right;
            border-collapse: collapse;
            border: 1px solid #dce4ef;
            border-radius: 8px;
            overflow: hidden;
        }
        .totals-table td { padding: 9px 16px; font-size: 11.5px; color: #34495e; }
        .totals-table td.lbl { text-align: right; color: #7f8c8d; }
        .totals-table td.val { text-align: right; font-weight: 700; }
        .totals-table tr.total-row { background: #1a2b4a; }
        .totals-table tr.total-row td { color: #fff; font-size: 14px; font-weight: 900; padding: 12px 16px; }
        .totals-table tr.total-row td.lbl { color: #a8bbd1; }

        /* ── NOTES ── */
        .notes-section {
            clear: both;
            margin-top: 22px;
            padding: 12px 18px;
            background: #fdfae5;
            border-left: 4px solid #f1c40f;
            border-radius: 0 8px 8px 0;
        }
        .notes-title { font-weight: bold; color: #d35400; margin-bottom: 4px; font-size: 11px; }
        .notes-content { color: #795b00; font-size: 11px; line-height: 1.6; }

        /* ── DISCLAIMER ── */
        .disclaimer {
            clear: both;
            margin-top: 20px;
            padding: 12px 18px;
            background: #fff0f0;
            border-left: 4px solid #e74c3c;
            border-radius: 0 8px 8px 0;
        }
        .disclaimer-title { font-weight: bold; color: #c0392b; font-size: 11px; margin-bottom: 3px; }
        .disclaimer-text { color: #922b21; font-size: 10.5px; line-height: 1.6; }

        /* ── FOOTER ── */
        .footer {
            margin-top: 36px;
            text-align: center;
            font-size: 10px;
            color: #b0bec5;
            border-top: 1px solid #ecf0f1;
            padding-top: 16px;
            clear: both;
        }
    </style>
</head>
<body>
    <?php
        $logoPath = public_path('images/app_icon.png');
        $base64Logo = '';
        if (file_exists($logoPath)) {
            $ext = strtolower(pathinfo($logoPath, PATHINFO_EXTENSION));
            $data = file_get_contents($logoPath);
            $base64Logo = 'data:image/' . $ext . ';base64,' . base64_encode($data);
        }

        $companyNombre    = !empty($company['nombre']) ? $company['nombre'] : config('company.nombre', 'EMPRESA');
        $companyRnc       = !empty($company['rnc']) ? $company['rnc'] : config('company.rnc', '');
        $companyTel       = !empty($company['telefono']) ? $company['telefono'] : config('company.telefono', '');
        $companyDir       = !empty($company['direccion']) ? $company['direccion'] : config('company.direccion', '');

        $cliente = $cotizacion->cliente;
        $emision = \Carbon\Carbon::parse($cotizacion->fecha_emision)->format('d/m/Y');
        $vence   = \Carbon\Carbon::parse($cotizacion->fecha_vencimiento)->format('d/m/Y');
        $dias    = \Carbon\Carbon::parse($cotizacion->fecha_emision)
                        ->diffInDays(\Carbon\Carbon::parse($cotizacion->fecha_vencimiento));

        $estadoColor = match($cotizacion->estado) {
            'aprobado'  => ['bg' => '#27ae60', 'text' => '#fff'],
            'cancelado' => ['bg' => '#e74c3c', 'text' => '#fff'],
            default     => ['bg' => '#f39c12', 'text' => '#fff'],
        };
    ?>

    <div class="page">

        {{-- ── TOP BAND ── --}}
        <div class="top-band">
            <table class="top-band-inner">
                <tr>
                    <td style="width:55%">
                        @if($base64Logo)
                            <img src="{{ $base64Logo }}" alt="Logo" style="max-height:55px; margin-bottom:8px;">
                        @endif
                        <div class="company-name">{{ $companyNombre }}</div>
                        <div class="company-sub">
                            @if($companyRnc) RNC: {{ $companyRnc }} &nbsp;|&nbsp; @endif
                            @if($companyTel) Tel: {{ $companyTel }} @endif
                            @if($companyDir) <br>{{ $companyDir }} @endif
                        </div>
                    </td>
                    <td class="quote-badge" style="width:45%">
                        <div class="label">Cotización</div>
                        <div class="number">#{{ str_pad($cotizacion->id, 6, '0', STR_PAD_LEFT) }}</div>
                        <div>
                            <span class="estado-pill"
                                style="background:{{ $estadoColor['bg'] }}; color:{{ $estadoColor['text'] }}">
                                {{ strtoupper($cotizacion->estado) }}
                            </span>
                        </div>
                    </td>
                </tr>
            </table>
        </div>

        {{-- ── META ROW ── --}}
        <div class="meta-row">
            <table>
                <tr>
                    <td><strong>Fecha de Emisión:</strong> &nbsp;{{ $emision }}</td>
                    <td style="text-align:center"><strong>Válida Hasta:</strong> &nbsp;{{ $vence }}</td>
                    <td style="text-align:right"><strong>Elaborado por:</strong> &nbsp;{{ $cotizacion->user->name ?? '---' }}</td>
                </tr>
            </table>
        </div>

        {{-- ── VIGENCIA BANNER ── --}}
        <div class="vigencia-banner">
            <strong>Vigencia de la oferta:</strong>
            Esta cotización es válida por <strong>{{ $dias }} días</strong> a partir de la fecha de emisión,
            hasta el <strong>{{ $vence }}</strong>.
        </div>

        {{-- ── CLIENT + COMPANY BLOCK ── --}}
        <table class="info-section">
            <tr>
                <td class="info-box">
                    <div class="info-box-title">Cliente</div>
                    <div class="info-value-lg">
                        {{ $cliente->nombre ?? '' }} {{ $cliente->apellido ?? '' }}
                    </div>
                    <div class="info-value">
                        @if(!empty($cliente->rnc_cedula))
                            RNC / Cédula: <span>{{ $cliente->rnc_cedula }}</span><br>
                        @elseif(!empty($cliente->rnc))
                            RNC / Cédula: <span>{{ $cliente->rnc }}</span><br>
                        @endif
                        @if(!empty($cliente->email))
                            Email: <span>{{ $cliente->email }}</span><br>
                        @endif
                        @if(!empty($cliente->telefono))
                            Teléfono: <span>{{ $cliente->telefono }}</span><br>
                        @endif
                        @if(!empty($cliente->direccion))
                            Dirección: <span>{{ $cliente->direccion }}</span><br>
                        @endif
                        @if(!empty($cliente->tipo_cliente))
                            Tipo de Cliente: <span>{{ ucfirst($cliente->tipo_cliente) }}</span>
                        @endif
                    </div>
                </td>
                <td class="info-box">
                    <div class="info-box-title">Empresa</div>
                    <div class="info-value-lg">{{ $companyNombre }}</div>
                    <div class="info-value">
                        @if($companyRnc) RNC: <span>{{ $companyRnc }}</span><br> @endif
                        @if($companyTel) Teléfono: <span>{{ $companyTel }}</span><br> @endif
                        @if($companyDir) Dirección: <span>{{ $companyDir }}</span><br> @endif
                        Asesor: <span>{{ $cotizacion->user->name ?? 'Sistema' }}</span>
                    </div>
                </td>
            </tr>
        </table>

        {{-- ── ITEMS ── --}}
        <table class="items-table">
            <thead>
                <tr>
                    <th style="width:8%">Cant.</th>
                    <th style="width:42%">Descripción</th>
                    <th class="r" style="width:15%">P. Unitario</th>
                    <th class="r" style="width:12%">ITBIS</th>
                    <th class="r" style="width:15%">Total</th>
                </tr>
            </thead>
            <tbody>
                @foreach($cotizacion->detalles as $detalle)
                <tr>
                    <td>{{ doubleval($detalle->cantidad) }}x</td>
                    <td><span class="item-desc">{{ $detalle->descripcion }}</span></td>
                    <td class="r">RD$ {{ number_format($detalle->precio, 2) }}</td>
                    <td class="r">
                        @if(doubleval($detalle->itbis) > 0)
                            RD$ {{ number_format($detalle->itbis, 2) }}
                        @endif
                    </td>
                    <td class="r"><strong>RD$ {{ number_format($detalle->total, 2) }}</strong></td>
                </tr>
                @endforeach
            </tbody>
        </table>

        {{-- ── TOTALS ── --}}
        <div class="totals-wrap">
            <table class="totals-table">
                <tr>
                    <td class="lbl">Subtotal:</td>
                    <td class="val">RD$ {{ number_format($cotizacion->subtotal, 2) }}</td>
                </tr>
                @if($cotizacion->descuento_total > 0)
                <tr>
                    <td class="lbl">Descuento:</td>
                    <td class="val" style="color:#e74c3c;">− RD$ {{ number_format($cotizacion->descuento_total, 2) }}</td>
                </tr>
                @endif
                <tr>
                    <td class="lbl">ITBIS:</td>
                    <td class="val">RD$ {{ number_format($cotizacion->itbis, 2) }}</td>
                </tr>
                <tr class="total-row">
                    <td class="lbl">TOTAL GENERAL:</td>
                    <td class="val">RD$ {{ number_format($cotizacion->total, 2) }}</td>
                </tr>
            </table>
        </div>
        <div style="clear:both; height:40px;"></div>

        {{-- ── NOTAS DEL CLIENTE ── --}}
        @if($cotizacion->nota)
        <div class="notes-section" style="margin-top:12px;">
            <div class="notes-title">Notas adicionales</div>
            <div class="notes-content">{{ $cotizacion->nota }}</div>
        </div>
        @endif

        <div class="disclaimer" style="margin-top:12px;">
            <div class="disclaimer-title">IMPORTANTE — Esta cotización está sujeta a cambios</div>
            <div class="disclaimer-text">
                Precios y condiciones vigentes hasta el <strong>{{ $vence }}</strong>.
                Este documento no constituye una factura ni un compromiso de venta.
            </div>
        </div>

        {{-- ── FOOTER ── --}}
        <div class="footer">
            Cotización generada el {{ \Carbon\Carbon::now()->format('d/m/Y H:i') }} &nbsp;|&nbsp;
            {{ $companyNombre }}
            <br>Este documento no tiene validez como Comprobante Fiscal.
        </div>

    </div>
</body>
</html>
