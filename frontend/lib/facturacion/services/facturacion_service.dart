import 'dart:convert';
import '../models/factura_item.dart';
import '../../../modulo_cliente/models/cliente.dart';
import '../../../model/comprobante.dart';
import '../../../services/api_services.dart';
import '../../../utils/constants.dart';

class FacturacionService {
  final ApiService _api = ApiService();
  final String _baseUrl = "$hostName/api";

  Future<Map<String, dynamic>> crearFactura({
    required Cliente cliente,
    required Comprobante comprobante,
    required List<FacturaItem> items,
    required String token,
    required int userId,
    String tipoFactura = 'contado',
    int diasCredito = 0,
    String nota = "",
    Map<String, dynamic>? pago,
  }) async {
    try {
      final payload = {
        "cliente_id": cliente.id,
        "ncf_secuencia_id": comprobante.id,
        "user_id": userId,
        "tipo_factura": tipoFactura,
        "dias_credito": diasCredito,
        "nota": nota,
        "pago": pago,
        "fecha_emision": DateTime.now().toIso8601String(),
        "fecha_vencimiento": DateTime.now()
            .add(Duration(days: diasCredito))
            .toIso8601String(),
        "detalles": items
            .map(
              (item) => {
                "producto_id": int.tryParse(item.id),
                "descripcion": item.descripcion,
                "cantidad": item.cantidad,
                "precio": item.precio,
                "itbis_porcentaje": item.itbisPorcentaje,
                "itbis": item.montoItbis,
                "descuento_porcentaje": item.descuentoPorcentaje,
                "descuento": item.montoDescuento,
                "subtotal": item.subtotal,
                "total": item.total,
              },
            )
            .toList(),
      };

      final response = await _api.post(
        "$_baseUrl/facturas",
        payload,
        token: token,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data['error'] ?? data['message'] ?? "Error desconocido",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> getHistorial({
    required String token,
    Map<String, String>? filters,
  }) async {
    try {
      String query = "";
      if (filters != null && filters.isNotEmpty) {
        query =
            "?${filters.entries.map((e) => "${e.key}=${e.value}").join("&")}";
      }

      final response = await _api.get("$_baseUrl/facturas$query", token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": data['data'],
          "resumen": data['resumen'],
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error al obtener facturas",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> getReportes({
    required String token,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      String query = "";
      List<String> params = [];
      if (fechaDesde != null) params.add("fecha_desde=$fechaDesde");
      if (fechaHasta != null) params.add("fecha_hasta=$fechaHasta");
      if (params.isNotEmpty) query = "?${params.join("&")}";

      final response = await _api.get(
        "$_baseUrl/facturas/reportes$query",
        token: token,
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return {
          "success": false,
          "message": "Error al procesar respuesta del servidor (JSON inválido)",
        };
      }

      if (response.statusCode == 200) {
        return {"success": true, "data": data['data']};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error al obtener reportes",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> generarNotaCredito(
    String token,
    int facturaId,
    List<Map<String, dynamic>> detalles,
    String motivo,
  ) async {
    final response = await _api.post(
      '$_baseUrl/facturas/$facturaId/nota-credito',
      {'detalles': detalles, 'motivo': motivo},
      token: token,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      try {
        final decoded = jsonDecode(response.body);
        final errMsg = decoded['error'] ?? decoded['message'] ?? response.body;
        throw Exception(errMsg);
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) {
          rethrow;
        }
        throw Exception('Error al generar la nota de crédito: ${response.body}');
      }
    }

    final data = jsonDecode(response.body);
    return (data['data'] as Map<String, dynamic>?) ??
        <String, dynamic>{'id': data['data']?['id']};
  }

  Future<String?> getNotaCreditoPdfUrl(String token, int id) async {
    try {
      final response = await _api.get(
        '$_baseUrl/notas-credito/$id/pdf-url',
        token: token,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> getNotasCredito({
    required String token,
    Map<String, String>? filters,
  }) async {
    try {
      String query = "";
      if (filters != null && filters.isNotEmpty) {
        query =
            "?${filters.entries.map((e) => "${e.key}=${e.value}").join("&")}";
      }

      final response = await _api.get(
        "$_baseUrl/notas-credito$query",
        token: token,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": data['data'],
          "resumen": data['resumen'],
        };
      } else {
        return {
          "success": false,
          "message": response.statusCode == 500
              ? "Ocurrió un error interno en el servidor."
              : (data['message'] ?? "Error al obtener notas de crédito"),
        };
      }
    } catch (e) {
      return {"success": false, "message": "Ocurrió un error de conexión."};
    }
  }

  Future<String?> getReportePdfUrl(
    String token, {
    Map<String, String>? filters,
  }) async {
    try {
      String query = "";
      if (filters != null && filters.isNotEmpty) {
        query =
            "?${filters.entries.map((e) => "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}").join("&")}";
      }
      final response = await _api.get(
        "$_baseUrl/facturas/reporte/pdf-token$query",
        token: token,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['pdf_url'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
