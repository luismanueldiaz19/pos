import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../utils/helpers.dart';
import '../../models/compra.dart';
import 'gasto_detalle_dialog.dart';

class GastoItemCard extends StatelessWidget {
  final Compra gasto;

  const GastoItemCard({super.key, required this.gasto});

  @override
  Widget build(BuildContext context) {
    final primerDetalle = gasto.detalles.isNotEmpty
        ? gasto.detalles.first
        : null;
    final cuentaNombre = primerDetalle?.cuentaContable != null
        ? '${primerDetalle!.cuentaContable!.codigo} - ${primerDetalle.cuentaContable!.nombre}'
        : (primerDetalle?.descripcion ?? 'Gasto General');

    final esContado = gasto.tipoCompra.toUpperCase() == 'CONTADO';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono según tipo de gasto
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: esContado
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: esContado
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Icon(
              esContado
                  ? Icons.payments_outlined
                  : Icons.calendar_month_outlined,
              size: 18,
              color: esContado
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 10),

          // Información del comprobante y beneficiario
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      gasto.numeroFacturaProveedor,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (gasto.ncf != null && gasto.ncf!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          gasto.ncf!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  gasto.proveedor?.nombre ?? 'Beneficiario Ocasional',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (primerDetalle?.descripcion != null)
                  Text(
                    primerDetalle!.descripcion!,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Clasificación contable (Clase 6)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    cuentaNombre,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd/MM/yyyy').format(gasto.fechaCompra),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Condición de pago
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: esContado
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    esContado ? 'CONTADO' : 'CRÉDITO (CxP)',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: esContado
                          ? const Color(0xFF166534)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
                if (!esContado && gasto.fechaVencimiento != null)
                  Text(
                    'Vence: ${DateFormat('dd/MM/yyyy').format(gasto.fechaVencimiento!)}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFD97706),
                    ),
                  ),
              ],
            ),
          ),

          // Importes
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FormatterNumber.formatCurrency(gasto.total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (gasto.impuestos > 0)
                Text(
                  'ITBIS: ${FormatterNumber.formatCurrency(gasto.impuestos)}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // Botón ver detalle
          IconButton(
            icon: const Icon(
              Icons.remove_red_eye_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            tooltip: 'Ver detalle del gasto y asiento contable',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => GastoDetalleDialog(gasto: gasto),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
