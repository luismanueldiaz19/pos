import 'package:flutter_riverpod/legacy.dart';
import '../models/movimiento_inventario.dart';
import '../models/producto.dart';
import '../services/inventario_api.dart';

class InventarioState {
  final bool isLoading;
  final String? error;
  final List<MovimientoInventario> movimientos;
  final Map<String, dynamic> existenciasResumen;
  final List<dynamic> existenciasProductos;
  final List<Producto> alertas;
  final String filtroTipo;
  final String filtroSearch;

  InventarioState({
    this.isLoading = false,
    this.error,
    this.movimientos = const [],
    this.existenciasResumen = const {},
    this.existenciasProductos = const [],
    this.alertas = const [],
    this.filtroTipo = 'TODOS',
    this.filtroSearch = '',
  });

  InventarioState copyWith({
    bool? isLoading,
    String? error,
    List<MovimientoInventario>? movimientos,
    Map<String, dynamic>? existenciasResumen,
    List<dynamic>? existenciasProductos,
    List<Producto>? alertas,
    String? filtroTipo,
    String? filtroSearch,
  }) {
    return InventarioState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      movimientos: movimientos ?? this.movimientos,
      existenciasResumen: existenciasResumen ?? this.existenciasResumen,
      existenciasProductos: existenciasProductos ?? this.existenciasProductos,
      alertas: alertas ?? this.alertas,
      filtroTipo: filtroTipo ?? this.filtroTipo,
      filtroSearch: filtroSearch ?? this.filtroSearch,
    );
  }
}

final inventarioProvider = StateNotifierProvider<InventarioNotifier, InventarioState>((ref) {
  return InventarioNotifier();
});

class InventarioNotifier extends StateNotifier<InventarioState> {
  InventarioNotifier() : super(InventarioState());

  final _api = InventarioApi();

  Future<void> loadAll(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final futures = await Future.wait([
        _api.fetchMovimientos(token, search: state.filtroSearch, tipo: state.filtroTipo),
        _api.fetchExistencias(token, search: state.filtroSearch),
        _api.fetchAlertas(token),
      ]);

      final movimientos = futures[0] as List<MovimientoInventario>;
      final existenciasData = futures[1] as Map<String, dynamic>;
      final alertas = futures[2] as List<Producto>;

      state = state.copyWith(
        isLoading: false,
        movimientos: movimientos,
        existenciasResumen: existenciasData['resumen'] ?? {},
        existenciasProductos: existenciasData['productos'] ?? [],
        alertas: alertas,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMovimientos(String token, {String? search, String? tipo}) async {
    final s = search ?? state.filtroSearch;
    final t = tipo ?? state.filtroTipo;
    state = state.copyWith(isLoading: true, error: null, filtroSearch: s, filtroTipo: t);
    try {
      final movimientos = await _api.fetchMovimientos(token, search: s, tipo: t);
      state = state.copyWith(isLoading: false, movimientos: movimientos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadExistencias(String token, {String? search, int? categoriaId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.fetchExistencias(token, search: search, categoriaId: categoriaId);
      state = state.copyWith(
        isLoading: false,
        existenciasResumen: data['resumen'] ?? {},
        existenciasProductos: data['productos'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAlertas(String token) async {
    try {
      final alertas = await _api.fetchAlertas(token);
      state = state.copyWith(alertas: alertas);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> registrarAjuste(
    int productoId,
    String tipo,
    double cantidad,
    String motivo,
    String token,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.registrarAjuste(productoId, tipo, cantidad, motivo, token);
      await loadAll(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<String?> obtenerPdfReporteUrl(
    String token, {
    required String tipoReporte,
    Map<String, dynamic>? filters,
  }) async {
    try {
      return await _api.getReportePdfUrl(token, tipoReporte: tipoReporte, filters: filters);
    } catch (_) {
      return null;
    }
  }
}
