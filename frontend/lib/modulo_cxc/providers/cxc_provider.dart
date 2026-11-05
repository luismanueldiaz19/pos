import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../providers/auth_provider.dart';
import '../models/pago_cxc.dart';
import '../models/cxc.dart';
import '../api/cxc_api.dart';

class CxcState {
  final bool isLoading;
  final List<CuentaPorCobrar> cxcs;
  final List<PagoCxc> historialPagos;
  final String? error;
  final bool isLoadingHistorial;
  final String? errorHistorial;

  CxcState({
    this.isLoading = false,
    this.cxcs = const [],
    this.historialPagos = const [],
    this.error,
    this.isLoadingHistorial = false,
    this.errorHistorial,
  });

  CxcState copyWith({
    bool? isLoading,
    List<CuentaPorCobrar>? cxcs,
    List<PagoCxc>? historialPagos,
    String? error,
    bool? isLoadingHistorial,
    String? errorHistorial,
  }) {
    return CxcState(
      isLoading: isLoading ?? this.isLoading,
      cxcs: cxcs ?? this.cxcs,
      historialPagos: historialPagos ?? this.historialPagos,
      error: error,
      isLoadingHistorial: isLoadingHistorial ?? this.isLoadingHistorial,
      errorHistorial: errorHistorial,
    );
  }
}

class CxcNotifier extends StateNotifier<CxcState> {
  final Ref ref;
  final CxcApi api;

  CxcNotifier(this.ref, this.api) : super(CxcState()) {
    loadCxcs();
  }

  Future<void> loadCxcs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception('No autenticado');

      final data = await api.getCxcs(token);
      state = state.copyWith(isLoading: false, cxcs: data, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadHistorialPagos({Map<String, String>? filters}) async {
    state = state.copyWith(isLoadingHistorial: true, errorHistorial: null);
    try {
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception('No autenticado');

      final pagos = await api.getHistorialPagos(token, filters: filters);
      state = state.copyWith(
        isLoadingHistorial: false,
        historialPagos: pagos,
        errorHistorial: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistorial: false,
        errorHistorial: e.toString(),
      );
    }
  }

  Future<String?> obtenerPdfReporteUrl(
    String token, {
    Map<String, String>? filters,
  }) async {
    return await api.getReportePdfUrl(token, filters: filters);
  }

  Future<bool> registrarPago(int cxcId, Map<String, dynamic> data) async {
    try {
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception('No autenticado');

      final success = await api.registrarPago(token, cxcId, data);
      if (success) {
        await loadCxcs(); // Recargar después de pago
        await loadHistorialPagos(); // Recargar el historial también
      }
      return success;
    } catch (e) {
      throw Exception('Error al registrar cobro: $e');
    }
  }
}

final cxcProvider = StateNotifierProvider<CxcNotifier, CxcState>((ref) {
  return CxcNotifier(ref, CxcApi());
});
