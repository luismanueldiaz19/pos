import 'package:flutter/material.dart';
import '../../../../utils/helpers.dart';
import '../../../../model/catalogo_cuenta_model.dart';
import '../../../../facturacion/models/metodo_pago.dart';

class GastoMotorContableCard extends StatelessWidget {
  final CatalogoCuentaModel? cuentaGasto;
  final String tipoCompra;
  final MetodoPago? metodoPago;
  final double subtotal;
  final double itbis;
  final double total;

  const GastoMotorContableCard({
    super.key,
    required this.cuentaGasto,
    required this.tipoCompra,
    required this.metodoPago,
    required this.subtotal,
    required this.itbis,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final cuentaGastoNombre = cuentaGasto != null
        ? '${cuentaGasto!.codigo} ${cuentaGasto!.nombre}'
        : '6.X [Seleccione cuenta de gasto]';

    final cuentaHaberNombre = tipoCompra == 'CONTADO'
        ? (metodoPago != null ? '1.1.01 ${metodoPago!.nombre} (Caja/Bancos)' : '1.1.01.01 CAJA')
        : '2.1.01 CUENTAS POR PAGAR PROVEEDORES';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: Color(0xFF0F172A), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Asiento Contable Automático (Partida Doble)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Cuadrado ✓',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Línea 1: DÉBITO Gasto
          _buildAsientoLine(
            tipo: 'DEBE',
            cuenta: cuentaGastoNombre,
            monto: subtotal,
            color: const Color(0xFF0284C7),
          ),

          // Línea 2: DÉBITO ITBIS (si aplica)
          if (itbis > 0)
            _buildAsientoLine(
              tipo: 'DEBE',
              cuenta: '2.1.02 ITBIS POR PAGAR (Deducible compras)',
              monto: itbis,
              color: const Color(0xFF0284C7),
            ),

          // Línea 3: CRÉDITO Caja/Banco o CxP
          _buildAsientoLine(
            tipo: 'HABER',
            cuenta: cuentaHaberNombre,
            monto: total,
            color: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildAsientoLine({
    required String tipo,
    required String cuenta,
    required double monto,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: tipo == 'DEBE' ? const Color(0xFFE0F2FE) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tipo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: tipo == 'DEBE' ? const Color(0xFF0369A1) : const Color(0xFFB45309),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cuenta,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            FormatterNumber.formatCurrency(monto),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

