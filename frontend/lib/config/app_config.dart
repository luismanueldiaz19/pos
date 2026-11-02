/// ============================================================================
/// CONFIGURACIÓN CENTRALIZADA DEL SISTEMA (DEPLOYMENT CONFIG)
/// ============================================================================
/// Esta es la ÚNICA clase que necesitas modificar para desplegar el sistema
/// para cualquier cliente o negocio (Tienda, Cafetería, Fundación, etc.).
/// ============================================================================
class AppConfig {
  AppConfig._(); // Prevenir instanciación

  // ──────────────────────────────────────────────────────────────────────────
  // 1. CONEXIÓN AL BACKEND / SERVIDOR
  // ──────────────────────────────────────────────────────────────────────────
  /// URL del servidor API (sin barra final '/').
  // static const String serverUrl = 'https://tienda.comunidadfantino.site';
  static const String serverUrl = 'http://127.0.0.1:8000';

  /// Versión de la API backend (generalmente '/api/v2')
  static const String apiVersion = '/api/v2';

  /// URL completa para endpoints estándar
  static String get apiUrl => '$serverUrl$apiVersion';

  /// URL base para autenticación y rutas generales (/api)
  static String get apiBaseUrl => '$serverUrl/api';

  // ──────────────────────────────────────────────────────────────────────────
  // 2. DATOS DE LA EMPRESA / CLIENTE (Aparecen en Facturas, Tickets y Reportes)
  // ──────────────────────────────────────────────────────────────────────────
  /// Nombre comercial / Razón social
  static const String nombreEmpresa =
      'Fundación Centro de Evangelización Padre Fantino';

  /// Subtítulo / Slogan de la empresa
  static const String slogan = '';

  /// Nombre corto para tickets térmicos y encabezados compactos
  static const String shortName = 'C.E.P.F';

  /// Descripción institucional
  static const String description = 'Sistema POS Venta';

  /// RNC o Cédula fiscal de la empresa
  static const String rnc = '4-30-37238-2';

  /// Dirección física de la empresa
  static const String direccion =
      'Av. Presidente Antonio Guzmán Fernande, junumucu Las Vegas, tramo Controba-San Francisco de Macoris';
  static const String ciudad = 'Las Vegas';
  static const String pais = 'República Dominicana';

  /// Dirección completa formateada para impresión
  static String get direccionCompleta => direccion;

  /// Teléfono de contacto
  static const String telefonoPrincipal = '(809) 697-8028';
  static const String? telefonoSecundario = null;
  static const String whatsapp = '(809) 697-8028';

  /// Correo y sitio web
  static const String correo = '----';
  static const String sitioWeb = '---';

  // ──────────────────────────────────────────────────────────────────────────
  // 3. IDENTIDAD VISUAL (LOGOS Y FONDOS)
  // ──────────────────────────────────────────────────────────────────────────
  /// Logo principal (Login, Sidebar, etc.)
  static const String logoApp = 'assets/logo.jpeg';

  /// Logo sin fondo (Transparente para interfaces oscuras o claras)
  static const String logoSinFondo = 'assets/logo_sin_fondo.png';

  /// Logo que se imprime en las facturas y tickets térmicos
  static const String logoFactura = 'assets/logo.jpeg';

  /// Fondo de pantalla predeterminado
  static const String backgroundPrincipal = 'assets/background.png';

  // ──────────────────────────────────────────────────────────────────────────
  // 4. DATOS DEL SOFTWARE Y DESARROLLADOR
  // ──────────────────────────────────────────────────────────────────────────
  /// Nombre comercial del software
  static const String appName = 'Menuxa';

  /// Versión actual del software
  static const String appVersion = '2.0.0';

  /// Nombre de la empresa desarrolladora
  static const String developerName = 'Lwader-Soft';

  /// Sitio web del desarrollador
  static const String developerWeb = '------';

  /// Crédito en el ticket impreso (al final de la factura)
  static const String ticketCredit = 'Powered by $developerName';
}

/// Alias directo con la estructura requerida
class AppInfo {
  AppInfo._();

  static const String name = AppConfig.nombreEmpresa;
  static const String subtitle = AppConfig.slogan;
  static const String description = AppConfig.description;
  static const String shortName = AppConfig.shortName;
  static const String address = AppConfig.direccion;
  static const String phone = AppConfig.telefonoPrincipal;
  static const String rnc = AppConfig.rnc;
}
