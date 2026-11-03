<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Cotización #{{ str_pad($cotizacion->id, 6, '0', STR_PAD_LEFT) }}</title>
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
    </style>
</head>
<body>
    <div class="main-document-flow">
        <!-- 1. ENCABEZADO GEOMÉTRICO (MODELO LA SIERRA) -->
        @include('pdf.components.header_banner', [
            'titulo'         => 'COTIZACIÓN',
            'subtitulo'      => !empty($company['slogan']) ? $company['slogan'] : ($company['actividad'] ?? null),
            'company'        => $company ?? [],
            'base64Logo'     => $base64Logo ?? null,
            'emisorNombre'   => $cotizacion->user->name ?? (!empty($company['nombre']) ? $company['nombre'] : 'Luis Miguel González'),
            'emisorTelefono' => $company['telefono'] ?? config('company.telefono', '(809) 697-8028'),
            'emisorEmail'    => '---',
        ])

        <!-- 2. INFORMACIÓN DEL DOCUMENTO Y CLIENTE -->
        @include('pdf.components.doc_client_info', [
            'cotizacion'       => $cotizacion,
            'cliente'          => $cotizacion->cliente,
            'numeroDocumento'  => str_pad($cotizacion->id, 6, '0', STR_PAD_LEFT),
            'fechaEmision'     => $cotizacion->fecha_emision ?? $cotizacion->created_at,
            'fechaVencimiento' => $cotizacion->fecha_vencimiento,
        ])

        <!-- 3. CAJA DE DESCRIPCIÓN DEL PROYECTO / SERVICIO -->
        @include('pdf.components.description_box', [
            'descripcion' => $cotizacion->nota ?: null,
        ])

        <!-- 4. TABLA DE ÍTEMS / SERVICIOS -->
        @include('pdf.components.items_table', [
            'detalles'      => $cotizacion->detalles,
            'simboloMoneda' => $company['moneda'] ?? '$',
        ])

        <!-- 5. TÉRMINOS, CONDICIONES, MÉTODOS DE PAGO Y TOTALES -->
        @include('pdf.components.totals_and_terms', [
            'subtotal'       => $cotizacion->subtotal,
            'impuesto'       => $cotizacion->itbis,
            'descuento'      => $cotizacion->descuento_total,
            'total'          => $cotizacion->total,
            'vigenciaDias'   => 15,
            'company'        => $company ?? [],
            'simboloMoneda'  => $company['moneda'] ?? '$',
        ])

        <!-- 6. BANNER INFERIOR NARANJA (FOOTER) -->
        @include('pdf.components.footer_banner', [
            'company' => $company ?? [],
        ])
    </div>
</body>
</html>
