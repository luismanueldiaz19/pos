import 'package:flutter/material.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../model/catalogo_cuenta_model.dart';
import '../../../../widgets/buscador_cuenta_gasto_dialog.dart';

class GastoClasificacionCard extends StatelessWidget {
  final List<CatalogoCuentaModel> cuentas;
  final int? selectedCuentaId;
  final ValueChanged<int?> onCuentaSelected;
  final TextEditingController conceptoCtrl;
  final String selectedCategoriaChip;
  final ValueChanged<String> onCategoriaChipChanged;

  const GastoClasificacionCard({
    super.key,
    required this.cuentas,
    required this.selectedCuentaId,
    required this.onCuentaSelected,
    required this.conceptoCtrl,
    required this.selectedCategoriaChip,
    required this.onCategoriaChipChanged,
  });

  @override
  Widget build(BuildContext context) {
    CatalogoCuentaModel? cuentaSeleccionada;
    if (selectedCuentaId != null) {
      final match = cuentas.where((c) => c.id == selectedCuentaId).toList();
      if (match.isNotEmpty) {
        cuentaSeleccionada = match.first;
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
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '1. Clasificación Contable (Clase 6)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final cuenta = await BuscadorCuentaGastoDialog.show(
                    context,
                    cuentas: cuentas,
                    selectedId: selectedCuentaId,
                  );
                  if (cuenta != null) {
                    onCuentaSelected(cuenta.id);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 13, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text(
                        'Nueva Cuenta',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Chips de categorías de gasto
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('TODOS', 'Todos'),
                _buildChip('SERVICIOS', '⚡ Servicios'),
                _buildChip('COMBUSTIBLE', '🚗 Combustible'),
                _buildChip('MANTENIMIENTO', '🔧 Mantenimiento'),
                _buildChip('LIMPIEZA', '🧹 Limpieza'),
                _buildChip('ALQUILER', '🏢 Alquiler'),
                _buildChip('PERSONAL', '👥 Personal'),
                _buildChip('OTROS', '💼 Otros'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Selector de cuenta con Buscador Rápido (soporta 200+ cuentas fluidas)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cuenta Contable de Gasto',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${cuentas.length} cuentas disponibles',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Selector táctil con buscador
          InkWell(
            onTap: () async {
              final cuenta = await BuscadorCuentaGastoDialog.show(
                context,
                cuentas: cuentas,
                selectedId: selectedCuentaId,
              );
              if (cuenta != null) {
                onCuentaSelected(cuenta.id);
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
                  color: cuentaSeleccionada != null
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 16,
                    color: cuentaSeleccionada != null
                        ? AppColors.primary
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  if (cuentaSeleccionada != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cuentaSeleccionada.codigo,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      cuentaSeleccionada != null
                          ? cuentaSeleccionada.nombre
                          : 'Buscar cuenta de gasto (ej: luz, combustible, 6.2)...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: cuentaSeleccionada != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: cuentaSeleccionada != null
                            ? const Color(0xFF1E293B)
                            : Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (cuentaSeleccionada != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Limpiar selección',
                      onPressed: () => onCuentaSelected(null),
                    )
                  else
                    const Icon(Icons.search, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Concepto / Detalle usando CustomTextField
          CustomTextField(
            controller: conceptoCtrl,
            label: 'Concepto / Justificación del Gasto (Opcional)',
            hintText: 'Ej: Combustible para delivery, Factura de luz agosto...',
            prefixIcon: Icons.edit_note_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label) {
    final isSelected = selectedCategoriaChip == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onCategoriaChipChanged(key),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}
