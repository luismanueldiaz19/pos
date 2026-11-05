import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import '../model/user.dart';
import '../services/usuario_service.dart';

class UsuarioState {
  final List<User> usuarios;
  final List<String> rolesDisponibles;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? selectedRoleFilter;

  UsuarioState({
    this.usuarios = const [],
    this.rolesDisponibles = const [
      'admin',
      'cajero',
      'contador',
      'auxiliar contable',
    ],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.selectedRoleFilter,
  });

  UsuarioState copyWith({
    List<User>? usuarios,
    List<String>? rolesDisponibles,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? selectedRoleFilter,
    bool clearRoleFilter = false,
  }) {
    return UsuarioState(
      usuarios: usuarios ?? this.usuarios,
      rolesDisponibles: rolesDisponibles ?? this.rolesDisponibles,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRoleFilter: clearRoleFilter
          ? null
          : (selectedRoleFilter ?? this.selectedRoleFilter),
    );
  }
}

class UsuarioNotifier extends StateNotifier<UsuarioState> {
  final UsuarioService _service = UsuarioService();
  Timer? _debounce;

  UsuarioNotifier() : super(UsuarioState());

  Future<void> cargarDatos(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await cargarRoles(token, silent: true);
    await cargarUsuarios(token, silent: true);
    state = state.copyWith(isLoading: false);
  }

  Future<void> cargarRoles(String token, {bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, clearError: true);
    final res = await _service.getRoles(token);
    if (res['success'] == true) {
      final List<String> roles = List<String>.from(res['data'] ?? []);
      state = state.copyWith(
        rolesDisponibles: roles,
        isLoading: silent ? state.isLoading : false,
      );
    } else {
      state = state.copyWith(
        error: res['message'],
        isLoading: silent ? state.isLoading : false,
      );
    }
  }

  Future<void> cargarUsuarios(String token, {bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, clearError: true);
    final res = await _service.getUsuarios(
      token,
      search: state.searchQuery,
      role: state.selectedRoleFilter,
    );
    if (res['success'] == true) {
      final List<User> usuarios = List<User>.from(res['data'] ?? []);
      state = state.copyWith(
        usuarios: usuarios,
        isLoading: silent ? state.isLoading : false,
      );
    } else {
      state = state.copyWith(
        error: res['message'],
        isLoading: silent ? state.isLoading : false,
      );
    }
  }

  void onSearchChanged(String token, String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      cargarUsuarios(token);
    });
  }

  void filtrarPorRol(String token, String? role) {
    if (role == null || role.toLowerCase() == 'todos' || role == state.selectedRoleFilter) {
      state = state.copyWith(clearRoleFilter: true);
    } else {
      state = state.copyWith(selectedRoleFilter: role);
    }
    cargarUsuarios(token);
  }

  Future<bool> crearUsuario(String token, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final res = await _service.crearUsuario(token, data);
    state = state.copyWith(isLoading: false);

    if (res['success'] == true) {
      await cargarUsuarios(token);
      return true;
    } else {
      state = state.copyWith(error: res['message']);
      return false;
    }
  }

  Future<bool> actualizarUsuario(
    String token,
    int id,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final res = await _service.actualizarUsuario(token, id, data);
    state = state.copyWith(isLoading: false);

    if (res['success'] == true) {
      await cargarUsuarios(token);
      return true;
    } else {
      state = state.copyWith(error: res['message']);
      return false;
    }
  }

  Future<bool> eliminarUsuario(String token, int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final res = await _service.eliminarUsuario(token, id);
    state = state.copyWith(isLoading: false);

    if (res['success'] == true) {
      await cargarUsuarios(token);
      return true;
    } else {
      state = state.copyWith(error: res['message']);
      return false;
    }
  }
}

final usuarioProvider =
    StateNotifierProvider<UsuarioNotifier, UsuarioState>((ref) {
  return UsuarioNotifier();
});

