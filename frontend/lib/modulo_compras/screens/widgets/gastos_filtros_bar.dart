import 'package:flutter/material.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';

class GastosFiltrosBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final String selectedTipoCompra;
  final ValueChanged<String> onTipoCompraChanged;
  final VoidCallback onSelectRangoFechas;
  final String? rangoFechasLabel;
  final VoidCallback onLimpiarFechas;
  final VoidCallback onQuickHoy;
  final VoidCallback onQuickEsteMes;
  final VoidCallback onLimpiarFiltros;

  const GastosFiltrosBar({
    super.key,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.selectedTipoCompra,
    required this.onTipoCompraChanged,
    required this.onSelectRangoFechas,
    required this.rangoFechasLabel,
    required this.onLimpiarFechas,
    required this.onQuickHoy,
    required this.onQuickEsteMes,
    required this.onLimpiarFiltros,
  });

  @override
  Widget build(BuildContext context) {
    final tieneRangoActivo = rangoFechasLabel != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Buscador de texto compacto
              Expanded(
                flex: 4,
                child: CustomTextField(
                  controller: searchCtrl,
                  label: '',
                  hintText: 'Buscar factura, NCF, concepto o proveedor...',
                  prefixIcon: Icons.search,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),

              // Botón Selector de Rango de Fechas
              InkWell(
                onTap: onSelectRangoFechas,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: tieneRangoActivo
                        ? const Color(0xFFEFF6FF)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: tieneRangoActivo
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 15,
                        color: tieneRangoActivo
                            ? AppColors.primary
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rangoFechasLabel ?? 'Rango de Fechas',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: tieneRangoActivo
                              ? AppColors.primary
                              : Colors.grey.shade800,
                        ),
                      ),
                      if (tieneRangoActivo) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onLimpiarFechas,
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Botón Limpiar Todo
              OutlinedButton.icon(
                onPressed: onLimpiarFiltros,
                icon: const Icon(Icons.clear_all, size: 14),
                label: const Text('Limpiar', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Fila de accesos rápidos y condiciones
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Condición:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              _buildFilterChip('todos', 'Todos', selectedTipoCompra == 'todos', onTipoCompraChanged),
              _buildFilterChip('CONTADO', '💵 Al Contado', selectedTipoCompra == 'CONTADO', onTipoCompraChanged),
              _buildFilterChip('CREDITO', '📅 A Crédito', selectedTipoCompra == 'CREDITO', onTipoCompraChanged),
              const SizedBox(width: 8),
              Container(width: 1, height: 16, color: Colors.grey.shade300),
              const SizedBox(width: 8),
              Text(
                'Atajos:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              _buildQuickActionChip('Hoy', onQuickHoy),
              _buildQuickActionChip('Este Mes', onQuickEsteMes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    bool isSelected,
    ValueChanged<String> onSelected,
  ) {
    return InkWell(
      onTap: () => onSelected(key),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.azulOscuro : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.azulOscuro : Colors.grey.shade300,
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
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
