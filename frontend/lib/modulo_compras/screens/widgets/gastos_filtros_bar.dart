import 'package:flutter/material.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';

class GastosFiltrosBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final String selectedTipoCompra;
  final ValueChanged<String> onTipoCompraChanged;
  final VoidCallback onSelectFechaDesde;
  final VoidCallback onSelectFechaHasta;
  final String? fechaDesdeLabel;
  final String? fechaHastaLabel;
  final VoidCallback onLimpiarFiltros;

  const GastosFiltrosBar({
    super.key,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.selectedTipoCompra,
    required this.onTipoCompraChanged,
    required this.onSelectFechaDesde,
    required this.onSelectFechaHasta,
    required this.fechaDesdeLabel,
    required this.fechaHastaLabel,
    required this.onLimpiarFiltros,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Buscador usando CustomTextField
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: searchCtrl,
                  label: '',
                  hintText: 'Buscar por factura, NCF, concepto o proveedor...',
                  prefixIcon: Icons.search,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),

              // Botón Fecha Desde
              _buildDateButton(
                label: fechaDesdeLabel ?? 'Desde',
                onTap: onSelectFechaDesde,
              ),
              const SizedBox(width: 6),

              // Botón Fecha Hasta
              _buildDateButton(
                label: fechaHastaLabel ?? 'Hasta',
                onTap: onSelectFechaHasta,
              ),
              const SizedBox(width: 8),

              // Botón Limpiar
              OutlinedButton.icon(
                onPressed: onLimpiarFiltros,
                icon: const Icon(Icons.clear_all, size: 14),
                label: const Text('Limpiar', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Chips de Condición de Pago
          Row(
            children: [
              Text(
                'Condición:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              _buildTipoChip('todos', 'Todos'),
              const SizedBox(width: 6),
              _buildTipoChip('CONTADO', '💵 Al Contado'),
              const SizedBox(width: 6),
              _buildTipoChip('CREDITO', '📅 A Crédito'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoChip(String key, String label) {
    final isSelected = selectedTipoCompra == key;
    return InkWell(
      onTap: () => onTipoCompraChanged(key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}

