import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../palletes/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/custom_loading.dart';
import '../../../widgets/custom_empty_state.dart';
import '../../../providers/auth_provider.dart';
import '../providers/gastos_provider.dart';
import 'registrar_gasto_screen.dart';
import 'widgets/gastos_kpi_cards.dart';
import 'widgets/gastos_filtros_bar.dart';
import 'widgets/gastos_table_view.dart';

/// Pantalla para ver, filtrar, paginar y exportar a PDF los Gastos Operativos.
/// Restringida exclusivamente para roles: `admin` y `contador`.
/// Aplica rigurosamente:
/// - `flutter-clean-reusable-ui`: Componentes modulares, <250 líneas, SRP.
/// - `flutter-small-widgets`: Densidad visual alta, KPI compactos (42px), Data Table compacta.
/// - `motor-contable`: Asientos y cuentas Clase 6 reflejados con precisión.
class GastosListScreen extends ConsumerStatefulWidget {
  const GastosListScreen({super.key});

  @override
  ConsumerState<GastosListScreen> createState() => _GastosListScreenState();
}

class _GastosListScreenState extends ConsumerState<GastosListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTimeRange? _rangoFechas;
  bool _isExportingPdf = false;

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

  Future<void> _seleccionarRangoFechas() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _rangoFechas ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      helpText: 'SELECCIONAR RANGO DE FECHAS',
      cancelText: 'CANCELAR',
      confirmText: 'APLICAR',
      saveText: 'APLICAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.azulOscuro,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _rangoFechas = picked);
      _aplicarFiltroFechas();
    }
  }

  void _aplicarFiltroFechas() {
    final fmt = DateFormat('yyyy-MM-dd');
    final desde = _rangoFechas != null ? fmt.format(_rangoFechas!.start) : null;
    final hasta = _rangoFechas != null ? fmt.format(_rangoFechas!.end) : null;
    ref.read(gastosProvider.notifier).setFechas(desde, hasta);
  }

  void _limpiarFechas() {
    setState(() => _rangoFechas = null);
    _aplicarFiltroFechas();
  }

  void _seleccionarHoy() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() => _rangoFechas = DateTimeRange(start: today, end: today));
    _aplicarFiltroFechas();
  }

  void _seleccionarEsteMes() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day);
    setState(() => _rangoFechas = DateTimeRange(start: start, end: end));
    _aplicarFiltroFechas();
  }

  void _limpiarFiltros() {
    setState(() {
      _searchCtrl.clear();
      _rangoFechas = null;
    });
    ref.read(gastosProvider.notifier).loadGastos(
          page: 1,
          fechaDesde: null,
          fechaHasta: null,
          estado: 'todos',
          tipoCompra: 'todos',
          search: '',
          clearCuenta: true,
        );
  }

  String? get _rangoFechasLabel {
    if (_rangoFechas == null) return null;
    final fmt = DateFormat('dd/MM/yy');
    return '${fmt.format(_rangoFechas!.start)} - ${fmt.format(_rangoFechas!.end)}';
  }

  Future<void> _exportarPdfReporte() async {
    if (_isExportingPdf) return;
    setState(() => _isExportingPdf = true);
    try {
      final notifier = ref.read(gastosProvider.notifier);
      final pdfUrlPath = await notifier.obtenerPdfReporteUrl();

      if (pdfUrlPath != null && pdfUrlPath.isNotEmpty) {
        final urlToLaunch = Uri.parse('$hostName$pdfUrlPath');
        if (await canLaunchUrl(urlToLaunch)) {
          await launchUrl(urlToLaunch, mode: LaunchMode.externalApplication);
        } else if (mounted) {
          showToast(context, 'No se pudo abrir el PDF', bgColor: Colors.orange);
        }
      } else if (mounted) {
        showToast(
          context,
          'No se pudo generar el reporte en PDF',
          bgColor: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error al generar reporte: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final bool isAdmin = auth.roles.contains('admin');
    final bool isContador = auth.roles.contains('contador');

    // Validación de seguridad de rol (solo admin o contador)
    if (!isAdmin && !isContador) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Restringido')),
        body: const Center(
          child: CustomEmptyState(
            title: 'Acceso Denegado',
            subtitle:
                'Este módulo está reservado exclusivamente para los roles Administrador y Contador.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final state = ref.watch(gastosProvider);

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
          // Botón Exportar PDF Reporte Filtrado
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: OutlinedButton.icon(
              onPressed: _isExportingPdf ? null : _exportarPdfReporte,
              icon: _isExportingPdf
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 15,
                      color: Color(0xFFDC2626),
                    ),
              label: Text(
                _isExportingPdf ? 'Generando...' : 'PDF Reporte',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Botón Nuevo Gasto
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegistrarGastoScreen(),
                  ),
                );
                ref.read(gastosProvider.notifier).loadGastos();
              },
              icon: const Icon(Icons.add, size: 15),
              label: const Text(
                'Nuevo Gasto',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
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
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KPI Totals Cards (Ultra compactos de 42px según skill flutter-small-widgets)
            GastosKpiCards(totales: state.totales),
            const SizedBox(height: 8),

            // 2. Barra de Filtros y Rango de Fechas
            GastosFiltrosBar(
              searchCtrl: _searchCtrl,
              onSearchChanged: (q) =>
                  ref.read(gastosProvider.notifier).setSearch(q),
              selectedTipoCompra: state.tipoCompra ?? 'todos',
              onTipoCompraChanged: (tipo) =>
                  ref.read(gastosProvider.notifier).setTipoCompra(tipo),
              onSelectRangoFechas: _seleccionarRangoFechas,
              rangoFechasLabel: _rangoFechasLabel,
              onLimpiarFechas: _limpiarFechas,
              onQuickHoy: _seleccionarHoy,
              onQuickEsteMes: _seleccionarEsteMes,
              onLimpiarFiltros: _limpiarFiltros,
            ),
            const SizedBox(height: 8),

            // 3. Tabla ERP Paginada
            Expanded(
              child: _buildCuerpoTabla(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuerpoTabla(GastosState state) {
    if (state.isLoading) {
      return const Center(
        child: CustomLoading(text: 'Cargando gastos operativos...'),
      );
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
          subtitle:
              'No se encontraron gastos con los filtros seleccionados. Utiliza "+ Nuevo Gasto" para registrar uno.',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return GastosTableView(
      state: state,
      onPageChanged: (page) =>
          ref.read(gastosProvider.notifier).changePage(page),
      onPerPageChanged: (perPage) =>
          ref.read(gastosProvider.notifier).setPerPage(perPage),
    );
  }
}
