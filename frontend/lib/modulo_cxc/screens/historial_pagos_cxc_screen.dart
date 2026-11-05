import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../modulo_cliente/widgets/paginador.dart';
import '../models/pago_cxc.dart';
import '../providers/cxc_provider.dart';

class HistorialPagosCxcScreen extends ConsumerStatefulWidget {
  const HistorialPagosCxcScreen({super.key});

  @override
  ConsumerState<HistorialPagosCxcScreen> createState() =>
      _HistorialPagosCxcScreenState();
}

class _HistorialPagosCxcScreenState
    extends ConsumerState<HistorialPagosCxcScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _fechaDesdeCtrl = TextEditingController();
  final TextEditingController _fechaHastaCtrl = TextEditingController();

  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String _selectedMetodo = 'todos';
  String _quickDateFilter = 'todo';

  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isExportingPdf = false;

  Future<void> _exportarPdfReporte() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    setState(() => _isExportingPdf = true);
    try {
      final filters = <String, String>{};
      if (_searchCtrl.text.trim().isNotEmpty) {
        filters['search'] = _searchCtrl.text.trim();
      }
      if (_fechaDesde != null) {
        filters['fecha_desde'] = formatDate(_fechaDesde!);
      }
      if (_fechaHasta != null) {
        filters['fecha_hasta'] = formatDate(_fechaHasta!);
      }
      if (_selectedMetodo != 'todos') {
        filters['metodo_pago'] = _selectedMetodo;
      }

      final pdfUrlPath = await ref
          .read(cxcProvider.notifier)
          .obtenerPdfReporteUrl(token, filters: filters);

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
    Future.microtask(
      () => ref.read(cxcProvider.notifier).loadHistorialPagos(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fechaDesdeCtrl.dispose();
    _fechaHastaCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _fechaDesdeCtrl.clear();
      _fechaHastaCtrl.clear();
      _fechaDesde = null;
      _fechaHasta = null;
      _selectedMetodo = 'todos';
      _quickDateFilter = 'todo';
      _currentPage = 1;
    });
  }

  void _setQuickDate(String type) {
    final now = DateTime.now();
    setState(() {
      _quickDateFilter = type;
      _currentPage = 1;
      if (type == 'hoy') {
        _fechaDesde = DateTime(now.year, now.month, now.day);
        _fechaHasta = DateTime(now.year, now.month, now.day, 23, 59, 59);
        _fechaDesdeCtrl.text = formatDate(_fechaDesde!);
        _fechaHastaCtrl.text = formatDate(_fechaHasta!);
      } else if (type == 'semana') {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        _fechaDesde = DateTime(monday.year, monday.month, monday.day);
        _fechaHasta = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        _fechaDesdeCtrl.text = formatDate(_fechaDesde!);
        _fechaHastaCtrl.text = formatDate(_fechaHasta!);
      } else if (type == 'mes') {
        _fechaDesde = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        _fechaHasta = DateTime(now.year, now.month, lastDay.day, 23, 59, 59);
        _fechaDesdeCtrl.text = formatDate(_fechaDesde!);
        _fechaHastaCtrl.text = formatDate(_fechaHasta!);
      } else {
        // 'todo'
        _fechaDesde = null;
        _fechaHasta = null;
        _fechaDesdeCtrl.clear();
        _fechaHastaCtrl.clear();
      }
    });
  }

  List<PagoCxc> _obtenerPagosParaTotales(List<PagoCxc> pagos) {
    final query = _searchCtrl.text.trim().toLowerCase();

    return pagos.where((p) {
      // 1. Filtro de búsqueda
      if (query.isNotEmpty) {
        final clienteNombre =
            (p.cuentaPorCobrar?['cliente']?['nombre'] ?? '').toString().toLowerCase();
        final ncf =
            (p.cuentaPorCobrar?['factura']?['ncf'] ?? '').toString().toLowerCase();
        final idRecibo = p.id.toString();
        final metodo = p.metodoPago.toLowerCase();
        final ref = (p.referencia ?? '').toLowerCase();

        final match = clienteNombre.contains(query) ||
            ncf.contains(query) ||
            idRecibo.contains(query) ||
            metodo.contains(query) ||
            ref.contains(query);

        if (!match) return false;
      }

      // 2. Filtro de rango de fecha
      if (_fechaDesde != null || _fechaHasta != null) {
        final parsedDate = DateTime.tryParse(p.fechaPago);
        if (parsedDate != null) {
          if (_fechaDesde != null) {
            final fDesde = DateTime(
              _fechaDesde!.year,
              _fechaDesde!.month,
              _fechaDesde!.day,
            );
            if (parsedDate.isBefore(fDesde)) return false;
          }
          if (_fechaHasta != null) {
            final fHasta = DateTime(
              _fechaHasta!.year,
              _fechaHasta!.month,
              _fechaHasta!.day,
              23,
              59,
              59,
            );
            if (parsedDate.isAfter(fHasta)) return false;
          }
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cxcProvider);

    // 1. Obtener cobros en período/búsqueda para totales agrupados
    final pagosEnPeriodo = _obtenerPagosParaTotales(state.historialPagos);
    final double totalRecaudado =
        pagosEnPeriodo.fold(0.0, (sum, p) => sum + p.montoPagado);
    final int totalCobros = pagosEnPeriodo.length;

    // Desglose agrupado por método
    double totalEfectivo = 0.0;
    int cantEfectivo = 0;
    double totalTarjeta = 0.0;
    int cantTarjeta = 0;
    double totalTransferencia = 0.0;
    int cantTransferencia = 0;

    for (final p in pagosEnPeriodo) {
      final m = p.metodoPago.toLowerCase();
      if (m.contains('tarjeta')) {
        totalTarjeta += p.montoPagado;
        cantTarjeta++;
      } else if (m.contains('transferencia')) {
        totalTransferencia += p.montoPagado;
        cantTransferencia++;
      } else {
        totalEfectivo += p.montoPagado;
        cantEfectivo++;
      }
    }

    // 2. Lista final filtrada por método (si aplica)
    final listaFiltrada = _selectedMetodo == 'todos'
        ? pagosEnPeriodo
        : pagosEnPeriodo.where((p) {
            final m = p.metodoPago.toLowerCase();
            return m.contains(_selectedMetodo);
          }).toList();

    // 3. Paginación
    final totalItems = listaFiltrada.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999999);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final itemsPagina = totalItems > 0
        ? listaFiltrada.sublist(startIndex, endIndex)
        : <PagoCxc>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Cobros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Registro y comprobantes de abonos en cuentas por cobrar',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
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
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () =>
                ref.read(cxcProvider.notifier).loadHistorialPagos(),
            tooltip: 'Actualizar historial',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── PANEL SUPERIOR: TOTALES AGRUPADOS (MÉTRICAS POR MÉTODO) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _buildTotalesAgrupados(
              totalRecaudado: totalRecaudado,
              totalCobros: totalCobros,
              totalEfectivo: totalEfectivo,
              cantEfectivo: cantEfectivo,
              totalTarjeta: totalTarjeta,
              cantTarjeta: cantTarjeta,
              totalTransferencia: totalTransferencia,
              cantTransferencia: cantTransferencia,
            ),
          ),

          // ── BARRA DE FILTROS: RANGO DE FECHAS, MÉTODOS Y BUSCADOR ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildBarraFiltros(),
          ),

          const SizedBox(height: 10),

          // ── LISTADO PAGINADO DE COBROS ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: state.isLoadingHistorial && state.historialPagos.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.azulOscuro,
                        strokeWidth: 2.5,
                      ),
                    )
                  : listaFiltrada.isEmpty
                      ? _buildEmptyState(state.historialPagos.isEmpty)
                      : ListView.separated(
                          itemCount: itemsPagina.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = itemsPagina[index];
                            return _buildPagoCard(p);
                          },
                        ),
            ),
          ),

          // ── BARRA INFERIOR DE PAGINACIÓN ──
          if (listaFiltrada.isNotEmpty)
            _buildPaginationBar(
              totalItems: totalItems,
              startIndex: startIndex,
              endIndex: endIndex,
              totalPages: totalPages,
            ),
        ],
      ),
    );
  }

  // ── 1. WIDGET: TOTALES AGRUPADOS ──────────────────────────────────────────
  Widget _buildTotalesAgrupados({
    required double totalRecaudado,
    required int totalCobros,
    required double totalEfectivo,
    required int cantEfectivo,
    required double totalTarjeta,
    required int cantTarjeta,
    required double totalTransferencia,
    required int cantTransferencia,
  }) {
    final pctEfectivo =
        totalRecaudado > 0 ? (totalEfectivo / totalRecaudado * 100) : 0.0;
    final pctTarjeta =
        totalRecaudado > 0 ? (totalTarjeta / totalRecaudado * 100) : 0.0;
    final pctTransf =
        totalRecaudado > 0 ? (totalTransferencia / totalRecaudado * 100) : 0.0;

    return Row(
      children: [
        // Tarjeta 1: Total General
        Expanded(
          flex: 4,
          child: _buildMetricaCard(
            titulo: 'TOTAL RECAUDADO',
            monto: totalRecaudado,
            subtitulo: '$totalCobros cobro(s)',
            icono: Icons.savings_outlined,
            color: const Color(0xFF059669),
            isSelected: _selectedMetodo == 'todos',
            onTap: () {
              setState(() {
                _selectedMetodo = 'todos';
                _currentPage = 1;
              });
            },
          ),
        ),
        const SizedBox(width: 8),

        // Tarjeta 2: Efectivo
        Expanded(
          flex: 3,
          child: _buildMetricaCard(
            titulo: 'EFECTIVO',
            monto: totalEfectivo,
            subtitulo: '$cantEfectivo cobros (${pctEfectivo.toStringAsFixed(1)}%)',
            icono: Icons.payments_rounded,
            color: const Color(0xFF047857),
            isSelected: _selectedMetodo == 'efectivo',
            onTap: () {
              setState(() {
                _selectedMetodo =
                    _selectedMetodo == 'efectivo' ? 'todos' : 'efectivo';
                _currentPage = 1;
              });
            },
          ),
        ),
        const SizedBox(width: 8),

        // Tarjeta 3: Tarjeta
        Expanded(
          flex: 3,
          child: _buildMetricaCard(
            titulo: 'TARJETA',
            monto: totalTarjeta,
            subtitulo: '$cantTarjeta cobros (${pctTarjeta.toStringAsFixed(1)}%)',
            icono: Icons.credit_card_rounded,
            color: const Color(0xFF1D4ED8),
            isSelected: _selectedMetodo == 'tarjeta',
            onTap: () {
              setState(() {
                _selectedMetodo =
                    _selectedMetodo == 'tarjeta' ? 'todos' : 'tarjeta';
                _currentPage = 1;
              });
            },
          ),
        ),
        const SizedBox(width: 8),

        // Tarjeta 4: Transferencia
        Expanded(
          flex: 3,
          child: _buildMetricaCard(
            titulo: 'TRANSFERENCIA',
            monto: totalTransferencia,
            subtitulo: '$cantTransferencia cobros (${pctTransf.toStringAsFixed(1)}%)',
            icono: Icons.account_balance_rounded,
            color: const Color(0xFFC2410C),
            isSelected: _selectedMetodo == 'transferencia',
            onTap: () {
              setState(() {
                _selectedMetodo = _selectedMetodo == 'transferencia'
                    ? 'todos'
                    : 'transferencia';
                _currentPage = 1;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricaCard({
    required String titulo,
    required double monto,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: color, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? color : const Color(0xFF64748B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (isSelected && titulo != 'TOTAL RECAUDADO')
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    FormatterNumber.formatCurrency(monto),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? color : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
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

  // ── 2. WIDGET: BARRA DE FILTROS ───────────────────────────────────────────
  Widget _buildBarraFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila superior: Buscador + Fechas + Limpiar
          Row(
            children: [
              // Buscador de texto
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) {
                      setState(() {
                        _currentPage = 1;
                      });
                    },
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText:
                          'Buscar por cliente, NCF, método o referencia...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 14),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _currentPage = 1;
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Fecha Desde
              SizedBox(
                width: 140,
                height: 34,
                child: _buildDateButton(
                  hint: 'Fecha Desde',
                  value: _fechaDesde != null
                      ? FormatterNumber.formatFechaLatina(_fechaDesde!)
                      : null,
                  onTap: () async {
                    final picked = await showCustomDatePicker(context);
                    if (picked != null) {
                      setState(() {
                        _fechaDesde = picked;
                        _fechaDesdeCtrl.text = formatDate(picked);
                        _quickDateFilter = 'custom';
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Fecha Hasta
              SizedBox(
                width: 140,
                height: 34,
                child: _buildDateButton(
                  hint: 'Fecha Hasta',
                  value: _fechaHasta != null
                      ? FormatterNumber.formatFechaLatina(_fechaHasta!)
                      : null,
                  onTap: () async {
                    final picked = await showCustomDatePicker(context);
                    if (picked != null) {
                      setState(() {
                        _fechaHasta = picked;
                        _fechaHastaCtrl.text = formatDate(picked);
                        _quickDateFilter = 'custom';
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Botón Limpiar
              SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 14),
                  label: const Text('Limpiar', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fila inferior: Chips rápidos de rango de fecha + Método de pago
          Row(
            children: [
              const Text(
                'Período:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              _buildMiniChip(
                label: 'Todo',
                isSelected: _quickDateFilter == 'todo',
                onTap: () => _setQuickDate('todo'),
              ),
              _buildMiniChip(
                label: 'Hoy',
                isSelected: _quickDateFilter == 'hoy',
                onTap: () => _setQuickDate('hoy'),
              ),
              _buildMiniChip(
                label: 'Esta Semana',
                isSelected: _quickDateFilter == 'semana',
                onTap: () => _setQuickDate('semana'),
              ),
              _buildMiniChip(
                label: 'Este Mes',
                isSelected: _quickDateFilter == 'mes',
                onTap: () => _setQuickDate('mes'),
              ),

              const SizedBox(width: 10),
              Container(
                height: 16,
                width: 1,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 10),

              const Text(
                'Método:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              _buildMiniChip(
                label: 'Todos',
                isSelected: _selectedMetodo == 'todos',
                onTap: () {
                  setState(() {
                    _selectedMetodo = 'todos';
                    _currentPage = 1;
                  });
                },
              ),
              _buildMiniChip(
                label: 'Efectivo',
                isSelected: _selectedMetodo == 'efectivo',
                onTap: () {
                  setState(() {
                    _selectedMetodo = 'efectivo';
                    _currentPage = 1;
                  });
                },
              ),
              _buildMiniChip(
                label: 'Tarjeta',
                isSelected: _selectedMetodo == 'tarjeta',
                onTap: () {
                  setState(() {
                    _selectedMetodo = 'tarjeta';
                    _currentPage = 1;
                  });
                },
              ),
              _buildMiniChip(
                label: 'Transferencia',
                isSelected: _selectedMetodo == 'transferencia',
                onTap: () {
                  setState(() {
                    _selectedMetodo = 'transferencia';
                    _currentPage = 1;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasValue ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: hasValue ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasValue ? value : hint,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                  color: hasValue ? const Color(0xFF0F172A) : Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // ── 3. WIDGET: TARJETA DE PAGO (RECIBO) ───────────────────────────────────
  Widget _buildPagoCard(PagoCxc p) {
    final clienteNombre =
        p.cuentaPorCobrar?['cliente']?['nombre'] ?? 'Cliente General';
    final ncfFactura = p.cuentaPorCobrar?['factura']?['ncf'] ?? 'N/A';
    final bancoNombre = p.cuentaDestino?['bank']?['name'] ?? '';

    // Fecha limpia formateada
    final parsedDate = DateTime.tryParse(p.fechaPago);
    final fechaLimpia = parsedDate != null
        ? FormatterNumber.formatFechaLatina(parsedDate)
        : p.fechaPago.split('T')[0];

    // Icono y color según método
    IconData mIcon;
    Color mColor;
    final m = p.metodoPago.toLowerCase();
    if (m.contains('tarjeta')) {
      mIcon = Icons.credit_card_rounded;
      mColor = const Color(0xFF1D4ED8);
    } else if (m.contains('transferencia')) {
      mIcon = Icons.account_balance_rounded;
      mColor = const Color(0xFFC2410C);
    } else {
      mIcon = Icons.payments_rounded;
      mColor = const Color(0xFF047857);
    }

    return InkWell(
      onTap: () => _mostrarDetalleCobro(p, fechaLimpia),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icono recibo
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_rounded,
                color: Color(0xFF059669),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clienteNombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'NCF: $ncfFactura',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Fecha formateada (limpia, sin T00:00:00)
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fechaLimpia,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Método de pago chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: mColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: mColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(mIcon, size: 10, color: mColor),
                            const SizedBox(width: 4),
                            Text(
                              p.metodoPago.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: mColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (bancoNombre.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '($bancoNombre)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],

                      if (p.referencia != null && p.referencia!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            'Ref: ${p.referencia}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Monto cobrado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatterNumber.formatCurrency(p.montoPagado),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF059669),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'COBRADO',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. WIDGET: BARRA DE PAGINACIÓN ────────────────────────────────────────
  Widget _buildPaginationBar({
    required int totalItems,
    required int startIndex,
    required int endIndex,
    required int totalPages,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando ${totalItems > 0 ? startIndex + 1 : 0} - $endIndex de $totalItems cobros',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Paginador(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: (newPage) {
              setState(() {
                _currentPage = newPage;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── 5. MODAL: DETALLE DEL COBRO ───────────────────────────────────────────
  void _mostrarDetalleCobro(PagoCxc p, String fechaLimpia) {
    final cliente = p.cuentaPorCobrar?['cliente']?['nombre'] ?? 'Cliente General';
    final rnc = p.cuentaPorCobrar?['cliente']?['rnc_cedula'] ?? 'N/A';
    final ncf = p.cuentaPorCobrar?['factura']?['ncf'] ?? 'N/A';
    final facturaId = p.cuentaPorCobrar?['factura']?['id'] ?? 'N/A';
    final cajero = p.usuario?['name'] ?? 'Administrador';
    final banco = p.cuentaDestino?['bank']?['name'] ??
        p.cuentaDestino?['nombre'] ??
        'Caja Principal';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recibo de Cobro #${p.id}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Comprobante de ingreso a Cuenta por Cobrar',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'MONTO COBRADO',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FormatterNumber.formatCurrency(p.montoPagado),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              _buildDetalleFila('Cliente:', cliente),
              _buildDetalleFila('RNC / Cédula:', rnc.toString()),
              _buildDetalleFila('Factura:', '#$facturaId • $ncf'),
              _buildDetalleFila('Método de Pago:', p.metodoPago.toUpperCase()),
              _buildDetalleFila('Fecha de Cobro:', fechaLimpia),
              _buildDetalleFila('Cuenta Destino / Banco:', banco.toString()),
              if (p.referencia != null && p.referencia!.isNotEmpty)
                _buildDetalleFila('Referencia:', p.referencia!),
              _buildDetalleFila('Cajero / Usuario:', cajero.toString()),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulOscuro,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Cerrar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleFila(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. WIDGET: ESTADO VACÍO ───────────────────────────────────────────────
  Widget _buildEmptyState(bool noDataTotal) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              noDataTotal
                  ? 'No hay cobros registrados'
                  : 'No se encontraron resultados',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              noDataTotal
                  ? 'Los abonos realizados a cuentas por cobrar aparecerán aquí.'
                  : 'Ningún recibo coincide con los filtros o el rango de fecha seleccionado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
            ),
            if (!noDataTotal) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all_rounded, size: 14),
                label: const Text('Limpiar Filtros', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.azulOscuro,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
