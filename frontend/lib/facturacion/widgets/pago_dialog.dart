import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../models/metodo_pago.dart';
import '../providers/metodo_pago_provider.dart';

class PagoDialog extends ConsumerStatefulWidget {
  final double total;
  final bool initialImprimir;

  const PagoDialog({
    super.key,
    required this.total,
    this.initialImprimir = true,
  });

  @override
  ConsumerState<PagoDialog> createState() => _PagoDialogState();
}

class _PagoDialogState extends ConsumerState<PagoDialog> {
  final TextEditingController _montoController = TextEditingController();
  MetodoPago? _metodoPagoSeleccionado;
  double _montoRecibido = 0;
  late bool _imprimirFactura;
  bool _hasFinalized = false;

  bool get _puedeFinalizar =>
      !((_montoRecibido < widget.total &&
              _metodoPagoSeleccionado?.tipo == 'efectivo') ||
          _metodoPagoSeleccionado == null);

  void _finalizar() {
    if (_hasFinalized) return;
    if (!_puedeFinalizar) return;
    _hasFinalized = true;
    Navigator.pop(context, {
      'monto_pagado': widget.total,
      'monto_recibido': _montoRecibido,
      'devuelta': _devuelta,
      'metodo_pago': _metodoPagoSeleccionado?.tipo,
      'metodo_pago_id': _metodoPagoSeleccionado?.id,
      'imprimir_factura': _imprimirFactura,
    });
  }

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.total.toStringAsFixed(2);
    _montoRecibido = widget.total;
    _imprimirFactura = widget.initialImprimir;

    final metodosExistentes = ref.read(metodoPagoProvider).metodos;
    if (metodosExistentes.isNotEmpty) {
      _metodoPagoSeleccionado = metodosExistentes.first;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(metodoPagoProvider).fetchMetodosActivos().then((_) {
        final prov = ref.read(metodoPagoProvider);
        if (prov.metodos.isNotEmpty && _metodoPagoSeleccionado == null) {
          setState(() {
            _metodoPagoSeleccionado = prov.metodos.first;
          });
        }
      });
    });
  }

  double get _devuelta =>
      (_montoRecibido - widget.total) > 0 ? _montoRecibido - widget.total : 0;

  @override
  Widget build(BuildContext context) {
    final metodoProv = ref.watch(metodoPagoProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _finalizar,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _finalizar,
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Procesar Pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Resumen de Total
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL A COBRAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '\$${widget.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'MÉTODO DE PAGO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                if (metodoProv.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (metodoProv.metodos.isEmpty)
                  const Text(
                    'No hay métodos de pago configurados',
                    style: TextStyle(color: Colors.red),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metodoProv.metodos.map((metodo) {
                      IconData icon = Icons.payments_rounded;
                      if (metodo.tipo == 'tarjeta')
                        icon = Icons.credit_card_rounded;
                      if (metodo.tipo == 'transferencia')
                        icon = Icons.account_balance_rounded;

                      return SizedBox(
                        width: 105,
                        child: _buildMetodoBtn(metodo, icon, metodo.nombre),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 12),

                const Text(
                  'MONTO RECIBIDO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _montoController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: AppColors.light,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _montoRecibido = double.tryParse(v) ?? 0;
                    });
                  },
                  onSubmitted: (_) => _finalizar(),
                ),

                if (_metodoPagoSeleccionado?.tipo == 'efectivo') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _montoRecibido >= widget.total
                          ? Colors.green.withOpacity(0.05)
                          : Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CAMBIO (DEVUELTA)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _montoRecibido >= widget.total
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        Text(
                          '\$${_devuelta.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _montoRecibido >= widget.total
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Switch Imprimir
                Row(
                  children: [
                    Icon(
                      Icons.print_rounded,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Imprimir Ticket',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 30, // Reduce Switch vertical height
                      child: Switch(
                        value: _imprimirFactura,
                        onChanged: (v) => setState(() => _imprimirFactura = v),
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _puedeFinalizar ? _finalizar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'FINALIZAR VENTA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetodoBtn(MetodoPago metodo, IconData icon, String label) {
    bool isSelected = _metodoPagoSeleccionado?.id == metodo.id;
    return InkWell(
      onTap: () => setState(() => _metodoPagoSeleccionado = metodo),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.light,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade100,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
