import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../palletes/app_colors.dart';
import '../../../widgets/custom_loading.dart';
import '../../../widgets/custom_empty_state.dart';
import '../../../providers/auth_provider.dart';
import '../providers/gastos_provider.dart';
import 'registrar_gasto_screen.dart';
import 'widgets/gastos_kpi_cards.dart';
import 'widgets/gastos_filtros_bar.dart';
import 'widgets/gasto_item_card.dart';

/// Pantalla para ver, filtrar y gestionar los Gastos Operativos.
/// Restringida exclusivamente para roles: `admin` y `contador`.
/// Aplica las skills:
/// - `flutter-clean-reusable-ui`: Componentes modulares, <250 líneas, componentes centrales.
/// - `flutter-small-widgets`: Densidad visual alta, alturas 32-38px, fuentes 11-13px.
/// - `motor-contable`: Visualización de cuentas Clase 6 y asientos contables.
class GastosListScreen extends ConsumerStatefulWidget {
  const GastosListScreen({super.key});

  @override
  ConsumerState<GastosListScreen> createState() => _GastosListScreenState();
}

class _GastosListScreenState extends ConsumerState<GastosListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gastosProvider.notifier).loadGastos();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _seleccionarFecha(bool isDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDesde ? _fechaDesde : _fechaHasta) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
      _aplicarFiltroFechas();
    }
  }

  void _aplicarFiltroFechas() {
    final fmt = DateFormat('yyyy-MM-dd');
    ref.read(gastosProvider.notifier).setFechas(
          _fechaDesde != null ? fmt.format(_fechaDesde!) : null,
          _fechaHasta != null ? fmt.format(_fechaHasta!) : null,
        );
  }

  void _limpiarFiltros() {
    setState(() {
      _searchCtrl.clear();
      _fechaDesde = null;
      _fechaHasta = null;
    });
    ref.read(gastosProvider.notifier).loadGastos(
          fechaDesde: null,
          fechaHasta: null,
          estado: 'todos',
          tipoCompra: 'todos',
          search: '',
          clearCuenta: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final bool isAdmin = auth.roles.contains('admin');
    final bool isContador = auth.roles.contains('contador');

    // Validación de seguridad de rol
    if (!isAdmin && !isContador) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Restringido')),
        body: const Center(
          child: CustomEmptyState(
            title: 'Acceso Denegado',
            subtitle: 'Este módulo está reservado exclusivamente para los roles Administrador y Contador.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final state = ref.watch(gastosProvider);
    final fmtLabel = DateFormat('dd/MM/yy');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro, size: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de Gastos Operativos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                Text(
                  'Historial y control (Clase 6 · Estado de Resultados)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botón Nuevo Gasto
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistrarGastoScreen()),
                );
                ref.read(gastosProvider.notifier).loadGastos();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo Gasto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          // Botón Refrescar
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refrescar gastos',
            onPressed: () => ref.read(gastosProvider.notifier).loadGastos(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            GastosKpiCards(totales: state.totales),
            const SizedBox(height: 10),

            // Barra de Filtros
            GastosFiltrosBar(
              searchCtrl: _searchCtrl,
              onSearchChanged: (q) => ref.read(gastosProvider.notifier).setSearch(q),
              selectedTipoCompra: state.tipoCompra ?? 'todos',
              onTipoCompraChanged: (tipo) => ref.read(gastosProvider.notifier).setTipoCompra(tipo),
              onSelectFechaDesde: () => _seleccionarFecha(true),
              onSelectFechaHasta: () => _seleccionarFecha(false),
              fechaDesdeLabel: _fechaDesde != null ? fmtLabel.format(_fechaDesde!) : null,
              fechaHastaLabel: _fechaHasta != null ? fmtLabel.format(_fechaHasta!) : null,
              onLimpiarFiltros: _limpiarFiltros,
            ),
            const SizedBox(height: 10),

            // Lista de Gastos
            Expanded(
              child: _buildListaGastos(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaGastos(GastosState state) {
    if (state.isLoading) {
      return const Center(child: CustomLoading(text: 'Cargando gastos operativos...'));
    }

    if (state.error != null) {
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }

    if (state.gastos.isEmpty) {
      return const Center(
        child: CustomEmptyState(
          title: 'No hay gastos registrados',
          subtitle: 'Utiliza el botón "+ Nuevo Gasto" para registrar tu primer gasto operativo.',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return ListView.builder(
      itemCount: state.gastos.length,
      itemBuilder: (context, index) {
        final gasto = state.gastos[index];
        return GastoItemCard(gasto: gasto);
      },
    );
  }
}

