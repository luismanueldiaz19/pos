@php
    $cli = $cliente ?? ($cotizacion->cliente ?? null);
    $cliNombre = !empty($cli->nombre) ? "{$cli->nombre} " . ($cli->apellido ?? '') : 'Cliente General';
    $cliTelefono = $cli->telefono ?? ($cli->celular ?? null);
    $cliDireccion = $cli->direccion ?? null;
    $cliDocumento = $cli->rnc_cedula ?? ($cli->rnc ?? null);

    $docNumero = $numeroDocumento ?? (isset($cotizacion) ? str_pad((string)$cotizacion->id, 6, '0', STR_PAD_LEFT) : '000001');
    $tipoDoc = $tipoDocumento ?? 'Cotización';

    $fmtEmision = isset($fechaEmision) ? \Carbon\Carbon::parse($fechaEmision)->translatedFormat('d \\d\\e F \\d\\e Y') : (isset($cotizacion) ? \Carbon\Carbon::parse($cotizacion->fecha_emision ?? $cotizacion->created_at)->translatedFormat('d \\d\\e F \\d\\e Y') : now()->translatedFormat('d \\d\\e F \\d\\e Y'));
    $fmtVencimiento = isset($fechaVencimiento) ? \Carbon\Carbon::parse($fechaVencimiento)->translatedFormat('d \\d\\e F \\d\\e Y') : (isset($cotizacion) && !empty($cotizacion->fecha_vencimiento) ? \Carbon\Carbon::parse($cotizacion->fecha_vencimiento)->translatedFormat('d \\d\\e F \\d\\e Y') : null);
@endphp

<!-- SECCIÓN INFORMACIÓN DE DOCUMENTO Y CLIENTE -->
<style>
    .dci-table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 20px;
    }
    .dci-col-left {
        width: 50%;
        vertical-align: top;
        padding-right: 20px;
    }
    .dci-col-right {
        width: 50%;
        vertical-align: top;
        padding-left: 20px;
    }
    .dci-title {
        font-size: 18px;
        font-weight: 800;
        color: #1e2e4a;
        line-height: 1.2;
        margin-bottom: 8px;
        letter-spacing: -0.2px;
        font-family: Arial, Helvetica, sans-serif;
    }
    .dci-doc-number {
        font-size: 15px;
        font-weight: 700;
        color: #334155;
    }
    .dci-label {
        font-size: 11px;
        color: #64748b;
        margin-bottom: 2px;
        font-family: Arial, Helvetica, sans-serif;
    }
    .dci-value {
        font-size: 13px;
        font-weight: 700;
        color: #1e293b;
        margin-bottom: 8px;
        font-family: Arial, Helvetica, sans-serif;
    }
    .dci-client-name {
        font-size: 14px;
        font-weight: 700;
        color: #1e293b;
        margin-bottom: 4px;
        font-family: Arial, Helvetica, sans-serif;
    }
    .dci-client-sub {
        font-size: 12px;
        color: #475569;
        line-height: 1.5;
        font-family: Arial, Helvetica, sans-serif;
    }
</style>

<table class="dci-table">
    <tr>
        <!-- COLUMNA IZQUIERDA: DATOS COTIZACIÓN (EN 2 LÍNEAS) -->
        <td class="dci-col-left">
            <div class="dci-title">
                {{ $tipoDoc }}<br>
                <span class="dci-doc-number">No. {{ $docNumero }}</span>
            </div>
            
            <div class="dci-label">Fecha de emisión:</div>
            <div class="dci-value">{{ $fmtEmision }}</div>

            @if(!empty($fmtVencimiento))
                <div class="dci-label">Válida hasta:</div>
                <div class="dci-value">{{ $fmtVencimiento }}</div>
            @endif
        </td>

        <!-- COLUMNA DERECHA: COTIZADO A (CLIENTE EN 2 LÍNEAS) -->
        <td class="dci-col-right">
            <div class="dci-title">Cotizado a:</div>
            <div class="dci-client-name">{{ $cliNombre }}</div>
            <div class="dci-client-sub">
                @if(!empty($cliTelefono))
                    <div>Celular: {{ $cliTelefono }}</div>
                @endif
                @if(!empty($cliDireccion))
                    <div>Dirección del trabajo: {{ $cliDireccion }}</div>
                @endif
                @if(!empty($cliDocumento))
                    <div>RNC / Cédula: {{ $cliDocumento }}</div>
                @endif
            </div>
        </td>
    </tr>
</table>
