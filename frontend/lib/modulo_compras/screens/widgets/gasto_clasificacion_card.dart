import 'package:flutter/material.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../model/catalogo_cuenta_model.dart';

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
              Icon(Icons.account_tree_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                '1. Clasificación Contable (Clase 6)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
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

          // Selector de cuenta
          Text(
            'Cuenta Contable de Gasto',
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
              border: Border.all(
                color: selectedCuentaId == null
                    ? Colors.grey.shade200
                    : AppColors.azulOscuro.withValues(alpha: 0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: selectedCuentaId,
                hint: const Text(
                  'Seleccione cuenta contable de gasto...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                items: cuentas.map((c) {
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(
                      '${c.codigo} - ${c.nombre}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onCuentaSelected,
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

