import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../model/company.dart';
import '../../../model/factura.dart';
import '../../../palletes/app_colors.dart';
import '../../../utils/helpers.dart';
import '../../services/printer_service.dart';
// import '../nota_credito_dialog.dart';

class FacturaDetallePanel extends StatefulWidget {
  final Factura? factura;
  final bool isLoading;
  final Map<String, dynamic>? resumen;
  final VoidCallback? onFacturaUpdated;

  const FacturaDetallePanel({
    super.key,
    required this.factura,
    this.isLoading = false,
    this.resumen,
    this.onFacturaUpdated,
  });

  @override
  State<FacturaDetallePanel> createState() => _FacturaDetallePanelState();
}

class _FacturaDetallePanelState extends State<FacturaDetallePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? estado) {
    final e = estado?.toLowerCase() ?? '';
    if (e == 'pagada') return Colors.green.shade700;
    if (e == 'pendiente') return Colors.orange.shade700;
    if (e == 'anulada') return Colors.red.shade700;
    return AppColors.azulOscuro;
  }

  Color _getEcfStatusColor(String estadoDgii) {
    final e = estadoDgii.toUpperCase();
    if (e.contains('ACEPTADO')) return Colors.teal.shade700;
    if (e.contains('PROCESO') || e == 'PENDIENTE') return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Future<void> _imprimirTicket(Factura factura) async {
    setState(() => _isPrinting = true);
    try {
      final items = (factura.detalles ?? []).map((det) {
        final desc = det.descripcion ?? det.producto?.nombre ?? 'Ítem';
        final cant = double.tryParse(det.cantidad?.toString() ?? '1') ?? 1.0;
        final precio = double.tryParse(det.precio?.toString() ?? '0') ?? 0.0;
        return ItemFactura(
          descripcion: desc,
          cantidad: cant,
          precioUnitario: precio,
        );
      }).toList();

      final subtotal = double.tryParse(factura.subtotal ?? '0') ?? 0;
      final itbis = double.tryParse(factura.itbis ?? '0') ?? 0;
      final desc = double.tryParse(factura.descuentoTotal ?? '0') ?? 0;
      final tot = double.tryParse(factura.total ?? '0') ?? 0;
      final ecf = factura.ecfDocumento;

      final res = await ThermalPrinterService.instance.imprimirFactura(
        nombreNegocio: Company.current.nombre,
        direccion: Company.current.direccionCompleta,
        rncOCedula: Company.current.rnc,
        numeroFactura: factura.id.toString(),
        ncf: factura.ncf,
        fecha: factura.fechaEmision ?? DateTime.now(),
        items: items,
        subtotal: subtotal,
        impuesto: itbis,
        descuento: desc,
        total: tot,
        cliente: factura.cliente?.nombre ?? 'Consumidor Final',
        rncCliente: factura.cliente?.rncCedula,
        tipoPago: factura.tipoFactura ?? 'CONTADO',
        qrUrl: ecf?.qrUrl,
        codigoSeguridad: ecf?.codigoSeguridad,
        fechaFirma: ecf?.fechaHoraFirma,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.mensaje),
            backgroundColor: res.exito ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Colors.grey.shade500,
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

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        color: const Color(0xFFF8F9FA),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.factura == null) {
      return Container(
        color: const Color(0xFFF8F9FA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 72,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 14),
              Text(
                'Selecciona una factura de la lista',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aquí se mostrarán todos sus artículos, firma electrónica e-CF y acciones.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    final f = widget.factura!;
    final ecf = f.ecfDocumento;
    final statusColor = _getStatusColor(f.estado);
    final subtotal = double.tryParse(f.subtotal ?? '0') ?? 0;
    final itbis = double.tryParse(f.itbis ?? '0') ?? 0;
    final desc = double.tryParse(f.descuentoTotal ?? '0') ?? 0;
    final total = double.tryParse(f.total ?? '0') ?? 0;
    final estadoStr = (f.estado ?? 'Emitida').toUpperCase();
    final fechaStr = f.fechaEmision != null
        ? FormatterNumber.formatFechaHora(f.fechaEmision!)
        : (f.createdAt != null
            ? FormatterNumber.formatFechaHora(f.createdAt!)
            : 'N/A');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: Container(
        key: ValueKey(f.id),
        color: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            // ── CABECERA DEL DETALLE ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              "Factura #${f.id} — ${f.ncf?.isNotEmpty == true ? f.ncf! : 'Sin NCF'}",
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                estadoStr,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            if (ecf != null)
                              Tooltip(
                                message:
                                    'Firmado: ${ecf.fechaHoraFirma} • TrackId: ${ecf.trackId ?? "N/A"} • Ambiente: ${ecf.ambiente}',
                                child: InkWell(
                                  onTap: ecf.qrUrl.isNotEmpty
                                      ? () async {
                                          final uri = Uri.tryParse(ecf.qrUrl);
                                          if (uri != null) {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode.externalApplication,
                                            );
                                          }
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getEcfStatusColor(ecf.estadoDgii)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getEcfStatusColor(
                                          ecf.estadoDgii,
                                        ).withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified_outlined,
                                          size: 11,
                                          color: _getEcfStatusColor(
                                            ecf.estadoDgii,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'e-CF ${ecf.estadoDgii} • Cód: ${ecf.codigoSeguridad}',
                                          style: TextStyle(
                                            color: _getEcfStatusColor(
                                              ecf.estadoDgii,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Cliente: ${f.cliente?.nombre ?? 'Consumidor Final'}  •  Vendedor: ${f.user?.name ?? 'Admin'}  •  Fecha: $fechaStr",
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isPrinting ? null : () => _imprimirTicket(f),
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined, size: 15),
                    label: const Text(
                      "Imprimir Ticket",
                      style: TextStyle(fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulOscuro,
                      side: const BorderSide(color: AppColors.azulOscuro),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── TARJETAS KPIS RÁPIDOS ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildKpiCard(
                    title: "Subtotal",
                    value: FormatterNumber.formatCurrency(subtotal),
                    subtitle: "Sin impuestos",
                    icon: Icons.layers_outlined,
                    color: AppColors.azulOscuro,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    title: "Descuento",
                    value: FormatterNumber.formatCurrency(desc),
                    subtitle: "Rebajas aplicadas",
                    icon: Icons.discount_outlined,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    title: "ITBIS (18%)",
                    value: FormatterNumber.formatCurrency(itbis),
                    subtitle: "Impuesto fiscal",
                    icon: Icons.account_balance_outlined,
                    color: Colors.indigo.shade700,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    title: "Total Factura",
                    value: FormatterNumber.formatCurrency(total),
                    subtitle: "Monto neto",
                    icon: Icons.monetization_on_outlined,
                    color: statusColor,
                  ),
                ],
              ),
            ),

            // ── TABS SELECTOR (Artículos, Acciones, Totales del Período) ────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.azulOscuro,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.azulOscuro,
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.format_list_bulleted, size: 15),
                        SizedBox(width: 6),
                        Text(
                          "Artículos Vendidos",
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 15),
                        SizedBox(width: 6),
                        Text(
                          "Acciones del Documento",
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline, size: 15),
                        SizedBox(width: 6),
                        Text(
                          "Totales del Período",
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── CUERPO DE LAS PESTAÑAS ──────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabArticulos(f),
                  _buildTabAcciones(context, f),
                  _buildTabTotalesPeriodo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabArticulos(Factura f) {
    final detalles = f.detalles ?? [];

    if (detalles.isEmpty) {
      return Center(
        child: Text(
          "No hay artículos registrados para esta factura.",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: detalles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, idx) {
        final item = detalles[idx];
        final desc =
            item.descripcion ?? item.producto?.nombre ?? 'Producto sin nombre';
        final cant = double.tryParse(item.cantidad?.toString() ?? '1') ?? 1.0;
        final precio = double.tryParse(item.precio?.toString() ?? '0') ?? 0.0;
        final itbis = double.tryParse(item.itbis?.toString() ?? '0') ?? 0.0;
        final totalLinea =
            double.tryParse(item.total?.toString() ?? '0') ??
            (cant * precio + itbis);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.azulOscuro.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${cant == cant.truncateToDouble() ? cant.toInt() : cant.toStringAsFixed(1)}x",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.azulOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.azulOscuro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Precio: ${FormatterNumber.formatCurrency(precio)}  •  ITBIS: ${FormatterNumber.formatCurrency(itbis)}",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                FormatterNumber.formatCurrency(totalLinea),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: AppColors.azulOscuro,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabAcciones(BuildContext context, Factura f) {
    final ecf = f.ecfDocumento;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Acciones Disponibles para este Documento:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                icon: Icons.print_outlined,
                label: "Imprimir Ticket",
                color: Colors.teal.shade700,
                onTap: () => _imprimirTicket(f),
              ),
              if (ecf != null && ecf.qrUrl.isNotEmpty)
                _buildActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: "Timbre DGII",
                  color: Colors.green.shade700,
                  onTap: () async {
                    final uri = Uri.tryParse(ecf.qrUrl);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              // TODO: Funcionalidad temporalmente comentada
              // _buildActionButton(
              //   icon: Icons.remove_circle_outline,
              //   label: "Nota de Crédito",
              //   color: Colors.purple.shade700,
              //   onTap: () {
              //     showDialog(
              //       context: context,
              //       builder: (_) => NotaCreditoDialog(factura: f),
              //     );
              //   },
              // ),
              _buildActionButton(
                icon: Icons.add_circle_outline,
                label: "Nota de Débito",
                color: Colors.indigo.shade700,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Módulo de Nota de Débito en desarrollo'),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: "Compartir",
                color: Colors.blue.shade700,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comprobante copiado al portapapeles'),
                    ),
                  );
                },
              ),
              // TODO: Funcionalidad de anulación temporalmente comentada
              // _buildActionButton(
              //   icon: Icons.cancel_outlined,
              //   label: "Anular Factura",
              //   color: Colors.red.shade700,
              //   onTap: () {
              //     _mostrarDialogoAnulacion(context, f);
              //   },
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /*
  void _mostrarDialogoAnulacion(BuildContext context, Factura f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("¿Anular Factura?"),
          ],
        ),
        content: Text(
          "¿Estás seguro de que deseas anular la Factura #${f.id} (${f.ncf ?? 'Sin NCF'})? Esta acción no se puede deshacer.",
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Solicitud de anulación procesada"),
                  backgroundColor: Colors.orange,
                ),
              );
              widget.onFacturaUpdated?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("ANULAR"),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildTabTotalesPeriodo() {
    final resumen = widget.resumen;
    if (resumen == null) {
      return Center(
        child: Text(
          "No hay totales acumulados disponibles para el filtro actual.",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    final totales = resumen['totales'] as Map<String, dynamic>? ?? {};
    final porMetodo = resumen['por_metodo'] as List<dynamic>? ?? [];

    final cantFacturas = totales['cantidad_facturas'] ?? 0;
    final totalVendido =
        double.tryParse((totales['total_venta'] ?? 0).toString()) ?? 0;
    final totalItbis =
        double.tryParse((totales['total_itbis'] ?? 0).toString()) ?? 0;
    final totalDesc =
        double.tryParse((totales['total_descuento'] ?? 0).toString()) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Resumen Financiero del Período Filtrado:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(height: 10),
                _resumenRow("Cantidad de Facturas:", "$cantFacturas emitidas"),
                _resumenRow(
                  "Total Facturado:",
                  FormatterNumber.formatCurrency(totalVendido),
                  isHighlight: true,
                ),
                _resumenRow(
                  "Total ITBIS Recaudado:",
                  FormatterNumber.formatCurrency(totalItbis),
                ),
                _resumenRow(
                  "Descuentos Otorgados:",
                  FormatterNumber.formatCurrency(totalDesc),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (porMetodo.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cobros por Método de Pago:",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...porMetodo.map((m) {
                    final metodo = (m['metodo_pago'] ?? '')
                        .toString()
                        .toUpperCase();
                    final tot =
                        double.tryParse((m['total'] ?? 0).toString()) ?? 0;
                    final pct = totalVendido > 0 ? (tot / totalVendido) : 0.0;

                    Color color = Colors.green;
                    IconData icon = Icons.money;
                    if (metodo.contains('TARJETA')) {
                      color = Colors.indigo;
                      icon = Icons.credit_card;
                    } else if (metodo.contains('TRANSFERENCIA')) {
                      color = Colors.deepOrange;
                      icon = Icons.account_balance;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 6),
                              Text(
                                metodo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                FormatterNumber.formatCurrency(tot),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(${(pct * 100).toStringAsFixed(1)}%)",
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade200,
                            color: color,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resumenRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 13 : 11.5,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.azulOscuro : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
