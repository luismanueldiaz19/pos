import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_loading.dart';
import '../providers/inventario_provider.dart';
import 'nuevo_ajuste_dialog.dart';

class ScreenKardexInventario extends ConsumerStatefulWidget {
  const ScreenKardexInventario({super.key});

  @override
  ConsumerState<ScreenKardexInventario> createState() =>
      _ScreenKardexInventarioState();
}

class _ScreenKardexInventarioState
    extends ConsumerState<ScreenKardexInventario> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fechaDesdeCtrl = TextEditingController();
  final TextEditingController _fechaHastaCtrl = TextEditingController();

  String _tipoSeleccionado = 'TODOS';
  bool _isExportingPdf = false;

  // Paginación local
  int _currentPage = 1;
  final int _rowsPerPage = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fechaDesdeCtrl.dispose();
    _fechaHastaCtrl.dispose();
    super.dispose();
  }

  void _cargarDatos() {
    final auth = ref.read(authProvider);
    if (auth.token != null) {
      ref.read(inventarioProvider.notifier).loadMovimientos(
            auth.token!,
            search: _searchController.text.trim(),
            tipo: _tipoSeleccionado,
          );
    }
  }

  Future<void> _seleccionarFecha(
      BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        _currentPage = 1;
      });
      _cargarDatos();
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _searchController.clear();
      _fechaDesdeCtrl.clear();
      _fechaHastaCtrl.clear();
      _tipoSeleccionado = 'TODOS';
      _currentPage = 1;
    });
    _cargarDatos();
  }

  Future<void> _exportarPdfReporte() async {
    final auth = ref.read(authProvider);
    final token = auth.token;
    if (token == null) return;

    setState(() => _isExportingPdf = true);
    try {
      final filters = <String, dynamic>{
        'tipo': _tipoSeleccionado,
        'search': _searchController.text.trim(),
        'fecha_desde': _fechaDesdeCtrl.text.trim(),
        'fecha_hasta': _fechaHastaCtrl.text.trim(),
      };

      final pdfUrlPath = await ref
          .read(inventarioProvider.notifier)
          .obtenerPdfReporteUrl(
            token,
            tipoReporte: 'kardex',
            filters: filters,
          );

      if (pdfUrlPath != null && pdfUrlPath.isNotEmpty) {
        final urlToLaunch = Uri.parse('$hostName$pdfUrlPath');
        if (await canLaunchUrl(urlToLaunch)) {
          await launchUrl(urlToLaunch, mode: LaunchMode.externalApplication);
        } else if (mounted) {
          showToast(context, 'No se pudo abrir el PDF', bgColor: Colors.orange);
        }
      } else if (mounted) {
        showToast(context, 'No se pudo generar el reporte en PDF',
            bgColor: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error al generar reporte: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  void _abrirNuevoAjuste() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NuevoAjusteDialog(),
    );

    if (result == true) {
      _cargarDatos();
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 8.5,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = AppColors.azulOscuro,
    Color? inactiveColor,
    Color? inactiveBg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : (inactiveBg ?? Colors.grey.shade100),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (inactiveColor ?? Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventarioProvider);
    final movimientos = state.movimientos;

    // Métricas dinámicas calculadas sobre movimientos
    double totalEntradas = 0.0;
    double totalSalidas = 0.0;
    int cantEntradas = 0;
    int cantSalidas = 0;

    for (final m in movimientos) {
      final isEntrada = (m.tipo ?? '').toUpperCase() == 'ENTRADA';
      final cant = m.cantidad ?? 0.0;
      if (isEntrada) {
        totalEntradas += cant;
        cantEntradas++;
      } else {
        totalSalidas += cant;
        cantSalidas++;
      }
    }

    final saldoNeto = totalEntradas - totalSalidas;

    // Filtro adicional local si aplica
    final term = _searchController.text.trim().toLowerCase();
    final fechaDesde = _fechaDesdeCtrl.text.trim();
    final fechaHasta = _fechaHastaCtrl.text.trim();

    final filtered = movimientos.where((m) {
      if (_tipoSeleccionado != 'TODOS' &&
          (m.tipo ?? '').toUpperCase() != _tipoSeleccionado) {
        return false;
      }
      if (fechaDesde.isNotEmpty && m.fecha != null) {
        final d = DateFormat('yyyy-MM-dd').format(m.fecha!);
        if (d.compareTo(fechaDesde) < 0) return false;
      }
      if (fechaHasta.isNotEmpty && m.fecha != null) {
        final d = DateFormat('yyyy-MM-dd').format(m.fecha!);
        if (d.compareTo(fechaHasta) > 0) return false;
      }
      if (term.isNotEmpty) {
        final prod = (m.producto?.nombre ?? '').toLowerCase();
        final cod = (m.producto?.codigo ?? '').toLowerCase();
        final refStr = (m.referencia ?? '').toLowerCase();
        return prod.contains(term) || cod.contains(term) || refStr.contains(term);
      }
      return true;
    }).toList();

    // Paginación
    final totalItems = filtered.length;
    final totalPages = (totalItems / _rowsPerPage).ceil().clamp(1, 9999);
    final currentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
    final pageItems =
        startIndex < totalItems ? filtered.sublist(startIndex, endIndex) : [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.azulOscuro, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Movimientos de Inventario",
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: "Actualizar datos",
            onPressed: _cargarDatos,
          ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: _isExportingPdf ? null : _exportarPdfReporte,
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined,
                    size: 16, color: AppColors.primary),
            label: Text(
              _isExportingPdf ? "Generando..." : "Reporte PDF",
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _abrirNuevoAjuste,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Nuevo Ajuste",
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading && movimientos.isEmpty
          ? const Center(
              child: CustomLoading(text: "Cargando movimientos de inventario..."))
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  // Tarjetas KPI Flujo de Inventario
                  Row(
                    children: [
                      _buildMetricCard(
                        title: "Operaciones Registradas",
                        value: "${movimientos.length}",
                        icon: Icons.history_edu_outlined,
                        color: Colors.blue,
                        subtitle: "Entradas y Salidas",
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Unidades Ingresadas (+)",
                        value: "+${totalEntradas.toStringAsFixed(1)}",
                        icon: Icons.add_circle_outline,
                        color: Colors.green,
                        subtitle: "$cantEntradas transacciones",
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Unidades Egresadas (-)",
                        value: "-${totalSalidas.toStringAsFixed(1)}",
                        icon: Icons.remove_circle_outline,
                        color: Colors.red,
                        subtitle: "$cantSalidas transacciones",
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Saldo Neto Flujo",
                        value: "${saldoNeto >= 0 ? '+' : ''}${saldoNeto.toStringAsFixed(1)}",
                        icon: Icons.swap_vert_circle_outlined,
                        color: saldoNeto >= 0 ? Colors.teal : Colors.orange,
                        subtitle: "Balance global",
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Barra de Filtros Compacta Distribuida en Una Sola Línea
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Filtros de Tipo con diseño limpio (Pills)
                          _buildFilterPill(
                            label: "Todos",
                            isSelected: _tipoSeleccionado == 'TODOS',
                            activeColor: AppColors.azulOscuro,
                            onTap: () => setState(() {
                              _tipoSeleccionado = 'TODOS';
                              _currentPage = 1;
                            }),
                          ),
                          const SizedBox(width: 4),
                          _buildFilterPill(
                            label: "Entradas (+)",
                            isSelected: _tipoSeleccionado == 'ENTRADA',
                            activeColor: Colors.green.shade700,
                            inactiveColor: Colors.green.shade700,
                            inactiveBg: Colors.green.shade50,
                            onTap: () => setState(() {
                              _tipoSeleccionado = 'ENTRADA';
                              _currentPage = 1;
                            }),
                          ),
                          const SizedBox(width: 4),
                          _buildFilterPill(
                            label: "Salidas (-)",
                            isSelected: _tipoSeleccionado == 'SALIDA',
                            activeColor: Colors.red.shade700,
                            inactiveColor: Colors.red.shade700,
                            inactiveBg: Colors.red.shade50,
                            onTap: () => setState(() {
                              _tipoSeleccionado = 'SALIDA';
                              _currentPage = 1;
                            }),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 18,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 8),

                          // Fecha Desde
                          SizedBox(
                            width: 125,
                            height: 28,
                            child: TextField(
                              controller: _fechaDesdeCtrl,
                              readOnly: true,
                              onTap: () =>
                                  _seleccionarFecha(context, _fechaDesdeCtrl),
                              style: const TextStyle(fontSize: 10.5),
                              decoration: InputDecoration(
                                labelText: "Desde",
                                labelStyle: const TextStyle(fontSize: 10),
                                prefixIcon: const Icon(Icons.calendar_today,
                                    size: 13),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Fecha Hasta
                          SizedBox(
                            width: 125,
                            height: 28,
                            child: TextField(
                              controller: _fechaHastaCtrl,
                              readOnly: true,
                              onTap: () =>
                                  _seleccionarFecha(context, _fechaHastaCtrl),
                              style: const TextStyle(fontSize: 10.5),
                              decoration: InputDecoration(
                                labelText: "Hasta",
                                labelStyle: const TextStyle(fontSize: 10),
                                prefixIcon: const Icon(Icons.event, size: 13),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 18,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 8),

                          // Buscador
                          SizedBox(
                            width: 220,
                            height: 28,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() => _currentPage = 1),
                              style: const TextStyle(fontSize: 10.5),
                              decoration: InputDecoration(
                                hintText: "Buscar producto o referencia...",
                                hintStyle: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade400),
                                prefixIcon:
                                    const Icon(Icons.search, size: 14),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 12),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _currentPage = 1);
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Botón Limpiar
                          OutlinedButton.icon(
                            onPressed: _limpiarFiltros,
                            icon: const Icon(Icons.clear_all_rounded, size: 13),
                            label: const Text("Limpiar",
                                style: TextStyle(fontSize: 10)),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Tabla de Kardex
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: DataTable2(
                          columnSpacing: 8,
                          horizontalMargin: 8,
                          headingRowHeight: 28,
                          dataRowHeight: 32,
                          headingRowColor:
                              WidgetStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn2(
                              label: Text("FECHA Y HORA",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 135,
                            ),
                            DataColumn2(
                              label: Text("PRODUCTO",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn2(
                              label: Text("CATEGORÍA",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 120,
                            ),
                            DataColumn2(
                              label: Text("MOVIMIENTO",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 110,
                            ),
                            DataColumn2(
                              label: Text("CANTIDAD",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              numeric: true,
                              fixedWidth: 100,
                            ),
                            DataColumn2(
                              label: Text("REFERENCIA / MOTIVO",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: pageItems.map((m) {
                            final dateStr = m.fecha != null
                                ? DateFormat('yyyy-MM-dd HH:mm').format(m.fecha!)
                                : '--';
                            final isEntrada =
                                (m.tipo ?? '').toUpperCase() == 'ENTRADA';

                            return DataRow2(
                              cells: [
                                DataCell(Text(
                                  dateStr,
                                  style: const TextStyle(
                                      fontSize: 10.5, color: Colors.blueGrey),
                                )),
                                DataCell(
                                  Text(
                                    m.producto?.nombre ??
                                        'Producto #${m.productoId}',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataCell(Text(
                                  m.producto?.categoria?.nombre ?? '--',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                )),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isEntrada
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: isEntrada
                                              ? Colors.green.shade300
                                              : Colors.red.shade300),
                                    ),
                                    child: Text(
                                      isEntrada ? "ENTRADA (+)" : "SALIDA (-)",
                                      style: TextStyle(
                                        color: isEntrada
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "${isEntrada ? '+' : '-'}${m.cantidad?.toStringAsFixed(1) ?? '0.0'}",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isEntrada
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    m.referencia ?? '--',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // Barra de Paginación Inferior
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          totalItems > 0
                              ? "Mostrando ${startIndex + 1} - $endIndex de $totalItems movimientos"
                              : "No hay movimientos para mostrar",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.first_page, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Primera página",
                              onPressed: currentPage > 1
                                  ? () => setState(() => _currentPage = 1)
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Anterior",
                              onPressed: currentPage > 1
                                  ? () => setState(
                                      () => _currentPage = currentPage - 1)
                                  : null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "Pág. $currentPage de $totalPages",
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Siguiente",
                              onPressed: currentPage < totalPages
                                  ? () => setState(
                                      () => _currentPage = currentPage + 1)
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.last_page, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Última página",
                              onPressed: currentPage < totalPages
                                  ? () => setState(
                                      () => _currentPage = totalPages)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
