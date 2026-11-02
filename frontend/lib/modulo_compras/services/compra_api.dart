import 'dart:convert';
import '../../utils/constants.dart';
import '../../services/api_services.dart';

class CompraApi {
  final String baseUrl = "$apiUrl/compras";

  Future<Map<String, dynamic>> getAll(
    String token, {
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? search,
    bool? esGasto,
    int? cuentaContableId,
    int page = 1,
    int perPage = 20,
  }) async {
    final api = ApiService();
    String query = '$baseUrl?page=$page&per_page=$perPage';
    if (fechaDesde != null && fechaDesde.isNotEmpty) query += '&fecha_desde=$fechaDesde';
    if (fechaHasta != null && fechaHasta.isNotEmpty) query += '&fecha_hasta=$fechaHasta';
    if (estado != null && estado.isNotEmpty && estado != 'todos') query += '&estado=$estado';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    if (esGasto != null) query += '&es_gasto=' + (esGasto ? '1' : '0');
    if (cuentaContableId != null) query += '&cuenta_contable_id=$cuentaContableId';
    
    final response = await api.get(query, token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? {};
    }
    throw Exception('Error al cargar compras');
  }

  Future<dynamic> create(String token, Map<String, dynamic> data) async {
    final api = ApiService();
    final response = await api.post(baseUrl, data, token: token);

    // 201 = compra nueva creada exitosamente
    // 200 = respuesta idempotente: el backend detectó el mismo idempotency_key
    //       y devuelve la compra existente sin duplicar ningún registro.
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al registrar compra: ${response.body}');
  }

  Future<String?> getReportePdfUrl(
    String token, {
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? search,
  }) async {
    final api = ApiService();
    String query = '$baseUrl/reporte/pdf-token?';
    if (fechaDesde != null && fechaDesde.isNotEmpty) query += '&fecha_desde=$fechaDesde';
    if (fechaHasta != null && fechaHasta.isNotEmpty) query += '&fecha_hasta=$fechaHasta';
    if (estado != null && estado.isNotEmpty && estado != 'todos') query += '&estado=$estado';
    if (search != null && search.isNotEmpty) query += '&search=$search';

    final response = await api.get(query, token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data']?['pdf_url'];
    }
    return null;
  }

  Future<String?> getCompraPdfUrl(String token, int compraId) async {
    final api = ApiService();
    final response = await api.get('$baseUrl/$compraId/pdf-token', token: token);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data']?['pdf_url'];
    }
    return null;
  }
}
