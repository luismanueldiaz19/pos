import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/helpers.dart';
import '../../../../widgets/custom_text_field.dart';

class GastoImporteCard extends StatelessWidget {
  final TextEditingController subtotalCtrl;
  final String itbisModo;
  final ValueChanged<String> onItbisModoChanged;
  final TextEditingController itbisManualCtrl;
  final double subtotal;
  final double itbis;
  final double total;
  final VoidCallback onValuesChanged;

  const GastoImporteCard({
    super.key,
    required this.subtotalCtrl,
    required this.itbisModo,
    required this.onItbisModoChanged,
    required this.itbisManualCtrl,
    required this.subtotal,
    required this.itbis,
    required this.total,
    required this.onValuesChanged,
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
              Icon(Icons.attach_money_outlined, size: 16, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text(
                '3. Importe y Fiscalidad (ITBIS)',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monto Base (Subtotal) con CustomTextField
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: subtotalCtrl,
                  label: 'Monto Base (Subtotal RD\$)',
                  hintText: '0.00',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  onChanged: (_) => onValuesChanged(),
                ),
              ),
              const SizedBox(width: 10),

              // Selector de ITBIS
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tratamiento de ITBIS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildItbisChip('EXENTO', 'Exento (0%)'),
                        const SizedBox(width: 4),
                        _buildItbisChip('ITBIS18', '18% ITBIS'),
                        const SizedBox(width: 4),
                        _buildItbisChip('MANUAL', 'Manual'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (itbisModo == 'MANUAL') ...[
            const SizedBox(height: 8),
            CustomTextField(
              controller: itbisManualCtrl,
              label: 'Monto Exacto de ITBIS (RD\$)',
              hintText: '0.00',
              prefixIcon: Icons.percent,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (_) => onValuesChanged(),
            ),
          ],
          const SizedBox(height: 10),

          // Resumen de Montos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subtotal: ${FormatterNumber.formatCurrency(subtotal)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                    Text(
                      'ITBIS: ${FormatterNumber.formatCurrency(itbis)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: itbis > 0 ? const Color(0xFF2563EB) : Colors.grey.shade600,
                        fontWeight: itbis > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TOTAL GASTO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(
                      FormatterNumber.formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItbisChip(String modo, String label) {
    final isSelected = itbisModo == modo;
    return Expanded(
      child: InkWell(
        onTap: () => onItbisModoChanged(modo),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

