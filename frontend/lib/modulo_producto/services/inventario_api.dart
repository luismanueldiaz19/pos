import 'dart:convert';
import '../../services/api_services.dart';
import '../../utils/constants.dart';
import '../models/movimiento_inventario.dart';
import '../models/producto.dart';

class InventarioApi {
  final ApiService api = ApiService();
  final String baseUrl = "$hostName/api/inventario";

  Future<List<MovimientoInventario>> fetchMovimientos(
    String token, {
    String? search,
    String? tipo,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (tipo != null && tipo.isNotEmpty && tipo != 'TODOS') queryParams['tipo'] = tipo;
    if (fechaDesde != null && fechaDesde.isNotEmpty) queryParams['fecha_desde'] = fechaDesde;
    if (fechaHasta != null && fechaHasta.isNotEmpty) queryParams['fecha_hasta'] = fechaHasta;

    String url = "$baseUrl/movimientos";
    if (queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      url = "$url?$queryString";
    }

    final response = await api.get(url, token: token);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];
      return data.map((e) => MovimientoInventario.fromJson(e)).toList();
    }
    throw Exception("Error al cargar movimientos: ${response.body}");
  }

  Future<Map<String, dynamic>> fetchExistencias(
    String token, {
    String? search,
    int? categoriaId,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoriaId != null) queryParams['categoria_id'] = categoriaId.toString();

    String url = "$baseUrl/existencias";
    if (queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      url = "$url?$queryString";
    }

    final response = await api.get(url, token: token);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? {};
    }
    throw Exception("Error al cargar existencias: ${response.body}");
  }

  Future<List<Producto>> fetchAlertas(String token) async {
    final response = await api.get("$baseUrl/alertas-stock", token: token);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];
      return data.map((e) => Producto.fromJson(e)).toList();
    }
    throw Exception("Error al cargar alertas de stock: ${response.body}");
  }

  Future<MovimientoInventario> registrarAjuste(
    int productoId,
    String tipo,
    double cantidad,
    String motivo,
    String token,
  ) async {
    final response = await api.post(
      "$baseUrl/ajuste",
      {
        'producto_id': productoId,
        'tipo': tipo,
        'cantidad': cantidad,
        'motivo': motivo,
      },
      token: token,
    );

    if (response.statusCode == 201) {
      final value = jsonDecode(response.body);
      return MovimientoInventario.fromJson(value['data']);
    }

    final decoded = jsonDecode(response.body);
    final errorMsg = decoded['message'] ?? decoded['error'] ?? response.body;
    throw Exception(errorMsg);
  }

  Future<String?> getReportePdfUrl(
    String token, {
    required String tipoReporte,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, String>{
      'tipo_reporte': tipoReporte,
    };
    if (filters != null) {
      filters.forEach((k, v) {
        if (v != null && v.toString().isNotEmpty) {
          queryParams[k] = v.toString();
        }
      });
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final url = "$baseUrl/reporte/pdf-token?$queryString";

    final response = await api.get(url, token: token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']?['pdf_url'];
    }
    return null;
  }
}
