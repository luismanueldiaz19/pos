import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../facturacion/models/metodo_pago.dart';

class GastoCondicionCard extends StatelessWidget {
  final String tipoCompra;
  final ValueChanged<String> onTipoCompraChanged;
  final List<MetodoPago> metodos;
  final int? selectedMetodoPagoId;
  final ValueChanged<int?> onMetodoPagoSelected;
  final TextEditingController referenciaPagoCtrl;
  final DateTime fechaVencimiento;
  final ValueChanged<DateTime> onFechaVencimientoSelected;

  const GastoCondicionCard({
    super.key,
    required this.tipoCompra,
    required this.onTipoCompraChanged,
    required this.metodos,
    required this.selectedMetodoPagoId,
    required this.onMetodoPagoSelected,
    required this.referenciaPagoCtrl,
    required this.fechaVencimiento,
    required this.onFechaVencimientoSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_outlined, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Text(
                '4. Condición y Origen de Fondos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          Row(
            children: [
              Expanded(
                child: _buildCondicionButton(
                  selected: tipoCompra == 'CONTADO',
                  label: '💵 AL CONTADO (Salida Inmediata)',
                  icon: Icons.money_off,
                  onTap: () => onTipoCompraChanged('CONTADO'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCondicionButton(
                  selected: tipoCompra == 'CREDITO',
                  label: '📅 A CRÉDITO (Genera CxP)',
                  icon: Icons.calendar_month,
                  onTap: () => onTipoCompraChanged('CREDITO'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (tipoCompra == 'CONTADO') ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Método de Pago',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedMetodoPagoId,
                            hint: const Text('Método de Pago...', style: TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                            items: metodos.map((m) {
                              return DropdownMenuItem<int>(
                                value: m.id,
                                child: Text(m.nombre, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: onMetodoPagoSelected,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: CustomTextField(
                    controller: referenciaPagoCtrl,
                    label: 'Ref. Pago (Cheque/Transf/Caja)',
                    hintText: 'Opcional',
                    prefixIcon: Icons.receipt,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Crédito: Plazo y vencimiento
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha de Vencimiento de la Deuda',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaVencimiento,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      onFechaVencimientoSelected(picked);
                    }
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(fechaVencimiento),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const Icon(Icons.event_available, size: 16, color: Color(0xFFD97706)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ℹ️ Se registrará en Cuentas por Pagar (CxP Proveedores - 2.1.01) para liquidarse con posterioridad.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCondicionButton({
    required bool selected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.azulOscuro : Colors.grey.shade300,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.azulOscuro : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.azulOscuro : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

