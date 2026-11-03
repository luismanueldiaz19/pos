import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/buscador_proveedor_dialog.dart';
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
    Proveedor? provSeleccionado;
    if (selectedProveedorId != null) {
      final match = proveedores.where((p) => p.id == selectedProveedorId).toList();
      if (match.isNotEmpty) {
        provSeleccionado = match.first;
      }
    }

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
              Icon(Icons.badge_outlined, size: 16, color: AppColors.azulOscuro),
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

          // Toggle Tipo Beneficiario
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  selected: esGastoMenor,
                  label: '⚡ Gasto Menor / Informal',
                  icon: Icons.bolt,
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

          // Nombre beneficiario o Selector con Buscador de proveedores
          if (esGastoMenor)
            CustomTextField(
              controller: beneficiarioCtrl,
              label: 'Nombre del Establecimiento / Beneficiario',
              hintText: 'Ej: Estación Shell, Ferretería El Sol, Taxi...',
              prefixIcon: Icons.storefront_outlined,
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Proveedor Formal Registrado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${proveedores.length} proveedores disponibles',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Selector táctil con Buscador Virtualizado (Soporta 5,000+ proveedores)
            InkWell(
              onTap: () async {
                final prov = await BuscadorProveedorDialog.show(
                  context,
                  proveedores: proveedores,
                  selectedId: selectedProveedorId,
                  title: 'Seleccionar Proveedor del Gasto',
                );
                if (prov != null) {
                  onProveedorSelected(prov.id);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: provSeleccionado != null
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: provSeleccionado != null
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provSeleccionado != null
                            ? '${provSeleccionado.nombre} ${provSeleccionado.rnc != null ? "(${provSeleccionado.rnc})" : ""}'
                            : 'Buscar o seleccionar proveedor...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: provSeleccionado != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: provSeleccionado != null
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (provSeleccionado != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Limpiar selección',
                        onPressed: () => onProveedorSelected(null),
                      )
                    else
                      const Icon(Icons.search, size: 16, color: Colors.grey),
                  ],
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
                flex: 3,
                child: CustomTextField(
                  controller: ncfCtrl,
                  label: 'NCF (Opcional)',
                  hintText: 'B01... / B13...',
                  prefixIcon: Icons.receipt_long_outlined,
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
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) onFechaSelected(picked);
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
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(fechaGasto),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
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
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.primary : Colors.grey.shade700,
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
