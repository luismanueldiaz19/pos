import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../palletes/app_colors.dart';
import '../../../../utils/helpers.dart';
import '../../models/compra.dart';

class GastoDetalleDialog extends StatelessWidget {
  final Compra gasto;

  const GastoDetalleDialog({super.key, required this.gasto});

  @override
  Widget build(BuildContext context) {
    final primerDetalle = gasto.detalles.isNotEmpty
        ? gasto.detalles.first
        : null;
    final cuentaNombre = primerDetalle?.cuentaContable != null
        ? '${primerDetalle!.cuentaContable!.codigo} - ${primerDetalle.cuentaContable!.nombre}'
        : (primerDetalle?.descripcion ?? 'Gasto Operativo');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gasto.numeroFacturaProveedor,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(gasto.fechaCompra),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Badges
              Row(
                children: [
                  _buildBadge(
                    label: gasto.tipoCompra == 'CONTADO'
                        ? 'CONTADO (PAGADO)'
                        : 'A CRÉDITO',
                    color: gasto.tipoCompra == 'CONTADO'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                    bgColor: gasto.tipoCompra == 'CONTADO'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                  ),
                  const SizedBox(width: 8),
                  if (gasto.ncf != null && gasto.ncf!.isNotEmpty)
                    _buildBadge(
                      label: 'NCF: ${gasto.ncf}',
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Datos informativos
              _buildInfoRow(
                'Cuenta de Gasto (Clase 6)',
                cuentaNombre,
                isHighlight: true,
              ),
              _buildInfoRow(
                'Proveedor / Beneficiario',
                gasto.proveedor?.nombre ?? 'Gasto Ocasional',
              ),
              if (primerDetalle?.descripcion != null)
                _buildInfoRow(
                  'Concepto / Detalle',
                  primerDetalle!.descripcion!,
                ),
              if (gasto.notas != null && gasto.notas!.isNotEmpty)
                _buildInfoRow('Notas / Justificación', gasto.notas!),

              const SizedBox(height: 12),
              // Desglose de importes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildMontoRow('Subtotal Base', gasto.subtotal),
                    const SizedBox(height: 4),
                    _buildMontoRow('ITBIS (18%)', gasto.impuestos),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL REGISTRADO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          FormatterNumber.formatCurrency(gasto.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Botón cerrar
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulOscuro,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Cerrar', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight
                    ? AppColors.primary
                    : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMontoRow(String label, double monto) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        Text(
          FormatterNumber.formatCurrency(monto),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
