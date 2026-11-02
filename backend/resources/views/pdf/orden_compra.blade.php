<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Orden de Compra {{ $orden->numero_orden }}</title>
    <style>
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            color: #2c3e50;
            font-size: 13px;
            margin: 0;
            padding: 0;
        }
        .container {
            padding: 40px;
        }
        .header-table {
            width: 100%;
            margin-bottom: 30px;
        }
        .header-table td {
            vertical-align: middle;
        }
        .logo-container img {
            max-height: 80px;
        }
        .company-details {
            font-size: 12px;
            color: #7f8c8d;
            line-height: 1.5;
        }
        .company-name {
            font-size: 24px;
            font-weight: 800;
            color: #2c3e50;
            margin: 0 0 5px 0;
            letter-spacing: 1px;
        }
        .quote-info-box {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 12px;
            border-left: 5px solid #27ae60;
        }
        .quote-title {
            font-size: 22px;
            font-weight: 900;
            color: #2ecc71;
            margin: 0 0 10px 0;
            letter-spacing: 2px;
        }
        .quote-meta {
            font-size: 12px;
            line-height: 1.6;
        }
        .quote-meta strong {
            color: #34495e;
            display: inline-block;
            width: 100px;
        }
        .client-section {
            margin: 30px 0;
            padding: 20px;
            background-color: #fcfcfc;
            border: 1px solid #ecf0f1;
            border-radius: 8px;
        }
        .client-section h3 {
            margin: 0 0 10px 0;
            color: #7f8c8d;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .client-name {
            font-size: 18px;
            font-weight: bold;
            color: #2c3e50;
            margin: 0 0 5px 0;
        }
        .client-details {
            color: #7f8c8d;
            line-height: 1.5;
        }
        .items-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            margin-top: 20px;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid #ecf0f1;
        }
        .items-table th {
            background-color: #34495e;
            color: #ffffff;
            padding: 12px 15px;
            text-align: left;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .items-table th.text-right {
            text-align: right;
        }
        .items-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #ecf0f1;
            color: #34495e;
        }
        .items-table tr:last-child td {
            border-bottom: none;
        }
        .items-table td.text-right {
            text-align: right;
        }
        .totals-container {
            width: 100%;
            margin-top: 20px;
        }
        .totals-table {
            width: 45%;
            float: right;
            border-collapse: collapse;
        }
        .totals-table td {
            padding: 10px;
            color: #34495e;
        }
        .totals-table td.label {
            text-align: right;
            color: #7f8c8d;
            font-weight: bold;
        }
        .totals-table td.value {
            text-align: right;
            font-weight: bold;
        }
        .totals-table tr.grand-total td {
            font-size: 16px;
            font-weight: 900;
            border-top: 2px solid #2c3e50;
            padding-top: 15px;
            white-space: nowrap;
        }
        .totals-table tr.grand-total td.label {
            color: #2c3e50;
        }
        .notes-section {
            clear: both;
            margin-top: 60px;
            padding: 15px 20px;
            background-color: #fdfae5;
            border-left: 4px solid #f1c40f;
            border-radius: 0 8px 8px 0;
        }
        .notes-title {
            font-weight: bold;
            color: #d35400;
            margin-bottom: 5px;
        }
        .notes-content {
            color: #e67e22;
        }
        .footer {
            margin-top: 50px;
            text-align: center;
            font-size: 11px;
            color: #bdc3c7;
            border-top: 1px solid #ecf0f1;
            padding-top: 20px;
            clear: both;
        }
    </style>
</head>
<body>
    <?php
        $logoPath = public_path('images/app_icon.png');
        $base64Logo = '';
        if(file_exists($logoPath)) {
            $type = pathinfo($logoPath, PATHINFO_EXTENSION);
            $data = file_get_contents($logoPath);
            $base64Logo = 'data:image/' . $type . ';base64,' . base64_encode($data);
        }
        $companyNombre = config('company.name', 'Menuxa Restaurante SRL');
        $companyRnc = config('company.rnc', '40224129524');
        $companyTel = config('company.phone', '(809) 000-0000');
        $companyDir = config('company.address', 'Santo Domingo, República Dominicana');
    ?>
    <div class="container">
        <!-- HEADER -->
        <table class="header-table">
            <tr>
                <td style="width: 50%;">
                    @if($base64Logo)
                        <div class="logo-container">
                            <img src="{{ $base64Logo }}" alt="Logo">
                        </div>
                    @else
                        <h1 class="company-name">{{ $companyNombre }}</h1>
                    @endif
                    <div class="company-details" style="margin-top: 10px;">
                        <strong>{{ $companyNombre }}</strong><br>
                        Tel: {{ $companyTel }}<br>
                        RNC: {{ $companyRnc }}<br>
                        {{ $companyDir }}
                    </div>
                </td>
                <td style="width: 50%;">
                    <div class="quote-info-box">
                        <h2 class="quote-title">ORDEN DE COMPRA</h2>
                        <div class="quote-meta">
                            <strong>No. Orden:</strong> {{ $orden->numero_orden }}<br>
                            <strong>Fecha Emisión:</strong> {{ \Carbon\Carbon::parse($orden->fecha)->format('d/m/Y') }}<br>
                            <strong>Válido Hasta:</strong> {{ \Carbon\Carbon::parse($orden->fecha_vencimiento)->format('d/m/Y') }}<br>
                            <strong>Estado:</strong> <span style="color: {{ $orden->estado == 'ENVIADA' ? '#27ae60' : ($orden->estado == 'CANCELADA' ? '#c0392b' : '#f39c12') }}; text-transform: uppercase; font-weight: bold;">{{ $orden->estado }}</span>
                        </div>
                    </div>
                </td>
            </tr>
        </table>

        <!-- SUPPLIER INFO -->
        <div class="client-section">
            <h3>Proveedor:</h3>
            <div class="client-name">{{ $orden->proveedor->nombre }}</div>
            <div class="client-details">
                @if($orden->proveedor->email)
                    Email: {{ $orden->proveedor->email }}<br>
                @endif
                @if($orden->proveedor->telefono)
                    Teléfono: {{ $orden->proveedor->telefono }}<br>
                @endif
                @if($orden->proveedor->rnc)
                    RNC/Cédula: {{ $orden->proveedor->rnc }}<br>
                @endif
                @if($orden->proveedor->direccion)
                    Dirección: {{ $orden->proveedor->direccion }}
                @endif
            </div>
        </div>

        <!-- ITEMS -->
        <table class="items-table">
            <thead>
                <tr>
                    <th style="width: 10%;">CANT</th>
                    <th style="width: 40%;">DESCRIPCIÓN</th>
                    <th class="text-right" style="width: 15%;">PRECIO</th>
                    <th class="text-right" style="width: 15%;">ITBIS</th>
                    <th class="text-right" style="width: 20%;">TOTAL</th>
                </tr>
            </thead>
            <tbody>
                @foreach($orden->detalles as $detalle)
                <tr>
                    <td>{{ doubleval($detalle->cantidad) }}x</td>
                    <td><strong>{{ $detalle->descripcion }}</strong></td>
                    <td class="text-right">RD$ {{ number_format($detalle->costo_esperado, 2) }}</td>
                    <td class="text-right">RD$ {{ number_format($detalle->itbis, 2) }}</td>
                    <td class="text-right">RD$ {{ number_format($detalle->total, 2) }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <!-- TOTALS -->
        <div class="totals-container">
            <table class="totals-table">
                <tr>
                    <td class="label">Subtotal:</td>
                    <td class="value">RD$ {{ number_format($orden->subtotal, 2) }}</td>
                </tr>
                @if($orden->descuento_total > 0)
                <tr>
                    <td class="label">Descuento:</td>
                    <td class="value" style="color: #e74c3c;">- RD$ {{ number_format($orden->descuento_total, 2) }}</td>
                </tr>
                @endif
                <tr>
                    <td class="label">ITBIS (18%):</td>
                    <td class="value">RD$ {{ number_format($orden->itbis, 2) }}</td>
                </tr>
                <tr class="grand-total">
                    <td class="label">TOTAL GENERAL:</td>
                    <td class="value">RD$ {{ number_format($orden->total, 2) }}</td>
                </tr>
            </table>
        </div>

        <!-- NOTES -->
        @if($orden->notas)
        <div class="notes-section">
            <div class="notes-title">Notas adicionales</div>
            <div class="notes-content">{{ $orden->notas }}</div>
        </div>
        @endif

        <!-- FOOTER -->
        <div class="footer">
            Este documento es una orden de compra generada para nuestro proveedor &bull; {{ $companyNombre }}
        </div>
    </div>
</body>
</html>
