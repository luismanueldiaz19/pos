import 'dart:convert';
import 'package:sistema_restaurante/modulo_cliente/models/cliente.dart';
import 'package:sistema_restaurante/facturacion/models/factura_item.dart';
import 'package:sistema_restaurante/services/api_services.dart';
import 'package:sistema_restaurante/utils/constants.dart';

class CotizacionService {
  final ApiService _api = ApiService();
  final String _baseUrl = apiUrl;

  Future<Map<String, dynamic>> crearCotizacion({
    required Cliente cliente,
    required List<FacturaItem> items,
    required String token,
    String nota = "",
    int diasValidez = 15,
  }) async {
    try {
      final company = Company.current;
      final payload = {
        "cliente_id": cliente.id,
        "nota": nota,
        "company_name": company.nombre,
        "company_rnc": company.rnc ?? '',
        "company_address": company.direccionCompleta,
        "company_phone": company.telefono ?? '',
        "fecha_emision": DateTime.now().toIso8601String(),
        "fecha_vencimiento": DateTime.now()
            .add(Duration(days: diasValidez))
            .toIso8601String(),
        "detalles": items
            .map(
              (item) => {
                "producto_id": int.tryParse(item.id),
                "descripcion": item.descripcion,
                "cantidad": item.cantidad,
                "precio": item.precio,
                "itbis_porcentaje": item.itbisPorcentaje,
                "descuento_porcentaje": item.descuentoPorcentaje,
                "descuento": item.montoDescuento,
              },
            )
            .toList(),
      };

      final response = await _api.post(
        "$_baseUrl/cotizaciones",
        payload,
        token: token,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error desconocido",
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
      final company = Company.current;
      final queryParams = <String, String>{
        if (filters != null) ...filters,
        "company_name": company.nombre,
        "company_rnc": company.rnc,
        "company_address": company.direccionCompleta,
        "company_phone": company.telefono,
      };

      final query =
          "?" +
          queryParams.entries
              .map(
                (e) =>
                    "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}",
              )
              .join("&");

      final response = await _api.get(
        "$_baseUrl/cotizaciones$query",
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
          "message": data['message'] ?? "Error al obtener cotizaciones",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> getCotizacion({
    required String id,
    required String token,
  }) async {
    try {
      final company = Company.current;
      final query =
          "?company_name=${Uri.encodeComponent(company.nombre)}"
          "&company_rnc=${Uri.encodeComponent(company.rnc)}"
          "&company_address=${Uri.encodeComponent(company.direccionCompleta)}"
          "&company_phone=${Uri.encodeComponent(company.telefono)}";

      final response = await _api.get(
        "$_baseUrl/cotizaciones/$id$query",
        token: token,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data['data']};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error al obtener cotización",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> updateEstado({
    required String id,
    required String estado,
    required String token,
  }) async {
    try {
      final response = await _api.patch("$_baseUrl/cotizaciones/$id/estado", {
        "estado": estado,
      }, token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data['message']};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Error al actualizar",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }
}
