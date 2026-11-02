import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../models/proveedor.dart';

class GastoBeneficiarioCard extends StatelessWidget {
  final bool esGastoMenor;
  final ValueChanged<bool> onTipoBeneficiarioChanged;
  final TextEditingController beneficiarioCtrl;
  final List<Proveedor> proveedores;
  final int? selectedProveedorId;
  final ValueChanged<int?> onProveedorSelected;
  final TextEditingController numFacturaCtrl;
  final VoidCallback onAutoGenerarRecibo;
  final TextEditingController ncfCtrl;
  final DateTime fechaGasto;
  final ValueChanged<DateTime> onFechaSelected;

  const GastoBeneficiarioCard({
    super.key,
    required this.esGastoMenor,
    required this.onTipoBeneficiarioChanged,
    required this.beneficiarioCtrl,
    required this.proveedores,
    required this.selectedProveedorId,
    required this.onProveedorSelected,
    required this.numFacturaCtrl,
    required this.onAutoGenerarRecibo,
    required this.ncfCtrl,
    required this.fechaGasto,
    required this.onFechaSelected,
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
              Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF0284C7)),
              SizedBox(width: 6),
              Text(
                '2. Beneficiario y Comprobante',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Selector de modalidad: Gasto Menor vs Proveedor Formal
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  selected: esGastoMenor,
                  label: '⚡ Gasto Menor / Informal',
                  icon: Icons.flash_on_outlined,
                  onTap: () => onTipoBeneficiarioChanged(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOptionButton(
                  selected: !esGastoMenor,
                  label: '🏢 Proveedor Registrado',
                  icon: Icons.business_outlined,
                  onTap: () => onTipoBeneficiarioChanged(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nombre beneficiario o dropdown de proveedores
          if (esGastoMenor)
            CustomTextField(
              controller: beneficiarioCtrl,
              label: 'Nombre del Establecimiento / Beneficiario',
              hintText: 'Ej: Estación Shell, Ferretería El Sol, Taxi...',
              prefixIcon: Icons.storefront_outlined,
            )
          else ...[
            Text(
              'Proveedor Formal Registrado',
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
                  value: selectedProveedorId,
                  hint: const Text(
                    'Seleccione proveedor formal...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  items: proveedores.map((p) {
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(
                        '${p.nombre} ${p.rnc != null ? "(${p.rnc})" : ""}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: onProveedorSelected,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // No. Factura / Recibo + NCF + Fecha
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: numFacturaCtrl,
                  label: 'No. Factura / Recibo',
                  hintText: 'REC-20261102-001',
                  prefixIcon: Icons.tag,
                  suffixWidget: IconButton(
                    icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                    tooltip: 'Auto-generar número de recibo',
                    onPressed: onAutoGenerarRecibo,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: ncfCtrl,
                  label: 'NCF (Opcional)',
                  hintText: 'B01... / B13...',
                  prefixIcon: Icons.confirmation_number_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha del Gasto',
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
                          initialDate: fechaGasto,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          onFechaSelected(picked);
                        }
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(fechaGasto),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
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
            const SizedBox(width: 4),
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
