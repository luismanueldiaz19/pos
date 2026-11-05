import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';
import '../models/cxc.dart';
import '../models/pago_cxc.dart';

class CxcApi {
  final String baseUrl = "$apiUrl/cxc";
  final ApiService api = ApiService();

  Future<List<CuentaPorCobrar>> getCxcs(String token) async {
    final response = await api.get(baseUrl, token: token);

    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      final List data = body is List
          ? body
          : (body is Map ? (body['data'] is List ? body['data'] : []) : []);
      return data.map((json) => CuentaPorCobrar.fromJson(json)).toList();
    } else {
      throw Exception(
        'Error al cargar las Cuentas por Cobrar: ${response.body}',
      );
    }
  }

  Future<bool> registrarPago(
    String token,
    int cxcId,
    Map<String, dynamic> pagoData,
  ) async {
    final response = await api.post(
      "$baseUrl/$cxcId/pagar",
      pagoData,
      token: token,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Error al registrar cobro: ${response.body}');
    }
  }

  Future<List<PagoCxc>> getHistorialPagos(
    String token, {
    Map<String, String>? filters,
  }) async {
    String query = "";
    if (filters != null && filters.isNotEmpty) {
      final parts = filters.entries
          .where((e) => e.value.trim().isNotEmpty)
          .map((e) => "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}");
      if (parts.isNotEmpty) {
        query = "?${parts.join("&")}";
      }
    }
    final response = await api.get("$baseUrl/pagos/historial$query", token: token);

    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      final List data = body is List
          ? body
          : (body is Map ? (body['data'] is List ? body['data'] : []) : []);
      return data.map((json) => PagoCxc.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar historial de pagos: ${response.body}');
    }
  }

  Future<String?> getReportePdfUrl(
    String token, {
    Map<String, String>? filters,
  }) async {
    try {
      String query = "";
      if (filters != null && filters.isNotEmpty) {
        final parts = filters.entries
            .where((e) => e.value.trim().isNotEmpty)
            .map((e) => "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}");
        if (parts.isNotEmpty) {
          query = "?${parts.join("&")}";
        }
      }
      final response = await api.get(
        "$baseUrl/pagos/reporte/pdf-token$query",
        token: token,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['pdf_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
