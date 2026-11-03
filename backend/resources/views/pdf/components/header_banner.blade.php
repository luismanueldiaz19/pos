@php
    $comp = $company ?? [];
    $empresaNombre = !empty($comp['nombre']) ? $comp['nombre'] : (!empty($comp['name']) ? $comp['name'] : config('company.nombre', 'LA SIERRA'));
    $empresaSubtitulo = $subtitulo ?? (!empty($comp['slogan']) ? $comp['slogan'] : null);
    $tituloDoc = $titulo ?? 'COTIZACIÓN';
    $numDoc = $numeroDocumento ?? (isset($cotizacion) ? str_pad((string)$cotizacion->id, 6, '0', STR_PAD_LEFT) : null);

    $asesorNombre = $emisorNombre ?? ($cotizacion->user->name ?? null);
    $asesorTelefono = $emisorTelefono ?? (!empty($comp['telefono']) ? $comp['telefono'] : config('company.telefono', '(809) 697-8028'));
    $asesorEmail = $emisorEmail ?? '---';

    // 1. Resolver el logo de forma robusta
    $logoSrc = $base64Logo ?? null;
    if (empty($logoSrc)) {
        $iconPath = public_path('images/app_icon.png');
        if (file_exists($iconPath)) {
            $type = pathinfo($iconPath, PATHINFO_EXTENSION);
            $data = file_get_contents($iconPath);
            $logoSrc = 'data:image/' . $type . ';base64,' . base64_encode($data);
        }
    }

    // Iniciales si no hay logo
    $palabras = explode(' ', trim($empresaNombre));
    $monograma = '';
    foreach (array_slice($palabras, 0, 2) as $p) {
        if (!empty($p)) $monograma .= strtoupper(mb_substr($p, 0, 1));
    }
    
    // Partición limpia del nombre en 2 líneas si es largo
    $lenNombre = mb_strlen($empresaNombre);
    if ($lenNombre > 25 && strpos($empresaNombre, ' ') !== false) {
        if (strpos($empresaNombre, 'Padre Fantino') !== false) {
            $nombreEmpresaHtml = str_replace('Padre Fantino', '<br>Padre Fantino', e($empresaNombre));
        } else {
            $mitad = (int)($lenNombre / 2);
            $pos = strpos($empresaNombre, ' ', $mitad);
            if ($pos !== false) {
                $nombreEmpresaHtml = e(substr($empresaNombre, 0, $pos)) . '<br>' . e(substr($empresaNombre, $pos + 1));
            } else {
                $nombreEmpresaHtml = e($empresaNombre);
            }
        }
        $fontSizeNombre = '13.5px';
    } else {
        $nombreEmpresaHtml = e($empresaNombre);
        $fontSizeNombre = $lenNombre > 18 ? '16px' : '20px';
    }

    // SVG del corte diagonal exacto en base64 para DomPDF con tonos suaves
    $dividerSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="78" viewBox="0 0 45 78">'
                . '<rect width="45" height="78" fill="#ffffff"/>'
                . '<polygon points="0,0 28,78 0,78" fill="#e26a3f"/>'
                . '<polygon points="12,0 45,0 45,78 40,78" fill="#1e2e4a"/>'
                . '</svg>';
    $dividerBase64 = 'data:image/svg+xml;base64,' . base64_encode($dividerSvg);
@endphp

<!-- ENCABEZADO GEOMÉTRICO (MODELO LA SIERRA) -->
<style>
    .hb-main-table {
        width: 100%;
        border-collapse: collapse;
        margin: 0 0 8px 0;
        padding: 0;
    }
    .hb-main-table td {
        padding: 0;
        margin: 0;
        border: none;
        vertical-align: middle;
    }
    .hb-orange-box {
        background-color: #e26a3f;
        height: 78px;
        width: 48%;
        padding: 12px 16px;
        border-top-left-radius: 6px;
    }
    .hb-divider-box {
        width: 45px;
        height: 78px;
        font-size: 0;
        line-height: 0;
        vertical-align: top !important;
    }
    .hb-navy-box {
        background-color: #1e2e4a;
        height: 78px;
        width: 46%;
        padding: 10px 18px;
        text-align: center;
        border-top-right-radius: 6px;
    }
    .hb-title {
        font-size: 23px;
        font-weight: 900;
        color: #ffffff;
        letter-spacing: 1.5px;
        line-height: 1.15;
        font-family: Arial, Helvetica, sans-serif;
    }
    .hb-num-doc {
        font-size: 13px;
        font-weight: 700;
        color: #ffffff;
        opacity: 0.9;
        margin-top: 3px;
        letter-spacing: 1px;
        font-family: Arial, Helvetica, sans-serif;
    }
    .hb-meta-advisor {
        width: 100%;
        border-collapse: collapse;
        margin-top: 4px;
        margin-bottom: 18px;
    }
    .hb-meta-advisor td {
        padding: 0;
        border: none;
    }
    .hb-advisor-text {
        text-align: right;
        padding-right: 2px;
        font-size: 11px;
        color: #475569;
        line-height: 1.45;
        font-family: Arial, Helvetica, sans-serif;
    }
    .hb-advisor-name {
        font-size: 13px;
        font-weight: 800;
        color: #0f172a;
    }
</style>

<table class="hb-main-table">
    <tr>
        <!-- BLOQUE NARANJA IZQUIERDO -->
        <td class="hb-orange-box">
            <table style="width: 100%; border-collapse: collapse;">
                <tr>
                    <td style="width: 46px; vertical-align: middle; padding: 0;">
                        @if(!empty($logoSrc))
                            <img src="{{ $logoSrc }}" width="44" height="44" style="width: 44px; height: 44px; display: block; border-radius: 4px;" alt="Logo">
                        @else
                            <div style="width: 38px; height: 38px; background-color: #1e2e4a; border-radius: 6px; text-align: center; line-height: 38px; color: #ffffff; font-size: 14px; font-weight: bold; border: 1.5px solid rgba(255,255,255,0.4);">
                                {{ $monograma ?: 'LS' }}
                            </div>
                        @endif
                    </td>
                    <td style="padding-left: 12px; vertical-align: middle;">
                        <div style="font-size: {{ $fontSizeNombre }}; font-weight: 900; color: #ffffff; letter-spacing: 0.3px; line-height: 1.25; font-family: Arial, Helvetica, sans-serif;">
                            {!! $nombreEmpresaHtml !!}
                        </div>
                        @if(!empty($empresaSubtitulo))
                        <div style="font-size: 11px; color: #ffffff; opacity: 0.95; margin-top: 3px; font-family: Arial, Helvetica, sans-serif;">
                            {{ $empresaSubtitulo }}
                        </div>
                        @endif
                    </td>
                </tr>
            </table>
        </td>

        <!-- CORTE DIAGONAL PARALELO -->
        <td class="hb-divider-box">
            <img src="{{ $dividerBase64 }}" width="45" height="78" style="display: block; margin: 0; padding: 0;" alt="">
        </td>

        <!-- BLOQUE AZUL MARINO DERECHO (TÍTULO EN 2 LÍNEAS SI APLICA) -->
        <td class="hb-navy-box">
            <div class="hb-title">{{ $tituloDoc }}</div>
            @if(!empty($numDoc))
                <div class="hb-num-doc">No. {{ $numDoc }}</div>
            @endif
        </td>
    </tr>
</table>

<!-- METADATOS DEL ASESOR / EMISOR (DEBAJO DEL BANNER A LA DERECHA) -->
<table class="hb-meta-advisor">
    <tr>
        <td style="width: 40%;"></td>
        <td style="width: 60%;" class="hb-advisor-text">
            @if(!empty($asesorNombre))
                <div class="hb-advisor-name">{{ $asesorNombre }}</div>
            @endif
            @if(!empty($asesorTelefono))
                <div>{{ $asesorTelefono }}</div>
            @endif
            @if(!empty($asesorEmail))
                <div>{{ $asesorEmail }}</div>
            @endif
        </td>
    </tr>
</table>
