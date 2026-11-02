import '../config/app_config.dart';

/// Datos de la empresa / negocio.
/// La información activa se configura centralizadamente en [AppConfig].
class Company {
  // ── DATOS DEL NEGOCIO ─────────────────────────────
  final String nombre;
  final String slogan;
  final String rnc;
  final String direccion;
  final String ciudad;
  final String pais;
  final String telefono;
  final String? telefono2;
  final String? correo;
  final String? sitioWeb;
  final String? logoPath; // ruta del asset (ej: 'assets/logo.jpeg')

  const Company({
    required this.nombre,
    required this.rnc,
    required this.direccion,
    required this.ciudad,
    required this.pais,
    required this.telefono,
    this.slogan = '',
    this.telefono2,
    this.correo,
    this.sitioWeb,
    this.logoPath,
  });

  /// Dirección completa: "Calle X, Santiago, RD"
  String get direccionCompleta => '$direccion, $ciudad, $pais';

  /// Línea de encabezado de ticket: nombre + RNC
  String get encabezadoTicket => '$nombre  |  RNC: $rnc';

  // ──────────────────────────────────────────────────
  // INSTANCIA ACTIVA DEL NEGOCIO (Obtenida de AppConfig)
  // ──────────────────────────────────────────────────
  static const Company current = Company(
    nombre: AppConfig.nombreEmpresa,
    slogan: AppConfig.slogan,
    rnc: AppConfig.rnc,
    direccion: AppConfig.direccion,
    ciudad: AppConfig.ciudad,
    pais: AppConfig.pais,
    telefono: AppConfig.telefonoPrincipal,
    telefono2: AppConfig.telefonoSecundario,
    correo: AppConfig.correo,
    sitioWeb: AppConfig.sitioWeb,
    logoPath: AppConfig.logoFactura,
  );
}

// ──────────────────────────────────────────────────
// INFORMACIÓN DEL SISTEMA Y DESARROLLADOR
// ──────────────────────────────────────────────────
class SystemInfo {
  /// Nombre comercial del sistema
  static const String systemName = AppConfig.appName;

  /// Versión del sistema
  static const String version = AppConfig.appVersion;

  /// Empresa desarrolladora
  static const String developerName = AppConfig.developerName;

  /// Sitio web del desarrollador
  static const String developerWeb = AppConfig.developerWeb;

  /// Línea de crédito que aparece al pie del ticket
  static const String ticketCredit = AppConfig.ticketCredit;

  /// Línea corta para ticket (80mm)
  static const String ticketCreditShort =
      'Powered by ${AppConfig.developerName}';
}
