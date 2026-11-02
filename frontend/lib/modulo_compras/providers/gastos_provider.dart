import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/compra.dart';
import '../services/compra_api.dart';
import '../../providers/auth_provider.dart';

final compraApiProvider = Provider((ref) => CompraApi());

class TotalesGastos {
  final double totalGastos;
  final double totalContado;
  final double totalCredito;
  final double totalItbis;
  final double totalSubtotal;
  final int cantidad;

  TotalesGastos({
    this.totalGastos = 0.0,
    this.totalContado = 0.0,
    this.totalCredito = 0.0,
    this.totalItbis = 0.0,
    this.totalSubtotal = 0.0,
    this.cantidad = 0,
  });
}

class GastosState {
  final bool isLoading;
  final List<Compra> gastos;
  final String? error;
  final TotalesGastos totales;

  // Filtros
  final String? fechaDesde;
  final String? fechaHasta;
  final String? estado;
  final String? tipoCompra; // 'todos', 'CONTADO', 'CREDITO'
  final int? cuentaContableId;
  final String search;

  GastosState({
    this.isLoading = false,
    this.gastos = const [],
    this.error,
    TotalesGastos? totales,
    this.fechaDesde,
    this.fechaHasta,
    this.estado = 'todos',
    this.tipoCompra = 'todos',
    this.cuentaContableId,
    this.search = '',
  }) : totales = totales ?? TotalesGastos();

  GastosState copyWith({
    bool? isLoading,
    List<Compra>? gastos,
    String? error,
    TotalesGastos? totales,
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? tipoCompra,
    int? cuentaContableId,
    bool clearCuenta = false,
    String? search,
  }) {
    return GastosState(
      isLoading: isLoading ?? this.isLoading,
      gastos: gastos ?? this.gastos,
      error: error ?? this.error,
      totales: totales ?? this.totales,
      fechaDesde: fechaDesde ?? this.fechaDesde,
      fechaHasta: fechaHasta ?? this.fechaHasta,
      estado: estado ?? this.estado,
      tipoCompra: tipoCompra ?? this.tipoCompra,
      cuentaContableId: clearCuenta ? null : (cuentaContableId ?? this.cuentaContableId),
      search: search ?? this.search,
    );
  }
}

class GastosNotifier extends StateNotifier<GastosState> {
  final CompraApi api;
  final String? token;

  GastosNotifier(this.api, this.token) : super(GastosState()) {
    if (token != null) {
      loadGastos();
    }
  }

  Future<void> loadGastos({
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? tipoCompra,
    int? cuentaContableId,
    bool clearCuenta = false,
    String? search,
  }) async {
    if (token == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      fechaDesde: fechaDesde ?? state.fechaDesde,
      fechaHasta: fechaHasta ?? state.fechaHasta,
      estado: estado ?? state.estado,
      tipoCompra: tipoCompra ?? state.tipoCompra,
      cuentaContableId: clearCuenta ? null : (cuentaContableId ?? state.cuentaContableId),
      clearCuenta: clearCuenta,
      search: search ?? state.search,
    );

    try {
      final response = await api.getAll(
        token!,
        fechaDesde: state.fechaDesde,
        fechaHasta: state.fechaHasta,
        estado: state.estado,
        search: state.search,
        esGasto: true,
        cuentaContableId: state.cuentaContableId,
        page: 1,
        perPage: 100, // Cargar hasta 100 gastos por consulta
      );

      final List<dynamic> dataList = response['data'] ?? [];
      var list = dataList.map((e) => Compra.fromJson(e)).toList();

      // Filtro local adicional de tipoCompra si se seleccionó CONTADO o CREDITO
      if (state.tipoCompra != null && state.tipoCompra != 'todos') {
        list = list.where((c) => c.tipoCompra.toUpperCase() == state.tipoCompra!.toUpperCase()).toList();
      }

      double totalGeneral = 0;
      double contado = 0;
      double credito = 0;
      double itbis = 0;
      double subtotal = 0;

      for (var c in list) {
        totalGeneral += c.total;
        itbis += c.impuestos;
        subtotal += c.subtotal;
        if (c.tipoCompra.toUpperCase() == 'CONTADO') {
          contado += c.total;
        } else {
          credito += c.total;
        }
      }

      state = state.copyWith(
        isLoading: false,
        gastos: list,
        totales: TotalesGastos(
          totalGastos: totalGeneral,
          totalContado: contado,
          totalCredito: credito,
          totalItbis: itbis,
          totalSubtotal: subtotal,
          cantidad: list.length,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String query) {
    state = state.copyWith(search: query);
    loadGastos();
  }

  void setTipoCompra(String tipo) {
    state = state.copyWith(tipoCompra: tipo);
    loadGastos();
  }

  void setCuenta(int? cuentaId) {
    loadGastos(cuentaContableId: cuentaId, clearCuenta: cuentaId == null);
  }

  void setFechas(String? desde, String? hasta) {
    loadGastos(fechaDesde: desde, fechaHasta: hasta);
  }
}

final gastosProvider = StateNotifierProvider<GastosNotifier, GastosState>((ref) {
  final api = ref.watch(compraApiProvider);
  final token = ref.watch(authProvider).token;
  return GastosNotifier(api, token);
});

