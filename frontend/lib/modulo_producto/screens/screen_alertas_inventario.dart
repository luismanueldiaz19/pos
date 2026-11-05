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
import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import 'nuevo_ajuste_dialog.dart';

class ScreenAlertasInventario extends ConsumerStatefulWidget {
  const ScreenAlertasInventario({super.key});

  @override
  ConsumerState<ScreenAlertasInventario> createState() =>
      _ScreenAlertasInventarioState();
}

class _ScreenAlertasInventarioState
    extends ConsumerState<ScreenAlertasInventario> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);

  String _filtroSeveridad = 'TODAS'; // 'TODAS', 'DEFICIT', 'AGOTADO', 'BAJO'
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
    super.dispose();
  }

  void _cargarDatos() {
    final auth = ref.read(authProvider);
    if (auth.token != null) {
      ref.read(inventarioProvider.notifier).loadAlertas(auth.token!);
    }
  }

  Future<void> _exportarPdfReporte() async {
    final auth = ref.read(authProvider);
    final token = auth.token;
    if (token == null) return;

    setState(() => _isExportingPdf = true);
    try {
      final filters = <String, dynamic>{
        'search': _searchController.text.trim(),
      };
      if (_filtroSeveridad != 'TODAS') {
        filters['estado_alerta'] = _filtroSeveridad.toLowerCase();
      }

      final pdfUrlPath = await ref
          .read(inventarioProvider.notifier)
          .obtenerPdfReporteUrl(
            token,
            tipoReporte: 'alertas',
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

  void _abrirNuevoAjuste([Producto? producto]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NuevoAjusteDialog(productoInicial: producto),
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

  Widget _buildStockBadge(double stock, double minimo) {
    Color bg;
    Color fg;
    String label;

    if (stock < 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
      label = "${stock.toStringAsFixed(1)} (Déficit)";
    } else if (stock == 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = "0.0 (Agotado)";
    } else {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      label = "${stock.toStringAsFixed(1)} (Bajo mín.)";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
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
    final alertas = state.alertas;

    // Métricas
    int deficitCount = 0;
    int agotadosCount = 0;
    int bajoMinimoCount = 0;
    double unidadesFaltantesTotal = 0.0;
    double inversionEstimadaTotal = 0.0;

    for (final p in alertas) {
      final stock = p.stockActual ?? 0.0;
      final minimo = p.stockMinimo ?? 0.0;
      final costo = p.costo ?? 0.0;
      final faltante = (minimo - stock) > 0 ? (minimo - stock) : 0.0;

      if (stock < 0) {
        deficitCount++;
      } else if (stock == 0) {
        agotadosCount++;
      } else {
        bajoMinimoCount++;
      }

      unidadesFaltantesTotal += faltante;
      inversionEstimadaTotal += (faltante * costo);
    }

    // Filtrado
    final term = _searchController.text.trim().toLowerCase();
    final filtered = alertas.where((p) {
      final stock = p.stockActual ?? 0.0;
      if (_filtroSeveridad == 'DEFICIT' && stock >= 0) return false;
      if (_filtroSeveridad == 'AGOTADO' && stock != 0) return false;
      if (_filtroSeveridad == 'BAJO' && (stock <= 0)) return false;

      if (term.isNotEmpty) {
        final nom = (p.nombre ?? '').toLowerCase();
        final cod = (p.codigo ?? '').toLowerCase();
        final cat = (p.categoria?.nombre ?? '').toLowerCase();
        return nom.contains(term) || cod.contains(term) || cat.contains(term);
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
          "Alertas de Reposición y Déficit de Stock",
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
              onPressed: () => _abrirNuevoAjuste(),
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
      body: state.isLoading && alertas.isEmpty
          ? const Center(
              child: CustomLoading(text: "Consultando alertas de stock..."))
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  // KPI Cards Compactas
                  Row(
                    children: [
                      _buildMetricCard(
                        title: "Total en Alerta",
                        value: "${alertas.length}",
                        icon: Icons.warning_amber_rounded,
                        color: alertas.isNotEmpty ? Colors.amber.shade800 : Colors.green,
                        subtitle: "Bajo stock o déficit",
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Déficit Crítico",
                        value: "$deficitCount",
                        icon: Icons.error_outline,
                        color: Colors.red.shade800,
                        subtitle: "Stock negativo (< 0)",
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Completamente Agotados",
                        value: "$agotadosCount",
                        icon: Icons.cancel_outlined,
                        color: Colors.red.shade600,
                        subtitle: "Existencias en 0.0",
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Inversión Estimada",
                        value: _currencyFormat.format(inversionEstimadaTotal),
                        icon: Icons.monetization_on_outlined,
                        color: Colors.indigo,
                        subtitle: "+${unidadesFaltantesTotal.toStringAsFixed(1)} un. a reponer",
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Barra de Filtros Compacta en una sola línea
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
                          _buildFilterPill(
                            label: "Todas",
                            isSelected: _filtroSeveridad == 'TODAS',
                            activeColor: AppColors.azulOscuro,
                            onTap: () => setState(() {
                              _filtroSeveridad = 'TODAS';
                              _currentPage = 1;
                            }),
                          ),
                          const SizedBox(width: 4),
                          _buildFilterPill(
                            label: "Déficit ($deficitCount)",
                            isSelected: _filtroSeveridad == 'DEFICIT',
                            activeColor: Colors.red.shade800,
                            inactiveColor: Colors.red.shade800,
                            inactiveBg: Colors.red.shade50,
                            onTap: () => setState(() {
                              _filtroSeveridad = 'DEFICIT';
                              _currentPage = 1;
                            }),
                          ),
                          const SizedBox(width: 4),
                          _buildFilterPill(
                            label: "Agotados ($agotadosCount)",
                            isSelected: _filtroSeveridad == 'AGOTADO',
                            activeColor: Colors.red.shade600,
                            inactiveColor: Colors.red.shade600,
                            inactiveBg: Colors.red.shade50,
                            onTap: () => setState(() {
                              _filtroSeveridad = 'AGOTADO';
                              _currentPage = 1;
                            }),
                          ),
                          const SizedBox(width: 4),
                          _buildFilterPill(
                            label: "Bajo Mín. ($bajoMinimoCount)",
                            isSelected: _filtroSeveridad == 'BAJO',
                            activeColor: Colors.amber.shade900,
                            inactiveColor: Colors.amber.shade900,
                            inactiveBg: Colors.amber.shade50,
                            onTap: () => setState(() {
                              _filtroSeveridad = 'BAJO';
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

                          // Buscador
                          SizedBox(
                            width: 240,
                            height: 28,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() => _currentPage = 1),
                              style: const TextStyle(fontSize: 10.5),
                              decoration: InputDecoration(
                                hintText: "Buscar producto por código o nombre...",
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Tabla de Alertas
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
                              WidgetStateProperty.all(Colors.amber.shade50),
                          columns: const [
                            DataColumn2(
                              label: Text("CÓDIGO",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 85,
                            ),
                            DataColumn2(
                              label: Text("PRODUCTO EN ALERTA",
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
                              label: Text("U.M.",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 60,
                            ),
                            DataColumn2(
                              label: Text("STOCK ACTUAL",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 125,
                            ),
                            DataColumn2(
                              label: Text("MÍNIMO",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              numeric: true,
                              fixedWidth: 70,
                            ),
                            DataColumn2(
                              label: Text("A REPONER",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              numeric: true,
                              fixedWidth: 95,
                            ),
                            DataColumn2(
                              label: Text("COSTO UNIT.",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              numeric: true,
                              fixedWidth: 100,
                            ),
                            DataColumn2(
                              label: Text("INVERSIÓN EST.",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              numeric: true,
                              fixedWidth: 125,
                            ),
                            DataColumn2(
                              label: Text("ACCIÓN",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 75,
                            ),
                          ],
                          rows: pageItems.map((p) {
                            final stock = p.stockActual ?? 0.0;
                            final minimo = p.stockMinimo ?? 0.0;
                            final costo = p.costo ?? 0.0;
                            final faltante =
                                (minimo - stock) > 0 ? (minimo - stock) : 0.0;
                            final inversion = (faltante * costo);

                            return DataRow2(
                              cells: [
                                DataCell(Text(
                                  p.codigo ?? '#${p.id}',
                                  style: const TextStyle(
                                      fontSize: 10.5, color: Colors.blueGrey),
                                )),
                                DataCell(
                                  Text(
                                    p.nombre ?? '',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataCell(Text(
                                  p.categoria?.nombre ?? '--',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                )),
                                DataCell(Text(
                                  p.unidadMedida?.nombre ?? 'un.',
                                  style: const TextStyle(
                                      fontSize: 10.5, color: Colors.blueGrey),
                                )),
                                DataCell(_buildStockBadge(stock, minimo)),
                                DataCell(Text(
                                  minimo.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10.5),
                                )),
                                DataCell(
                                  Text(
                                    "+${faltante.toStringAsFixed(1)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                DataCell(Text(
                                  _currencyFormat.format(costo),
                                  style: const TextStyle(fontSize: 10.5),
                                )),
                                DataCell(Text(
                                  _currencyFormat.format(inversion),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.azulOscuro),
                                )),
                                DataCell(
                                  ElevatedButton(
                                    onPressed: () => _abrirNuevoAjuste(p),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 4),
                                      minimumSize: const Size(60, 26),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: const Text("Reponer",
                                        style: TextStyle(fontSize: 10)),
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
                              ? "Mostrando ${startIndex + 1} - $endIndex de $totalItems alertas"
                              : "¡Excelente! No hay alertas de stock para los filtros aplicados.",
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
