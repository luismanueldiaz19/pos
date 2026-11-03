@php
    $comp = $company ?? [];
    $tel = !empty($comp['telefono']) ? $comp['telefono'] : (!empty($comp['phone']) ? $comp['phone'] : config('company.telefono', '(809) 697-8028'));
    $email = '---';
    $web = '---';

    // SVG para el corte diagonal izquierdo del footer en tono suave
    $footerSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="35" height="44" viewBox="0 0 35 44">'
               . '<polygon points="35,0 35,44 0,44" fill="#e26a3f"/>'
               . '</svg>';
    $footerBase64 = 'data:image/svg+xml;base64,' . base64_encode($footerSvg);

    // SVGs circulares vectoriales de alta definición en tono suave
    $iconPhone = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="12" r="12" fill="#1e2e4a"/><path d="M6.62 10.79a15.05 15.05 0 006.59 6.59l2.2-2.2a1 1 0 011.02-.24c1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20a1 1 0 01-1 1A17 17 0 013 4a1 1 0 011-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z" fill="#ffffff" transform="scale(0.55) translate(10, 10)"/></svg>';
    $iconPhoneBase64 = 'data:image/svg+xml;base64,' . base64_encode($iconPhone);

    $iconMail = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="12" r="12" fill="#1e2e4a"/><path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z" fill="#ffffff" transform="scale(0.55) translate(10, 10)"/></svg>';
    $iconMailBase64 = 'data:image/svg+xml;base64,' . base64_encode($iconMail);

    $iconWeb = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="12" r="12" fill="#1e2e4a"/><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" fill="#ffffff" transform="scale(0.55) translate(10, 10)"/></svg>';
    $iconWebBase64 = 'data:image/svg+xml;base64,' . base64_encode($iconWeb);
@endphp

<!-- BANNER INFERIOR NARANJA (FOOTER MODELO LA SIERRA) -->
<style>
    .fb-wrapper {
        position: fixed;
        bottom: 30px;
        left: 38px;
        right: 38px;
    }
    .fb-table {
        width: 100%;
        border-collapse: collapse;
        margin: 0;
        padding: 0;
    }
    .fb-table td {
        padding: 0;
        margin: 0;
        border: none;
        vertical-align: middle;
    }
    .fb-diagonal-cell {
        width: 35px;
        height: 44px;
        font-size: 0;
        line-height: 0;
        vertical-align: bottom !important;
    }
    .fb-orange-content {
        background-color: #e26a3f;
        height: 44px;
        padding: 0 20px;
        color: #ffffff;
        text-align: center;
        font-size: 11.5px;
        font-weight: 700;
        border-bottom-right-radius: 9px;
        font-family: Arial, Helvetica, sans-serif;
    }
    .fb-item {
        display: inline-block;
        margin: 0 16px;
        color: #ffffff;
        text-decoration: none;
        vertical-align: middle;
    }
    .fb-icon-img {
        display: inline-block;
        vertical-align: middle;
        margin-right: 6px;
    }
</style>

<div class="fb-wrapper">
    <table class="fb-table">
        <tr>
            <!-- CORTE DIAGONAL ENTRADA IZQUIERDA -->
            <td class="fb-diagonal-cell">
                <img src="{{ $footerBase64 }}" width="35" height="44" style="display: block;" alt="">
            </td>

            <!-- CONTENIDO NARANJA CON CONTACTOS -->
            <td class="fb-orange-content">
                <span class="fb-item">
                    <img class="fb-icon-img" src="{{ $iconPhoneBase64 }}" width="20" height="20" alt="Tel">
                    {{ $tel }}
                </span>
                <span class="fb-item">
                    <img class="fb-icon-img" src="{{ $iconMailBase64 }}" width="20" height="20" alt="Mail">
                    {{ $email }}
                </span>
                <span class="fb-item">
                    <img class="fb-icon-img" src="{{ $iconWebBase64 }}" width="20" height="20" alt="Web">
                    {{ $web }}
                </span>
            </td>
        </tr>
    </table>
</div>
