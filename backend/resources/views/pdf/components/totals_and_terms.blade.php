@php
    $moneda = $simboloMoneda ?? '$';
    $sub = $subtotal ?? ($cotizacion->subtotal ?? 0);
    $imp = $impuesto ?? ($cotizacion->itbis ?? 0);
    $tot = $total ?? ($cotizacion->total ?? ($sub + $imp));
    $des = $descuento ?? ($cotizacion->descuento_total ?? 0);

    $anticipo = $anticipoMonto ?? null;
    $saldo = $saldoMonto ?? ($anticipo !== null ? ($tot - $anticipo) : null);

    $diasVigencia = $vigenciaDias ?? 15;
    $lblImp = $labelImpuesto ?? 'IVA (18%)';

    $titular = !empty($titularPago) ? $titularPago : (!empty($company['titular_cuenta']) ? $company['titular_cuenta'] : '---');
    $cuenta = !empty($cuentaBancaria) ? $cuentaBancaria : (!empty($company['cuenta_bancaria']) ? $company['cuenta_bancaria'] : 'Cuenta No. ---');
@endphp

<!-- SECCIÓN INFERIOR: TÉRMINOS, CONDICIONES, MÉTODOS DE PAGO Y TOTALES -->
<style>
    .tat-main-table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 8px;
        margin-bottom: 25px;
        font-family: Arial, Helvetica, sans-serif;
    }
    .tat-col-left {
        width: 55%;
        vertical-align: top;
        padding-right: 25px;
    }
    .tat-col-right {
        width: 45%;
        vertical-align: top;
        padding-left: 10px;
    }
    .tat-section-title {
        font-size: 15px;
        font-weight: 800;
        color: #1e2e4a;
        margin-bottom: 6px;
    }
    .tat-terms-list {
        font-size: 11.5px;
        color: #475569;
        line-height: 1.6;
        margin-bottom: 16px;
    }
    .tat-terms-list ol {
        margin-left: 18px;
        padding-left: 0;
    }
    .tat-terms-list li {
        margin-bottom: 4px;
    }
    .tat-payment-box {
        font-size: 11.5px;
        color: #475569;
        line-height: 1.5;
    }
    .tat-payment-title {
        font-size: 15px;
        font-weight: 800;
        color: #1e2e4a;
        margin-bottom: 5px;
    }
    .tat-totals-table {
        width: 100%;
        border-collapse: collapse;
    }
    .tat-totals-table td {
        padding: 5px 8px;
        font-size: 12.5px;
    }
    .tat-totals-table td.lbl {
        color: #475569;
        font-weight: 600;
        text-align: left;
    }
    .tat-totals-table td.val {
        color: #1e293b;
        font-weight: 700;
        text-align: right;
    }
    .tat-total-highlight {
        background-color: #f1f5f9;
        border-radius: 4px;
    }
    .tat-total-highlight td.lbl {
        font-size: 16px;
        font-weight: 900;
        color: #0f172a;
        padding: 9px 8px;
    }
    .tat-total-highlight td.val {
        font-size: 17px;
        font-weight: 900;
        color: #0f172a;
        padding: 9px 8px;
    }
    .tat-extra-row td {
        color: #64748b;
        font-size: 11.5px;
        padding-top: 6px;
    }
</style>

<table class="tat-main-table">
    <tr>
        <!-- COLUMNA IZQUIERDA: NOTAS O TÉRMINOS & MÉTODOS DE PAGO -->
        <td class="tat-col-left">
            <div class="tat-section-title">Notas o términos</div>
            <div class="tat-terms-list">
                <ol>
                    <li>Cotización válida por {{ $diasVigencia }} días. Pasado ese plazo, los precios de materiales pueden variar.</li>
                </ol>
            </div>

            <div class="tat-payment-title">Métodos de pago</div>
            <div class="tat-payment-box">
                <div>Transferencia bancaria / Efectivo</div>
                <div>{{ $cuenta }}</div>
                <div>Titular: {{ $titular }}</div>
            </div>
        </td>

        <!-- COLUMNA DERECHA: TOTALES -->
        <td class="tat-col-right">
            <table class="tat-totals-table">
                <tr>
                    <td class="lbl">Subtotal</td>
                    <td class="val">{{ $moneda }}{{ number_format($sub, 2) }}</td>
                </tr>
                @if($des > 0)
                <tr>
                    <td class="lbl">Descuento</td>
                    <td class="val" style="color: #dc2626;">- {{ $moneda }}{{ number_format($des, 2) }}</td>
                </tr>
                @endif
                <tr>
                    <td class="lbl">{{ $lblImp }}</td>
                    <td class="val">{{ $moneda }}{{ number_format($imp, 2) }}</td>
                </tr>
                <tr class="tat-total-highlight">
                    <td class="lbl">Total</td>
                    <td class="val">{{ $moneda }}{{ number_format($tot, 2) }}</td>
                </tr>

                @if(!empty($anticipo))
                <tr class="tat-extra-row">
                    <td class="lbl">Anticipo compra de materiales</td>
                    <td class="val">{{ $moneda }}{{ number_format($anticipo, 2) }}</td>
                </tr>
                <tr class="tat-extra-row">
                    <td class="lbl">Saldo contra entrega del trabajo</td>
                    <td class="val">{{ $moneda }}{{ number_format($saldo, 2) }}</td>
                </tr>
                @endif
            </table>
        </td>
    </tr>
</table>
