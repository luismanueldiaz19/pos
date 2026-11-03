@php
    // Normalización de datos de la empresa con fallbacks automáticos
    $comp = $company ?? [];
    $empresaNombre = !empty($comp['nombre']) ? $comp['nombre'] : (!empty($comp['name']) ? $comp['name'] : config('company.nombre', 'Fundación Centro de Evangelización Padre Fantino'));
    $empresaRnc = !empty($comp['rnc']) ? $comp['rnc'] : config('company.rnc', '4-30-37238-2');
    $empresaDireccion = !empty($comp['direccion']) ? $comp['direccion'] : (!empty($comp['address']) ? $comp['address'] : config('company.direccion', ''));
    $empresaTelefono = !empty($comp['telefono']) ? $comp['telefono'] : (!empty($comp['phone']) ? $comp['phone'] : config('company.telefono', ''));
    $empresaEmail = !empty($comp['email']) ? $comp['email'] : config('company.email', '');

    // Formateo de fecha de emisión
    $fechaEmision = $fecha ?? ($fechaGeneracion ?? now());
    if ($fechaEmision instanceof \DateTimeInterface) {
        $fechaTexto = $fechaEmision->format('d/m/Y h:i A');
    } else {
        $fechaTexto = (string) $fechaEmision;
    }

    $tituloDoc = $titulo ?? 'DOCUMENTO OFICIAL';
    $subtituloDoc = $subtitulo ?? null;
    $usuarioDoc = $usuario ?? ($usuarioName ?? 'Sistema');
    $numeroDoc = $numeroDocumento ?? null;
    $estadoDoc = $estado ?? null;
    $logoSrc = $base64Logo ?? null;

    // Iniciales para monograma si no hay logo
    $palabras = explode(' ', trim($empresaNombre));
    $monograma = '';
    foreach (array_slice($palabras, 0, 3) as $p) {
        if (!empty($p)) $monograma .= strtoupper(mb_substr($p, 0, 1));
    }
@endphp

<!-- COMPONENTE GENERAL DE ENCABEZADO (DISEÑO CORPORATIVO GOOGLE WORKSPACE / MATERIAL 3) -->
<style>
    .gh-header-container {
        width: 100%;
        background-color: #0f172a;
        color: #ffffff;
        border-radius: 8px 8px 0 0;
        padding: 16px 22px;
        margin-bottom: 0;
    }
    .gh-table {
        width: 100%;
        border-collapse: collapse;
        border: none;
    }
    .gh-table td {
        vertical-align: middle;
        padding: 0;
        border: none;
    }
    .gh-logo-img {
        max-height: 44px;
        max-width: 180px;
        margin-bottom: 6px;
        display: block;
    }
    .gh-monogram {
        display: inline-block;
        background-color: #1e293b;
        border: 1px solid #334155;
        color: #38bdf8;
        font-weight: 900;
        font-size: 13px;
        letter-spacing: 1.5px;
        padding: 4px 10px;
        border-radius: 6px;
        margin-bottom: 6px;
    }
    .gh-company-name {
        font-size: 18px;
        font-weight: 900;
        letter-spacing: 0.3px;
        color: #ffffff;
        line-height: 1.2;
    }
    .gh-company-sub {
        font-size: 10px;
        color: #cbd5e1;
        margin-top: 4px;
        line-height: 1.4;
    }
    .gh-rnc-badge {
        display: inline-block;
        background-color: #1e293b;
        color: #93c5fd;
        border: 1px solid #3b82f6;
        padding: 1px 6px;
        border-radius: 4px;
        font-weight: bold;
        font-size: 9.5px;
        margin-right: 6px;
    }
    .gh-meta-right {
        text-align: right;
    }
    .gh-subtitle-pill {
        display: inline-block;
        background-color: #1e293b;
        color: #38bdf8;
        border: 1px solid #0284c7;
        font-size: 9px;
        font-weight: 800;
        text-transform: uppercase;
        letter-spacing: 1px;
        padding: 2px 8px;
        border-radius: 12px;
        margin-bottom: 4px;
    }
    .gh-title {
        font-size: 19px;
        font-weight: 900;
        color: #ffffff;
        letter-spacing: 0.5px;
        line-height: 1.15;
    }
    .gh-doc-number {
        font-size: 16px;
        font-weight: 900;
        color: #f8fafc;
        margin-top: 2px;
        letter-spacing: 0.5px;
    }
    .gh-status-pill {
        display: inline-block;
        padding: 2px 8px;
        border-radius: 10px;
        font-size: 8.5px;
        font-weight: 800;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        margin-top: 3px;
    }
    .gh-status-pagada { background: #dcfce7; color: #15803d; }
    .gh-status-pendiente { background: #fef3c7; color: #b45309; }
    .gh-status-anulada { background: #fee2e2; color: #b91c1c; }
    .gh-status-default { background: #e2e8f0; color: #334155; }
    .gh-date-box {
        font-size: 9.5px;
        color: #94a3b8;
        margin-top: 4px;
        line-height: 1.35;
    }
    .gh-date-box strong {
        color: #e2e8f0;
    }
    .gh-accent-bar {
        width: 100%;
        height: 3px;
        background-color: #1a73e8; /* Google Blue */
        margin-bottom: 12px;
        border-radius: 0 0 6px 6px;
    }
</style>

<div class="gh-header-container">
    <table class="gh-table">
        <tr>
            <!-- COLUMNA IZQUIERDA: IDENTIDAD Y DATOS DE LA EMPRESA -->
            <td style="width: 58%; text-align: left;">
                @if(!empty($logoSrc))
                    <img src="{{ $logoSrc }}" class="gh-logo-img" alt="Logo Corporativo">
                @else
                    <div class="gh-monogram">{{ $monograma ?: 'POS' }}</div>
                @endif
                <div class="gh-company-name">{{ $empresaNombre }}</div>
                <div class="gh-company-sub">
                    <span class="gh-rnc-badge">RNC: {{ $empresaRnc }}</span>
                    @if(!empty($empresaTelefono))
                        <span>Tel: {{ $empresaTelefono }}</span>
                    @endif
                    @if(!empty($empresaEmail))
                        <span>&nbsp;|&nbsp; {{ $empresaEmail }}</span>
                    @endif
                    @if(!empty($empresaDireccion))
                        <div style="margin-top: 3px; color: #94a3b8;">{{ $empresaDireccion }}</div>
                    @endif
                </div>
            </td>

            <!-- COLUMNA DERECHA: TÍTULO, SUBTÍTULO, METADATOS Y FECHAS -->
            <td style="width: 42%;" class="gh-meta-right">
                @if(!empty($subtituloDoc))
                    <div class="gh-subtitle-pill">{{ $subtituloDoc }}</div><br>
                @endif
                <div class="gh-title">{{ $tituloDoc }}</div>

                @if(!empty($numeroDoc))
                    <div class="gh-doc-number"># {{ $numeroDoc }}</div>
                @endif

                @if(!empty($estadoDoc))
                    @php
                        $estUpper = strtoupper((string) $estadoDoc);
                        $estClass = 'gh-status-default';
                        if (in_array($estUpper, ['PAGADA', 'COMPLETADO', 'ACTIVO', 'APROBADA'])) $estClass = 'gh-status-pagada';
                        elseif (in_array($estUpper, ['PENDIENTE', 'POR COBRAR', 'EMITIDA'])) $estClass = 'gh-status-pendiente';
                        elseif (in_array($estUpper, ['ANULADA', 'CANCELADA', 'RECHAZADA'])) $estClass = 'gh-status-anulada';
                    @endphp
                    <div>
                        <span class="gh-status-pill {{ $estClass }}">{{ $estUpper }}</span>
                    </div>
                @endif

                <div class="gh-date-box">
                    Emisión: <strong>{{ $fechaTexto }}</strong>
                    @if(!empty($usuarioDoc))
                        <br>Generado por: <strong>{{ $usuarioDoc }}</strong>
                    @endif
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="gh-accent-bar"></div>

