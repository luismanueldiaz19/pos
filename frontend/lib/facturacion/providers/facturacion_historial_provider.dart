import 'package:flutter_riverpod/legacy.dart';
import '../../model/factura.dart';
import '../services/facturacion_service.dart';

class FacturacionHistorialState {
  final List<Factura> historial;
  final bool isLoading;
  final String? error;
  final Map<String, String> filters;

  final Map<String, dynamic>? resumen;
  final int currentPage;
  final int lastPage;
  final int total;

  FacturacionHistorialState({
    this.historial = const [],
    this.isLoading = false,
    this.error,
    this.filters = const {},
    this.resumen,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  Map<String, double> get totales {
    double subtotal = 0;
    double itbis = 0;
    double descuento = 0;
    double total = 0;

    for (var f in historial) {
      if (f.estado != 'anulada') {
        subtotal += double.tryParse(f.subtotal ?? '0') ?? 0;
        itbis += double.tryParse(f.itbis ?? '0') ?? 0;
        descuento += double.tryParse(f.descuentoTotal ?? '0') ?? 0;
        total += double.tryParse(f.total ?? '0') ?? 0;
      }
    }

    return {
      'subtotal': subtotal,
      'itbis': itbis,
      'descuento': descuento,
      'total': total,
    };
  }

  FacturacionHistorialState copyWith({
    List<Factura>? historial,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, String>? filters,
    Map<String, dynamic>? resumen,
    int? currentPage,
    int? lastPage,
    int? total,
  }) {
    return FacturacionHistorialState(
      historial: historial ?? this.historial,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      resumen: resumen ?? this.resumen,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
    );
  }
}

class FacturacionHistorialNotifier
    extends StateNotifier<FacturacionHistorialState> {
  final FacturacionService _service = FacturacionService();

  FacturacionHistorialNotifier() : super(FacturacionHistorialState());

  Future<void> fetchHistorial(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Preparar filtros incluyendo paginación
    final queryFilters = Map<String, String>.from(state.filters);
    queryFilters['page'] = state.currentPage.toString();

    final result = await _service.getHistorial(
      token: token,
      filters: queryFilters,
    );

    if (result['success']) {
      final dataObj = result['data'] ?? {};
      final List<dynamic> dataList = dataObj['data'] ?? [];

      final int current = dataObj['current_page'] ?? 1;
      final int last = dataObj['last_page'] ?? 1;
      final int totalItems = dataObj['total'] ?? 0;

      final List<Factura> facturas = dataList
          .map((json) => Factura.fromJson(json))
          .toList();
      state = state.copyWith(
        isLoading: false,
        historial: facturas,
        resumen: result['resumen'],
        currentPage: current,
        lastPage: last,
        total: totalItems,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result['message']);
    }
  }

  void updateFilters(
    String token,
    Map<String, String> newFilters, {
    bool replace = false,
  }) {
    state = state.copyWith(
      filters: replace ? newFilters : {...state.filters, ...newFilters},
      currentPage: 1, // Resetear paginación al cambiar filtros
    );
    fetchHistorial(token);
  }

  void setPage(String token, int page) {
    state = state.copyWith(currentPage: page);
    fetchHistorial(token);
  }

  void clearFilters(String token) {
    state = state.copyWith(filters: {}, currentPage: 1);
    fetchHistorial(token);
  }

  Future<String?> obtenerPdfReporteUrl(String token) async {
    return await _service.getReportePdfUrl(token, filters: state.filters);
  }

  Future<Map<String, dynamic>?> generarNotaCredito(
    String token,
    int facturaId,
    List<Map<String, dynamic>> detalles,
    String motivo,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _service.generarNotaCredito(
        token,
        facturaId,
        detalles,
        motivo,
      );
      await fetchHistorial(token);
      return data;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final facturacionHistorialProvider =
    StateNotifierProvider<
      FacturacionHistorialNotifier,
      FacturacionHistorialState
    >((ref) {
      return FacturacionHistorialNotifier();
    });
