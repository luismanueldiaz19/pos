import 'package:flutter/material.dart';
import '../../../model/factura.dart';
import '../../../palletes/app_colors.dart';
import '../../../utils/helpers.dart';

class FacturaListItem extends StatelessWidget {
  final Factura factura;
  final bool isSelected;
  final VoidCallback onTap;

  const FacturaListItem({
    super.key,
    required this.factura,
    required this.isSelected,
    required this.onTap,
  });

  Color _getStatusColor() {
    final estado = factura.estado?.toLowerCase() ?? '';
    if (estado == 'pagada') {
      return Colors.green.shade600;
    } else if (estado == 'pendiente') {
      return Colors.orange.shade700;
    } else if (estado == 'anulada') {
      return Colors.red.shade600;
    }
    return AppColors.azulOscuro;
  }

  Color _getMetodoColor(String metodo) {
    final m = metodo.toUpperCase();
    if (m.contains('TARJETA')) return Colors.indigo.shade600;
    if (m.contains('TRANSFERENCIA')) return Colors.deepOrange.shade700;
    if (m.contains('PENDIENTE')) return Colors.orange.shade800;
    return Colors.green.shade700;
  }

  IconData _getMetodoIcon(String metodo) {
    final m = metodo.toUpperCase();
    if (m.contains('TARJETA')) return Icons.credit_card_rounded;
    if (m.contains('TRANSFERENCIA')) return Icons.account_balance_rounded;
    if (m.contains('PENDIENTE')) return Icons.pending_actions_rounded;
    return Icons.payments_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final total = double.tryParse(factura.total ?? '0') ?? 0;
    final estado = (factura.estado ?? 'Emitida').toUpperCase();
    final ncf = factura.ncf?.isNotEmpty == true ? factura.ncf! : 'Sin NCF';
    final cliente = factura.cliente?.nombre ?? 'Consumidor Final';
    final fechaStr = factura.fechaEmision != null
        ? FormatterNumber.formatFechaHora(factura.fechaEmision!)
        : (factura.createdAt != null
            ? FormatterNumber.formatFechaHora(factura.createdAt!)
            : 'N/A');

    final metodoNombre = factura.metodoPagoNombre;
    final metodoColor = _getMetodoColor(metodoNombre);
    final metodoIcon = _getMetodoIcon(metodoNombre);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? statusColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? statusColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Franja de color indicadora según estado
                Container(
                  width: 5,
                  color: statusColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        // Avatar identificador con ID
                        CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          radius: 18,
                          child: Text(
                            "#${factura.id}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Información de la factura
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Factura #${factura.id} • $ncf",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: AppColors.azulOscuro,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: statusColor.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      estado,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      cliente,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: metodoColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: metodoColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(metodoIcon, size: 10, color: metodoColor),
                                        const SizedBox(width: 3),
                                        Text(
                                          metodoNombre,
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: metodoColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      fechaStr,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    FormatterNumber.formatCurrency(total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
