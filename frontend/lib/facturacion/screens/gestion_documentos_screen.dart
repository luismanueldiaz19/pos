import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../model/factura.dart';
import '../../utils/helpers.dart';
import '../providers/facturacion_historial_provider.dart';
import 'widgets/factura_list_item.dart';
import 'widgets/factura_detalle_panel.dart';
import '../../modulo_cliente/widgets/paginador.dart';
import '../../widgets/custom_loading.dart';
import '../../widgets/custom_text_field.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class GestionDocumentosScreen extends ConsumerStatefulWidget {
  const GestionDocumentosScreen({super.key});

  @override
  ConsumerState<GestionDocumentosScreen> createState() =>
      _GestionDocumentosScreenState();
}

class _GestionDocumentosScreenState
    extends ConsumerState<GestionDocumentosScreen> {
  final _searchController = TextEditingController();
  final _fechaDesdeController = TextEditingController();
  final _fechaHastaController = TextEditingController();
  final _scrollController = ScrollController();

  Factura? _selectedFactura;
  bool _isExportingPdf = false;

  Future<void> _exportarPdfReporte() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    setState(() => _isExportingPdf = true);
    try {
      final notifier = ref.read(facturacionHistorialProvider.notifier);
      final pdfUrlPath = await notifier.obtenerPdfReporteUrl(token);

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
        showToast(context, 'Error al exportar: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(facturacionHistorialProvider.notifier).fetchHistorial(token);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fechaDesdeController.dispose();
    _fechaHastaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearAllFilters(String? token) {
    if (token == null) return;
    _searchController.clear();
    _fechaDesdeController.clear();
    _fechaHastaController.clear();
    setState(() => _selectedFactura = null);
    ref.read(facturacionHistorialProvider.notifier).clearFilters(token);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facturacionHistorialProvider);
    final auth = ref.watch(authProvider);

    // Mantener sincronizada la factura seleccionada si se refresca la lista
    if (_selectedFactura != null && state.historial.isNotEmpty) {
      final updated = state.historial.firstWhere(
        (f) => f.id == _selectedFactura!.id,
        orElse: () => _selectedFactura!,
      );
      if (updated != _selectedFactura) {
        _selectedFactura = updated;
      }
    }

    // Totales rápidos para el mini banner
    final totales = state.resumen?['totales'] as Map<String, dynamic>? ?? {};
    final double totalVendido =
        double.tryParse((totales['total_venta'] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'GESTIÓN DE FACTURAS Y DOCUMENTOS',
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
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
                  : const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
              label: const Text(
                'Reporte PDF',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar Facturas',
            onPressed: () {
              if (auth.token != null) {
                ref
                    .read(facturacionHistorialProvider.notifier)
                    .fetchHistorial(auth.token!);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── BARRA SUPERIOR DE FILTROS ─────────────────────────────────────
          _buildFilterBar(auth.token, state),

          // ── CUERPO PRINCIPAL: VISTA MASTER - DETAIL ───────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LADO IZQUIERDO: LISTA DE FACTURAS ───────────────────────
                Container(
                  width: 350,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.black12)),
                  ),
                  child: Column(
                    children: [
                      // Buscador en vivo
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomTextField(
                          label: "",
                          hintText: "Buscar NCF, cliente o ID...",
                          controller: _searchController,
                          prefixIcon: Icons.search_rounded,
                          onChanged: (value) {
                            if (auth.token != null) {
                              ref
                                  .read(facturacionHistorialProvider.notifier)
                                  .updateFilters(auth.token!, {'search': value});
                            }
                          },
                          onSuffixIconTap: () {
                            _searchController.clear();
                            if (auth.token != null) {
                              final newFilters = Map<String, String>.from(
                                state.filters,
                              );
                              newFilters.remove('search');
                              ref
                                  .read(facturacionHistorialProvider.notifier)
                                  .updateFilters(auth.token!, newFilters, replace: true);
                            }
                            setState(() {});
                          },
                          suffixIcon: _searchController.text.isNotEmpty
                              ? Icons.clear_rounded
                              : null,
                        ),
                      ),

                      // Mini resumen de totales del filtro
                      if (state.total > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.azulOscuro.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.azulOscuro.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt_outlined,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${state.total} Facturas",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "Total: ${FormatterNumber.formatCurrency(totalVendido)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.azulOscuro,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Lista scrollable con Stack de carga
                      Expanded(
                        child: Stack(
                          children: [
                            if (!state.isLoading && state.historial.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "No se encontraron facturas",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Ajusta los filtros o limpia la búsqueda.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                itemCount: state.historial.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final factura = state.historial[index];
                                  final isSelected =
                                      _selectedFactura?.id == factura.id;

                                  return FacturaListItem(
                                    factura: factura,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedFactura = factura;
                                      });
                                    },
                                  );
                                },
                              ),
                            if (state.isLoading)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  child: const CustomLoading(
                                    text: "Cargando facturas...",
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Paginador
                      if (state.historial.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Column(
                            children: [
                              Paginador(
                                currentPage: state.currentPage,
                                totalPages: state.lastPage,
                                onPageChanged: (page) {
                                  if (auth.token != null) {
                                    ref
                                        .read(
                                          facturacionHistorialProvider.notifier,
                                        )
                                        .setPage(auth.token!, page);
                                  }
                                },
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total de registros: ${state.total}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // ── LADO DERECHO: PANEL DE DETALLES Y ACCIONES ──────────────
                Expanded(
                  child: FacturaDetallePanel(
                    factura: _selectedFactura,
                    isLoading: state.isLoading && _selectedFactura == null,
                    resumen: state.resumen,
                    onFacturaUpdated: () {
                      if (auth.token != null) {
                        ref
                            .read(facturacionHistorialProvider.notifier)
                            .fetchHistorial(auth.token!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(String? token, FacturacionHistorialState state) {
    final estadoActual = state.filters['estado']?.toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filtros de estado
            const Text(
              "Estado:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: "Todos",
              isSelected: estadoActual == null,
              onTap: () {
                if (token != null) {
                  final newFilters = Map<String, String>.from(state.filters);
                  newFilters.remove('estado');
                  ref
                      .read(facturacionHistorialProvider.notifier)
                      .updateFilters(token, newFilters, replace: true);
                }
              },
            ),
            _buildChip(
              label: "Pagadas",
              isSelected: estadoActual == 'pagada',
              onTap: () {
                if (token != null) {
                  ref
                      .read(facturacionHistorialProvider.notifier)
                      .updateFilters(token, {'estado': 'pagada'});
                }
              },
            ),
            _buildChip(
              label: "Pendientes",
              isSelected: estadoActual == 'pendiente',
              onTap: () {
                if (token != null) {
                  ref
                      .read(facturacionHistorialProvider.notifier)
                      .updateFilters(token, {'estado': 'pendiente'});
                }
              },
            ),
            _buildChip(
              label: "Anuladas",
              isSelected: estadoActual == 'anulada',
              onTap: () {
                if (token != null) {
                  ref
                      .read(facturacionHistorialProvider.notifier)
                      .updateFilters(token, {'estado': 'anulada'});
                }
              },
            ),
            const SizedBox(width: 16),

            // Selector de Fecha Desde
            SizedBox(
              width: 140,
              child: _buildDateInput(
                label: "Fecha Desde",
                controller: _fechaDesdeController,
                onTap: () async {
                  final date = await showCustomDatePicker(context);
                  if (date != null && token != null) {
                    final formatted = formatDate(date);
                    _fechaDesdeController.text = formatted;
                    ref
                        .read(facturacionHistorialProvider.notifier)
                        .updateFilters(token, {'fecha_desde': formatted});
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // Selector de Fecha Hasta
            SizedBox(
              width: 140,
              child: _buildDateInput(
                label: "Fecha Hasta",
                controller: _fechaHastaController,
                onTap: () async {
                  final date = await showCustomDatePicker(context);
                  if (date != null && token != null) {
                    final formatted = formatDate(date);
                    _fechaHastaController.text = formatted;
                    ref
                        .read(facturacionHistorialProvider.notifier)
                        .updateFilters(token, {'fecha_hasta': formatted});
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // Botón Limpiar
            OutlinedButton.icon(
              onPressed: () => _clearAllFilters(token),
              icon: const Icon(Icons.clear_all_rounded, size: 15),
              label: const Text("Limpiar"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.azulOscuro : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.azulOscuro : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateInput({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.text.isNotEmpty ? controller.text : label,
                style: TextStyle(
                  fontSize: 11,
                  color: controller.text.isNotEmpty
                      ? AppColors.azulOscuro
                      : Colors.grey.shade500,
                  fontWeight: controller.text.isNotEmpty
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  final token = ref.read(authProvider).token;
                  if (token != null) {
                    final filters = Map<String, String>.from(
                      ref.read(facturacionHistorialProvider).filters,
                    );
                    filters.remove(label == "Fecha Desde" ? 'fecha_desde' : 'fecha_hasta');
                    ref
                        .read(facturacionHistorialProvider.notifier)
                        .updateFilters(token, filters, replace: true);
                  }
                },
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}
