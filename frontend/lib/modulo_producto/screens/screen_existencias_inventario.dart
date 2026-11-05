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
import '../providers/catalogo_provider.dart';
import '../providers/inventario_provider.dart';
import 'nuevo_ajuste_dialog.dart';

class ScreenExistenciasInventario extends ConsumerStatefulWidget {
  const ScreenExistenciasInventario({super.key});

  @override
  ConsumerState<ScreenExistenciasInventario> createState() =>
      _ScreenExistenciasInventarioState();
}

class _ScreenExistenciasInventarioState
    extends ConsumerState<ScreenExistenciasInventario> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);
  final NumberFormat _numberFormat = NumberFormat('#,##0.00', 'en_US');

  int? _selectedCategoriaId;
  bool _isExportingPdf = false;

  // Paginación local de la lista
  int _currentPage = 1;
  int _rowsPerPage = 20;

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
      ref.read(inventarioProvider.notifier).loadExistencias(
            auth.token!,
            categoriaId: _selectedCategoriaId,
          );
      ref.read(categoriasProvider.notifier).fetchAll(auth.token!);
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
      if (_selectedCategoriaId != null) {
        filters['categoria_id'] = _selectedCategoriaId;
      }

      final pdfUrlPath = await ref
          .read(inventarioProvider.notifier)
          .obtenerPdfReporteUrl(
            token,
            tipoReporte: 'existencias',
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
      fg = Colors.red.shade700;
      label = "${stock.toStringAsFixed(1)} (Déficit)";
    } else if (stock == 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = "0.0 (Agotado)";
    } else if (stock <= minimo) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      label = "${stock.toStringAsFixed(1)} (Bajo)";
    } else {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = stock.toStringAsFixed(1);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventarioProvider);
    final categoriasState = ref.watch(categoriasProvider);
    final resumen = state.existenciasResumen;

    final totalProductos = resumen['total_productos'] ?? 0;
    final totalUnidades = resumen['total_unidades'] ?? 0.0;
    final valorTotalCosto = resumen['valor_total_costo'] ?? 0.0;
    final enAlerta = resumen['productos_en_alerta'] ?? 0;

    final term = _searchController.text.trim().toLowerCase();
    final items = state.existenciasProductos;

    final filtered = items.where((it) {
      if (_selectedCategoriaId != null &&
          it['categoria_id'] != null &&
          it['categoria_id'] != _selectedCategoriaId) {
        return false;
      }
      if (term.isEmpty) return true;
      final nombre = (it['nombre'] ?? '').toString().toLowerCase();
      final codigo = (it['codigo'] ?? '').toString().toLowerCase();
      final categoria = (it['categoria'] ?? '').toString().toLowerCase();
      return nombre.contains(term) ||
          codigo.contains(term) ||
          categoria.contains(term);
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
          "Existencias y Valorización de Inventario",
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
      body: state.isLoading && items.isEmpty
          ? const Center(
              child: CustomLoading(text: "Cargando existencias de almacén..."))
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  // KPI Cards Compactas
                  Row(
                    children: [
                      _buildMetricCard(
                        title: "Ítems Inventariables",
                        value: "$totalProductos",
                        icon: Icons.category_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Unidades en Almacén",
                        value: _numberFormat.format(totalUnidades),
                        icon: Icons.all_inbox_outlined,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Valorización a Costo",
                        value: _currencyFormat.format(valorTotalCosto),
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        title: "Ítems en Alerta / Déficit",
                        value: "$enAlerta",
                        icon: Icons.report_problem_outlined,
                        color: enAlerta > 0 ? Colors.red : Colors.green,
                        subtitle: enAlerta > 0
                            ? "Requieren reposición"
                            : "Nivel óptimo",
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Barra de Filtros & Búsqueda Compacta
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Campo de búsqueda
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 28,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {
                                _currentPage = 1;
                              }),
                              style: const TextStyle(fontSize: 11),
                              decoration: InputDecoration(
                                hintText:
                                    "Buscar por código, nombre o categoría...",
                                hintStyle: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade400),
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
                                    vertical: 0, horizontal: 6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Filtro de Categoría Dropdown
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 28,
                            child: DropdownButtonFormField<int?>(
                              initialValue: _selectedCategoriaId,
                              isDense: true,
                              style: const TextStyle(
                                  fontSize: 10.5, color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: "Categoría",
                                labelStyle: const TextStyle(fontSize: 10),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text("Todas las categorías",
                                      style: TextStyle(fontSize: 10.5)),
                                ),
                                ...categoriasState.items.map(
                                  (cat) => DropdownMenuItem<int?>(
                                    value: cat.id,
                                    child: Text(
                                      cat.nombre,
                                      style: const TextStyle(fontSize: 10.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategoriaId = val;
                                  _currentPage = 1;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Selector de registros por página
                        SizedBox(
                          height: 28,
                          width: 85,
                          child: DropdownButtonFormField<int>(
                            initialValue: _rowsPerPage,
                            isDense: true,
                            style: const TextStyle(
                                fontSize: 10.5, color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Filas",
                              labelStyle: const TextStyle(fontSize: 9.5),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 15, child: Text("15")),
                              DropdownMenuItem(value: 20, child: Text("20")),
                              DropdownMenuItem(value: 50, child: Text("50")),
                              DropdownMenuItem(value: 100, child: Text("100")),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _rowsPerPage = v;
                                  _currentPage = 1;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Tabla de Existencias
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
                              label: Text("CÓDIGO",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 85,
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
                              label: Text("COSTO",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              numeric: true,
                              fixedWidth: 100,
                            ),
                            DataColumn2(
                              label: Text("VALOR COSTO",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              numeric: true,
                              fixedWidth: 140, // Ancho suficiente para evitar salto de línea
                            ),
                            DataColumn2(
                              label: Text("ACCIÓN",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                              fixedWidth: 65,
                            ),
                          ],
                          rows: pageItems.map((item) {
                            final stock = FormatterNumber.parseDouble(
                                item['stock_actual']);
                            final minimo = FormatterNumber.parseDouble(
                                item['stock_minimo']);
                            final costo =
                                FormatterNumber.parseDouble(item['costo']);
                            final valorCosto = FormatterNumber.parseDouble(
                                item['valor_costo']);

                            return DataRow2(
                              cells: [
                                DataCell(Text(
                                  item['codigo'] ?? '#${item['id']}',
                                  style: const TextStyle(
                                      fontSize: 10.5, color: Colors.blueGrey),
                                )),
                                DataCell(
                                  Text(
                                    item['nombre'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataCell(Text(
                                  item['categoria'] ?? '--',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                )),
                                DataCell(Text(
                                  item['unidad_medida'] ?? 'un.',
                                  style: const TextStyle(
                                      fontSize: 10.5, color: Colors.blueGrey),
                                )),
                                DataCell(_buildStockBadge(stock, minimo)),
                                DataCell(Text(
                                  minimo.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10.5),
                                )),
                                DataCell(Text(
                                  _currencyFormat.format(costo),
                                  style: const TextStyle(fontSize: 10.5),
                                )),
                                DataCell(Text(
                                  _currencyFormat.format(valorCosto),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.azulOscuro),
                                )),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.edit_note,
                                        size: 18, color: AppColors.primary),
                                    tooltip: "Ajustar este producto",
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      final prodModel = Producto(
                                        id: item['id'],
                                        nombre: item['nombre'],
                                        codigo: item['codigo'],
                                        stockActual: stock,
                                        stockMinimo: minimo,
                                        costo: costo,
                                        manejaInventario: true,
                                        tipoProducto: item['tipo_producto'],
                                      );
                                      _abrirNuevoAjuste(prodModel);
                                    },
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
                              ? "Mostrando ${startIndex + 1} - $endIndex de $totalItems productos"
                              : "No hay productos para mostrar",
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
