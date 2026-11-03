@php
    $items = $detalles ?? ($cotizacion->detalles ?? collect([]));
    $moneda = $simboloMoneda ?? '$';
    $count = count($items);
@endphp

<!-- TABLA DE ITEMS / SERVICIOS (MODELO LA SIERRA) -->
<style>
    .it-table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 24px;
        font-family: Arial, Helvetica, sans-serif;
    }
    .it-table th {
        background-color: #1e2e4a;
        color: #ffffff;
        font-weight: 700;
        font-size: 12px;
        padding: 10px 14px;
        text-align: left;
        border: none;
    }
    .it-table th.c, .it-table td.c {
        text-align: center;
    }
    .it-table th.r, .it-table td.r {
        text-align: right;
    }
    .it-table td {
        padding: 10px 14px;
        border-bottom: 1px solid #e2e8f0;
        color: #334155;
        font-size: 12px;
        vertical-align: middle;
    }
    .it-table tr:nth-child(even) td {
        background-color: #f8fafc;
    }
    .it-desc {
        font-weight: 600;
        color: #1e293b;
    }
</style>

<table class="it-table">
    <thead>
        <tr>
            <th style="width: 48%;">Detalles</th>
            <th style="width: 14%;" class="c">Cantidad</th>
            <th style="width: 19%;" class="r">Valor unitario</th>
            <th style="width: 19%;" class="r">Total</th>
        </tr>
    </thead>
    <tbody>
        @forelse($items as $item)
        @php
            $desc = $item->descripcion ?? ($item->producto->nombre ?? ($item->nombre ?? 'Detalles'));
            $cant = $item->cantidad ?? 1;
            $precio = $item->precio ?? ($item->costo_unitario ?? 0);
            $totalLinea = $item->total ?? ($cant * $precio);
        @endphp
        <tr>
            <td class="it-desc">{{ $desc }}</td>
            <td class="c">{{ (float)$cant == (int)$cant ? (int)$cant : number_format($cant, 2) }}</td>
            <td class="r">{{ $moneda }}{{ number_format($precio, 2) }}</td>
            <td class="r"><strong>{{ $moneda }}{{ number_format($totalLinea, 2) }}</strong></td>
        </tr>
        @empty
        <tr>
            <td colspan="4" style="text-align: center; padding: 25px; color: #94a3b8;">
                No hay ítems registrados en este documento.
            </td>
        </tr>
        @endforelse

        {{-- Filas de relleno si hay pocos items para mantener proporciones elegantes como en el modelo --}}
        @if($count > 0 && $count < 3)
            @for($i = $count; $i < 3; $i++)
            <tr>
                <td style="color: transparent;">&nbsp;</td>
                <td class="c" style="color: transparent;">&nbsp;</td>
                <td class="r" style="color: transparent;">&nbsp;</td>
                <td class="r" style="color: transparent;">&nbsp;</td>
            </tr>
            @endfor
        @endif
    </tbody>
</table>
