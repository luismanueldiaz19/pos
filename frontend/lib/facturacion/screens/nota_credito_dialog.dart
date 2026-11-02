import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../model/factura.dart';
import '../../utils/helpers.dart';
import '../providers/facturacion_historial_provider.dart';
import '../services/printer_service.dart';
import '../services/facturacion_service.dart';

class NotaCreditoDialog extends ConsumerStatefulWidget {
  final Factura factura;

  const NotaCreditoDialog({super.key, required this.factura});

  @override
  ConsumerState<NotaCreditoDialog> createState() => _NotaCreditoDialogState();
}

class _NotaCreditoDialogState extends ConsumerState<NotaCreditoDialog> {
  final Map<int, double> _cantidadesADevolver = {};
  final _motivoController = TextEditingController();
  bool _isSaving = false;

  final List<String> _motivosFrecuentes = [
    'Devolución por cliente',
    'Producto en mal estado / Avería',
    'Error en facturación / Digitación',
    'Cambio de producto',
    'Descontento con el servicio',
  ];

  @override
  void initState() {
    super.initState();
    for (var det in widget.factura.detalles ?? []) {
      if (det.productoId != null) {
        _cantidadesADevolver[det.productoId!] = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  double get _subtotalADevolver {
    double sub = 0;
    for (var det in widget.factura.detalles ?? []) {
      if (det.productoId == null) continue;
      final cantADevolver = _cantidadesADevolver[det.productoId!] ?? 0;
      if (cantADevolver > 0) {
        final cantOriginal = (det.cantidad ?? 1).toDouble();
        if (cantOriginal > 0) {
          final precioUnitario = det.precio ?? 0.0;
          sub += precioUnitario * cantADevolver;
        }
      }
    }
    return sub;
  }

  double get _itbisADevolver {
    double itb = 0;
    for (var det in widget.factura.detalles ?? []) {
      if (det.productoId == null) continue;
      final cantADevolver = _cantidadesADevolver[det.productoId!] ?? 0;
      if (cantADevolver > 0) {
        final cantOriginal = (det.cantidad ?? 1).toDouble();
        if (cantOriginal > 0) {
          final itbisLinea = det.itbis ?? 0.0;
          itb += (itbisLinea / cantOriginal) * cantADevolver;
        }
      }
    }
    return itb;
  }

  double get _totalADevolver => _subtotalADevolver + _itbisADevolver;

  Future<void> _guardar() async {
    final detallesDevolucion = <Map<String, dynamic>>[];
    for (var det in widget.factura.detalles ?? []) {
      if (det.productoId == null) continue;
      final cant = _cantidadesADevolver[det.productoId!];
      if (cant != null && cant > 0) {
        detallesDevolucion.add({
          'producto_id': det.productoId,
          'cantidad': cant,
        });
      }
    }

    if (detallesDevolucion.isEmpty) {
      showToast(context, 'Debes seleccionar al menos un artículo para devolver.');
      return;
    }

    if (_motivoController.text.trim().isEmpty) {
      showToast(context, 'Por favor especifica el motivo de la devolución.');
      return;
    }

    setState(() => _isSaving = true);

    final token = ref.read(authProvider).token!;
    final notaData = await ref
        .read(facturacionHistorialProvider.notifier)
        .generarNotaCredito(
          token,
          widget.factura.id!,
          detallesDevolucion,
          _motivoController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (notaData != null) {
      Navigator.pop(context); // Cerrar diálogo de generación
      _mostrarDialogoExito(notaData, token);
    } else {
      final error = ref.read(facturacionHistorialProvider).error ?? 'Error desconocido';
      showToast(context, 'Error: $error');
    }
  }

  void _mostrarDialogoExito(Map<String, dynamic> notaData, String token) {
    final ncf = notaData['ncf'] ?? 'N/A';
    final id = notaData['id'];
    final total = double.tryParse((notaData['total'] ?? 0).toString()) ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 44),
            ),
            const SizedBox(height: 12),
            const Text(
              "Nota de Crédito Generada",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "NCF: $ncf",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Monto devuelto: ${FormatterNumber.formatCurrency(total)}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "El inventario y el contra-asiento contable han sido registrados automáticamente.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _imprimirTicketTermico(notaData),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text("Imprimir Ticket", style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulOscuro,
                      side: const BorderSide(color: AppColors.azulOscuro),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirPdf(id, token, directUrl: notaData['pdf_url'] as String?),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text("Ver PDF", style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulOscuro,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _imprimirTicketTermico(Map<String, dynamic> notaData) async {
    try {
      final itemsDevueltos = <ItemFactura>[];
      final detalles = notaData['detalles'] as List<dynamic>? ?? [];

      for (final d in detalles) {
        final cant = double.tryParse((d['cantidad'] ?? 1).toString()) ?? 1.0;
        final prec = double.tryParse((d['precio_unitario'] ?? 0).toString()) ?? 0.0;
        final desc = d['producto']?['nombre'] ?? 'Artículo';
        itemsDevueltos.add(ItemFactura(descripcion: desc, cantidad: cant, precioUnitario: prec));
      }

      final subtotal = double.tryParse((notaData['subtotal'] ?? 0).toString()) ?? 0;
      final itbis = double.tryParse((notaData['itbis'] ?? 0).toString()) ?? 0;
      final total = double.tryParse((notaData['total'] ?? 0).toString()) ?? 0;

      final res = await ThermalPrinterService.instance.imprimirNotaCredito(
        nombreNegocio: 'RESTAURANTE & BAR',
        rncOCedula: '131-00000-0',
        direccion: 'SANTIAGO, REPÚBLICA DOMINICANA',
        ncfNota: (notaData['ncf'] ?? 'N/A').toString(),
        ncfFacturaAfectada: widget.factura.ncf ?? 'N/A',
        numeroFactura: widget.factura.id.toString(),
        fecha: DateTime.now(),
        itemsDevueltos: itemsDevueltos,
        subtotal: subtotal,
        itbis: itbis,
        total: total,
        motivo: (notaData['motivo'] ?? _motivoController.text).toString(),
        cliente: widget.factura.cliente?.nombre ?? 'Consumidor Final',
      );

      if (mounted) {
        showToast(context, res.mensaje);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error al imprimir ticket: $e');
      }
    }
  }

  Future<void> _abrirPdf(dynamic id, String token, {String? directUrl}) async {
    Uri? uri;
    if (directUrl != null && directUrl.isNotEmpty) {
      uri = Uri.parse(directUrl);
    } else {
      final idNum = int.tryParse(id.toString()) ?? 0;
      final urlCifrada = await FacturacionService().getNotaCreditoPdfUrl(token, idNum);
      if (urlCifrada != null && urlCifrada.isNotEmpty) {
        uri = Uri.parse(urlCifrada);
      } else {
        uri = Uri.parse("$hostName/api/notas-credito/$id/pdf?token=$token");
      }
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showToast(context, 'No se pudo abrir el PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalles = widget.factura.detalles ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER COMPACTO ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.assignment_return_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Registrar Nota de Crédito",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Text(
                                "Factura #${widget.factura.id}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "NCF Afectado: ${widget.factura.ncf ?? 'Sin NCF'}  •  Cliente: ${widget.factura.cliente?.nombre ?? 'Consumidor Final'}",
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── CUERPO CON SCROLL ─────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aviso informativo contable & inventario
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.azulOscuro.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.azulOscuro.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.azulOscuro),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Selecciona los artículos a devolver. El stock físico regresará al almacén y el motor contable generará el contra-asiento de reversión.",
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // LISTA DE ARTÍCULOS
                    const Text(
                      "Artículos de la Factura:",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (detalles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            "No se encontraron líneas de detalle para esta factura.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: detalles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final det = detalles[index];
                          final prodId = det.productoId ?? index;
                          final maxCant = (det.cantidad ?? 1).toDouble();
                          final cantActual = _cantidadesADevolver[prodId] ?? 0.0;
                          final precioUnitario = det.precio ?? 0.0;
                          final nombre = det.descripcion ?? det.producto?.nombre ?? 'Producto';

                          final subLinea = precioUnitario * cantActual;
                          final itbisLinea = ((det.itbis ?? 0.0) / maxCant) * cantActual;
                          final totalLinea = subLinea + itbisLinea;

                          final isSelected = cantActual > 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange.shade50.withValues(alpha: 0.3) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.azulOscuro,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          Text(
                                            "Precio: ${FormatterNumber.formatCurrency(precioUnitario)}",
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            "• Facturado: ${maxCant.toStringAsFixed(0)}",
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                          ),
                                          if (isSelected)
                                            Text(
                                              "• A Devolver: ${FormatterNumber.formatCurrency(totalLinea)}",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Selector numérico ultra-compacto
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      color: Colors.red.shade400,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      onPressed: cantActual > 0
                                          ? () => setState(() => _cantidadesADevolver[prodId] = cantActual - 1)
                                          : null,
                                    ),
                                    Container(
                                      width: 32,
                                      alignment: Alignment.center,
                                      child: Text(
                                        cantActual.toStringAsFixed(0),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? AppColors.primary : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      color: Colors.green.shade600,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      onPressed: cantActual < maxCant
                                          ? () => setState(() => _cantidadesADevolver[prodId] = cantActual + 1)
                                          : null,
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => setState(() => _cantidadesADevolver[prodId] = maxCant),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          "Todo",
                                          style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16),

                    // MOTIVO DE DEVOLUCIÓN & CHIPS RÁPIDOS
                    const Text(
                      "Motivo de la Devolución *",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _motivosFrecuentes.map((m) {
                        final isSel = _motivoController.text == m;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _motivoController.text = m;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.azulOscuro : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSel ? AppColors.azulOscuro : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              m,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _motivoController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 11.5),
                      decoration: InputDecoration(
                        hintText: "Escribe o complementa el motivo de la devolución...",
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CAJA DE TOTALES A REEMBOLSAR
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Subtotal a Revertir:",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                              Text(
                                FormatterNumber.formatCurrency(_subtotalADevolver),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "ITBIS (18%) a Revertir:",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                              Text(
                                FormatterNumber.formatCurrency(_itbisADevolver),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "TOTAL A REEMBOLSAR AL CLIENTE:",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  FormatterNumber.formatCurrency(_totalADevolver),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── FOOTER BOTONES DE ACCIÓN ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardar,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.receipt_long, size: 16),
                    label: Text(
                      _isSaving ? "Registrando..." : "Registrar Nota de Crédito",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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

