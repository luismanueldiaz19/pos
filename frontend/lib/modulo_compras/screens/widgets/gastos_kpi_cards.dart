import 'package:flutter/material.dart';
import '../../../../utils/helpers.dart';
import '../../providers/gastos_provider.dart';

/// Tarjetas de resumen KPI compactas para Gastos Operativos.
/// Aplica rigurosamente la skill `flutter-small-widgets`:
/// - Altura compacta (38-42px).
/// - Tipografía reducida (10-13px).
/// - Espaciados reducidos (padding 6-8px).
class GastosKpiCards extends StatelessWidget {
  final TotalesGastos totales;

  const GastosKpiCards({super.key, required this.totales});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final cardWidth = isWide
            ? (constraints.maxWidth - 24) / 4
            : (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildSmallKpi(
              title: 'TOTAL GASTOS',
              value: FormatterNumber.formatCurrency(totales.totalGastos),
              extra: '${totales.cantidad} reg',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF1E293B),
              bgColor: const Color(0xFFF8FAFC),
              borderColor: const Color(0xFFCBD5E1),
              width: cardWidth,
            ),
            _buildSmallKpi(
              title: 'AL CONTADO',
              value: FormatterNumber.formatCurrency(totales.totalContado),
              icon: Icons.payments_outlined,
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              width: cardWidth,
            ),
            _buildSmallKpi(
              title: 'A CRÉDITO (CxP)',
              value: FormatterNumber.formatCurrency(totales.totalCredito),
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              width: cardWidth,
            ),
            _buildSmallKpi(
              title: 'ITBIS FISCAL',
              value: FormatterNumber.formatCurrency(totales.totalItbis),
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallKpi({
    required String title,
    required String value,
    String? extra,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (extra != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          extra,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
