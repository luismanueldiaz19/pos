import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../model/company.dart';

// Re-exportar para compatibilidad en todo el proyecto
export '../config/app_config.dart';
export '../model/company.dart';

// ──────────────────────────────────────────────────
// ALIASES CENTRALIZADOS DESDE AppConfig
// (Modifica directamente lib/config/app_config.dart para cambiar de negocio)
// ──────────────────────────────────────────────────
const String appName = AppConfig.appName;
const String sloganApp = AppConfig.slogan;
const String developer = AppConfig.developerName;
const String developerVersion = AppConfig.appVersion;

final String menuxaAIKeyAPY = ''; // La clave se gestiona en el backend (.env)

const String logoApp = AppConfig.logoApp;
const String hostName = AppConfig.serverUrl;
const String apiUrl = '$hostName${AppConfig.apiVersion}';

const String logoSinFondo = AppConfig.logoSinFondo;
const String logoFactura = AppConfig.logoFactura;

const String background = AppConfig.backgroundCafeteria;

const double kwidth = 250;

String firmaLu = 'assets/logo_lwader.png';

String developerFirma = AppConfig.developerName;

String textConfirmacion = '👉🏼 Esta seguro realizar el pedido ? 👈🏼';
String textConfAction = '👉🏼 Esta seguro realizar la acción ? 👈🏼';
String eliminarMjs = '🥺 Esta seguro de eliminar 🥺';
String confirmarMjs =
    '👉🏼Esta seguro de confirmar el despacho de las facturas?👈🏼';

String actionMjs = '👉🏼Esta seguro de confirmar el tiempo ?👈🏼';

final List<String> estadoHojaList = [
  'PENDIENTE'.toUpperCase(),
  'EN PROCESO'.toUpperCase(),
  'EN PRODUCCION'.toUpperCase(),
  'PAUSADO'.toUpperCase(),
  'COMPLETADO'.toUpperCase(),
  'CANCELADO'.toUpperCase(),
  'NORMAL'.toUpperCase(),
];

final Map<String?, Color> estadoHojaColores = {
  'PENDIENTE'.toUpperCase(): Colors.orange,
  'EN PROCESO'.toUpperCase(): Colors.blue,
  'EN PRODUCCION'.toUpperCase(): Colors.indigo,
  'PAUSADO'.toUpperCase(): Colors.grey,
  'COMPLETADO'.toUpperCase(): Colors.green,
  'CANCELADO'.toUpperCase(): Colors.red,
  'NORMAL'.toUpperCase(): Colors.white,
};

List<String>? priorityList = ['NORMAL', 'EMERGENCIA', 'PRIORIDAD', 'AGREGADO'];

Map<String, Color> priorityColors = {
  'NORMAL': Colors.white,
  'EMERGENCIA': Colors.red.shade400,
  'PRIORIDAD': Colors.orange,
  'AGREGADO': Colors.yellow.shade300,
};

Map<String, IconData> priorityIcons = {
  'NORMAL': Icons.check_circle_outline,
  'EMERGENCIA': Icons.warning_amber_rounded,
  'PRIORIDAD': Icons.priority_high,
  'AGREGADO': Icons.add_circle_outline,
};

Color getColorPriority(String priorityName) {
  return priorityColors[priorityName] ?? Colors.white;
}

String getClientePorPrioridad(String prioridad) {
  switch (prioridad) {
    case 'Normal':
      return 'Normal';
    case 'Hoja verde':
      return 'Emergencia';
    case 'Hoja naranja':
      return 'Prioridad';
    case 'Hoja amarilla':
      return 'Agregado';
    default:
      return 'Normal';
  }
}

// ──────────────────────────────────────────────────
// DATOS DE LA EMPRESA (Compatibilidad hacia atrás)
// ──────────────────────────────────────────────────
String get empresaNombre => Company.current.nombre;
String get empresaDireccion => Company.current.direccionCompleta;
String get empresaRNC => Company.current.rnc;
