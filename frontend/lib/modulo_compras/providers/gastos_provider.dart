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

  // Paginación
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final int from;
  final int to;

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
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.perPage = 15,
    this.from = 0,
    this.to = 0,
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
    int? currentPage,
    int? lastPage,
    int? total,
    int? perPage,
    int? from,
    int? to,
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
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      perPage: perPage ?? this.perPage,
      from: from ?? this.from,
      to: to ?? this.to,
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
    int? page,
    int? perPage,
    String? fechaDesde,
    String? fechaHasta,
    String? estado,
    String? tipoCompra,
    int? cuentaContableId,
    bool clearCuenta = false,
    String? search,
  }) async {
    if (token == null) return;

    final targetPage = page ?? state.currentPage;
    final targetPerPage = perPage ?? state.perPage;

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: targetPage,
      perPage: targetPerPage,
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
        page: targetPage,
        perPage: targetPerPage,
      );

      final List<dynamic> dataList = response['data'] ?? [];
      var list = dataList.map((e) => Compra.fromJson(e)).toList();

      final current = (response['current_page'] as num?)?.toInt() ?? targetPage;
      final last = (response['last_page'] as num?)?.toInt() ?? 1;
      final totalRecords = (response['total'] as num?)?.toInt() ?? list.length;
      final fromRecord = (response['from'] as num?)?.toInt() ?? (list.isNotEmpty ? 1 : 0);
      final toRecord = (response['to'] as num?)?.toInt() ?? list.length;

      TotalesGastos calcTotales;
      if (response['totales'] != null && response['totales'] is Map) {
        final t = response['totales'];
        calcTotales = TotalesGastos(
          totalGastos: (num.tryParse(t['total_general']?.toString() ?? '0') ?? 0.0).toDouble(),
          totalContado: (num.tryParse(t['total_contado']?.toString() ?? '0') ?? 0.0).toDouble(),
          totalCredito: (num.tryParse(t['total_credito']?.toString() ?? '0') ?? 0.0).toDouble(),
          totalItbis: (num.tryParse(t['total_itbis']?.toString() ?? '0') ?? 0.0).toDouble(),
          totalSubtotal: (num.tryParse(t['total_subtotal']?.toString() ?? '0') ?? 0.0).toDouble(),
          cantidad: (num.tryParse(t['cantidad']?.toString() ?? '0') ?? totalRecords).toInt(),
        );
      } else {
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

        calcTotales = TotalesGastos(
          totalGastos: totalGeneral,
          totalContado: contado,
          totalCredito: credito,
          totalItbis: itbis,
          totalSubtotal: subtotal,
          cantidad: totalRecords,
        );
      }

      state = state.copyWith(
        isLoading: false,
        gastos: list,
        currentPage: current,
        lastPage: last,
        total: totalRecords,
        from: fromRecord,
        to: toRecord,
        totales: calcTotales,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void changePage(int page) {
    if (page < 1 || (page > state.lastPage && state.lastPage > 0)) return;
    loadGastos(page: page);
  }

  void setPerPage(int perPage) {
    loadGastos(page: 1, perPage: perPage);
  }

  void setSearch(String query) {
    loadGastos(page: 1, search: query);
  }

  void setTipoCompra(String tipo) {
    loadGastos(page: 1, tipoCompra: tipo);
  }

  void setCuenta(int? cuentaId) {
    loadGastos(page: 1, cuentaContableId: cuentaId, clearCuenta: cuentaId == null);
  }

  void setFechas(String? desde, String? hasta) {
    loadGastos(page: 1, fechaDesde: desde, fechaHasta: hasta);
  }

  Future<String?> obtenerPdfReporteUrl() async {
    if (token == null) return null;
    try {
      return await api.getReportePdfUrl(
        token!,
        fechaDesde: state.fechaDesde,
        fechaHasta: state.fechaHasta,
        estado: state.estado,
        search: state.search,
        esGasto: true,
        tipoCompra: state.tipoCompra,
        cuentaContableId: state.cuentaContableId,
      );
    } catch (_) {
      return null;
    }
  }
}

final gastosProvider = StateNotifierProvider<GastosNotifier, GastosState>((ref) {
  final api = ref.watch(compraApiProvider);
  final token = ref.watch(authProvider).token;
  return GastosNotifier(api, token);
});
