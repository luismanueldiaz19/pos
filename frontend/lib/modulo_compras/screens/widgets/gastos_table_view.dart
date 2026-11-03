import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';

import '../../../../palletes/app_colors.dart';
import '../../../../utils/helpers.dart';
import '../../models/compra.dart';
import '../../providers/gastos_provider.dart';
import 'gasto_detalle_dialog.dart';

/// Vista en Tabla con Paginación para Gastos Operativos.
/// Aplica rigurosamente:
/// - `flutter-small-widgets`: Densidad visual alta, alturas de fila 42px, fuentes 10-12px.
/// - `flutter-clean-reusable-ui`: Componente modular, SRP, sin lógica acoplada.
class GastosTableView extends StatelessWidget {
  final GastosState state;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPerPageChanged;

  const GastosTableView({
    super.key,
    required this.state,
    required this.onPageChanged,
    required this.onPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tabla con scroll horizontal si es necesario
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: DataTable2(
                columnSpacing: 10,
                horizontalMargin: 12,
                minWidth: 920,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingRowHeight: 36,
                dataRowHeight: 44,
                dividerThickness: 0.5,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
                columns: const [
                  DataColumn2(
                    label: Text(
                      'FECHA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    fixedWidth: 85,
                  ),
                  DataColumn2(
                    label: Text(
                      'COMPROBANTE / NCF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text(
                      'BENEFICIARIO / PROVEEDOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text(
                      'CUENTA CONTABLE (CLASE 6)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text(
                      'CONDICIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    fixedWidth: 105,
                  ),
                  DataColumn2(
                    label: Text(
                      'ITBIS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    fixedWidth: 95,
                    numeric: true,
                  ),
                  DataColumn2(
                    label: Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    fixedWidth: 110,
                    numeric: true,
                  ),
                  DataColumn2(
                    label: Text(
                      'ACCIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    fixedWidth: 55,
                  ),
                ],
                rows: state.gastos.map((gasto) => _buildRow(context, gasto)).toList(),
              ),
            ),
          ),

          // Barra de Paginación Integrada
          _buildPaginationBar(),
        ],
      ),
    );
  }

  DataRow2 _buildRow(BuildContext context, Compra gasto) {
    final primerDetalle = gasto.detalles.isNotEmpty ? gasto.detalles.first : null;
    final cuentaNombre = primerDetalle?.cuentaContable != null
        ? '${primerDetalle!.cuentaContable!.codigo} - ${primerDetalle.cuentaContable!.nombre}'
        : (primerDetalle?.descripcion ?? 'Gasto General');

    final esContado = gasto.tipoCompra.toUpperCase() == 'CONTADO';
    final fmtDate = DateFormat('dd/MM/yyyy');

    return DataRow2(
      cells: [
        // 1. Fecha
        DataCell(
          Text(
            fmtDate.format(gasto.fechaCompra),
            style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
          ),
        ),

        // 2. Comprobante / NCF
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gasto.numeroFacturaProveedor,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (gasto.ncf != null && gasto.ncf!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 0.6),
                  ),
                  child: Text(
                    gasto.ncf!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 3. Beneficiario / Proveedor
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gasto.proveedor?.nombre ?? 'Beneficiario Ocasional',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (primerDetalle?.descripcion != null &&
                  primerDetalle!.descripcion!.isNotEmpty &&
                  primerDetalle.descripcion != gasto.proveedor?.nombre)
                Text(
                  primerDetalle.descripcion!,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        // 4. Cuenta Contable
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              cuentaNombre,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.azulOscuro,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // 5. Condición
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  'Vence: ${fmtDate.format(gasto.fechaVencimiento!)}',
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFFD97706),
                  ),
                ),
            ],
          ),
        ),

        // 6. ITBIS
        DataCell(
          Text(
            gasto.impuestos > 0
                ? FormatterNumber.formatCurrency(gasto.impuestos)
                : '-',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: gasto.impuestos > 0
                  ? const Color(0xFF2563EB)
                  : Colors.grey.shade400,
            ),
          ),
        ),

        // 7. Total
        DataCell(
          Text(
            FormatterNumber.formatCurrency(gasto.total),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ),

        // 8. Acción
        DataCell(
          IconButton(
            icon: const Icon(
              Icons.remove_red_eye_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            tooltip: 'Ver comprobante y asiento contable',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => GastoDetalleDialog(gasto: gasto),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cantidad de registros y rango
          Row(
            children: [
              Text(
                'Total: ${state.total} gastos',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Filas por página:',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: [10, 15, 25, 50].contains(state.perPage)
                      ? state.perPage
                      : 15,
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 15, child: Text('15')),
                    DropdownMenuItem(value: 25, child: Text('25')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                  ],
                  onChanged: (val) {
                    if (val != null) onPerPageChanged(val);
                  },
                ),
              ),
            ],
          ),

          // Controles de navegación de página
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page, size: 16),
                tooltip: 'Primera página',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: state.currentPage > 1 ? () => onPageChanged(1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 16),
                tooltip: 'Anterior',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: state.currentPage > 1
                    ? () => onPageChanged(state.currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '${state.currentPage} / ${state.lastPage > 0 ? state.lastPage : 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 16),
                tooltip: 'Siguiente',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: state.currentPage < state.lastPage
                    ? () => onPageChanged(state.currentPage + 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page, size: 16),
                tooltip: 'Última página',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: state.currentPage < state.lastPage
                    ? () => onPageChanged(state.lastPage)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

