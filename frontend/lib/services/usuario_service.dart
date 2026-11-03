import 'dart:convert';
import '../model/user.dart';
import '../utils/constants.dart';
import 'api_services.dart';

class UsuarioService {
  final ApiService _api = ApiService();
  final String _baseUrl = '$hostName/api/usuarios';

  Future<Map<String, dynamic>> getUsuarios(
    String token, {
    String? search,
    String? role,
  }) async {
    try {
      final params = <String>[];
      if (search != null && search.trim().isNotEmpty) {
        params.add('search=${Uri.encodeComponent(search.trim())}');
      }
      if (role != null && role.isNotEmpty && role.toLowerCase() != 'todos') {
        params.add('role=${Uri.encodeComponent(role)}');
      }

      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _api.get('$_baseUrl$query', token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        final usuarios = list.map((json) => User.fromJson(json)).toList();
        return {'success': true, 'data': usuarios, 'total': data['total'] ?? 0};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener usuarios',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> getRoles(String token) async {
    try {
      final response = await _api.get('$_baseUrl/roles', token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        final roles = list.map((r) => r['name'].toString()).toList();
        return {'success': true, 'data': roles};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener roles',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> crearUsuario(
    String token,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _api.post(_baseUrl, payload, token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario creado correctamente',
          'data': User.fromJson(data['data']),
        };
      } else {
        final errors = data['errors'];
        String msg = data['message'] ?? 'Error al crear usuario';
        if (errors is Map) {
          msg = errors.values.map((v) => (v as List).join(' ')).join('\n');
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> actualizarUsuario(
    String token,
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _api.put('$_baseUrl/$id', payload, token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario actualizado correctamente',
          'data': User.fromJson(data['data']),
        };
      } else {
        final errors = data['errors'];
        String msg = data['message'] ?? 'Error al actualizar usuario';
        if (errors is Map) {
          msg = errors.values.map((v) => (v as List).join(' ')).join('\n');
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> eliminarUsuario(String token, int id) async {
    try {
      final response = await _api.delete('$_baseUrl/$id', token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario eliminado correctamente',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'No se pudo eliminar el usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

