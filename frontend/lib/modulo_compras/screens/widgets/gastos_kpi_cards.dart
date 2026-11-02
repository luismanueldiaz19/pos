import 'package:flutter/material.dart';
import '../../../../utils/helpers.dart';
import '../../providers/gastos_provider.dart';

class GastosKpiCards extends StatelessWidget {
  final TotalesGastos totales;

  const GastosKpiCards({super.key, required this.totales});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 750;
        final cardWidth = isWide
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildKpiCard(
              title: 'TOTAL GASTOS',
              value: FormatterNumber.formatCurrency(totales.totalGastos),
              subtitle: '${totales.cantidad} registros',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF0F172A),
              bgColor: const Color(0xFFF8FAFC),
              borderColor: const Color(0xFFCBD5E1),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'AL CONTADO (PAGADOS)',
              value: FormatterNumber.formatCurrency(totales.totalContado),
              subtitle: 'Salida de caja / bancos',
              icon: Icons.payments_outlined,
              iconColor: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'A CRÉDITO (CxP)',
              value: FormatterNumber.formatCurrency(totales.totalCredito),
              subtitle: 'Pasivos / Por pagar',
              icon: Icons.calendar_month_outlined,
              iconColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'ITBIS FISCAL ADELANTADO',
              value: FormatterNumber.formatCurrency(totales.totalItbis),
              subtitle: 'Deducible de compras',
              icon: Icons.receipt_long_outlined,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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
