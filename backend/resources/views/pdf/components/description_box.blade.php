@php
    $texto = $descripcion ?? ($cotizacion->nota ?? null);
    $label = $tituloDescripcion ?? 'Descripción del servicio:';
@endphp

@if(!empty($texto))
<!-- CAJA DE DESCRIPCIÓN DEL PROYECTO / SERVICIO -->
<style>
    .desc-box-container {
        width: 100%;
        background-color: #f1f5f9;
        border-radius: 6px;
        padding: 10px 16px;
        margin-bottom: 20px;
        font-size: 12px;
        color: #334155;
        line-height: 1.5;
        font-family: Arial, Helvetica, sans-serif;
    }
    .desc-box-label {
        font-weight: 700;
        color: #0f172a;
    }
</style>

<div class="desc-box-container">
    <span class="desc-box-label">{{ $label }}</span> {{ $texto }}
</div>
@endif
