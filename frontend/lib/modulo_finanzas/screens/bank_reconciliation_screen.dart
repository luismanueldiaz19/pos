import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../model/banco_models.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';

class BankReconciliationScreen extends ConsumerStatefulWidget {
  final BankAccountModel account;

  const BankReconciliationScreen({super.key, required this.account});

  @override
  ConsumerState<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends ConsumerState<BankReconciliationScreen> {
  final Set<int> _selectedTransactions = {};
  final TextEditingController _saldoBancoCtrl = TextEditingController(text: '');
  late final TextEditingController _fechaCorteCtrl;
  DateTime _fechaCorte = DateTime.now();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fechaCorteCtrl = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_fechaCorte),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(bankProvider.notifier).loadTransactions(token, widget.account.id);
      }
    });

    _saldoBancoCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _saldoBancoCtrl.dispose();
    _fechaCorteCtrl.dispose();
    super.dispose();
  }

  void _completarConciliacion() async {
    if (_selectedTransactions.isEmpty) return;

    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isProcessing = true);

    try {
      await ref.read(bankProvider.notifier).reconcileTransactions(token, _selectedTransactions.toList());

      if (!mounted) return;
      showToast(context, 'Conciliación completada exitosamente', bgColor: Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showToast(context, 'Error al conciliar: $e', bgColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankProvider);

    // Filtrar transacciones pendientes de conciliar
    final transactions = state.transactions.where((tx) {
      final s = tx.status.toLowerCase();
      return tx.bankAccountId == widget.account.id && s != 'completed' && s != 'completado';
    }).toList();

    final currentAccount = state.accounts.firstWhere(
      (acc) => acc.id == widget.account.id,
      orElse: () => widget.account,
    );

    final saldoLibros = currentAccount.currentBalance;

    double saldoConciliado = 0;
    for (var tx in transactions) {
      if (_selectedTransactions.contains(tx.id)) {
        final isPositive = tx.type == 'deposit' || tx.type == 'interest';
        saldoConciliado += isPositive ? tx.amount : -tx.amount;
      }
    }

    final saldoBanco = double.tryParse(_saldoBancoCtrl.text) ?? 0;
    final diferencia = saldoConciliado - saldoBanco;

    final currencyFormatter = NumberFormat.currency(
      locale: 'es_DO',
      symbol: '\$ ',
      decimalDigits: 2,
    );

    final canComplete = diferencia.abs() < 0.001 &&
        _selectedTransactions.isNotEmpty &&
        !_isProcessing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONCILIACIÓN BANCARIA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.azulOscuro,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Cuenta: ${currentAccount.name} • #${currentAccount.accountNumber}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PANEL IZQUIERDO: Transacciones pendientes ───────────────────
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transacciones Pendientes',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Marca las transacciones que aparecen en el estado de cuenta bancario',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        if (transactions.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (_selectedTransactions.length == transactions.length) {
                                  _selectedTransactions.clear();
                                } else {
                                  _selectedTransactions.addAll(transactions.map((t) => t.id));
                                }
                              });
                            },
                            icon: Icon(
                              _selectedTransactions.length == transactions.length
                                  ? Icons.clear_all_rounded
                                  : Icons.select_all_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              _selectedTransactions.length == transactions.length
                                  ? 'Deseleccionar todas'
                                  : 'Seleccionar todas',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 16),

                    // Lista de transacciones pendientes
                    Expanded(
                      child: state.isLoading && transactions.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : transactions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 42,
                                        color: Colors.green.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'No hay transacciones pendientes',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.azulOscuro,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Todas las transacciones de esta cuenta están conciliadas',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: transactions.length,
                                  separatorBuilder: (context, index) => const Divider(height: 8),
                                  itemBuilder: (context, index) {
                                    final tx = transactions[index];
                                    final isPositive = tx.type == 'deposit' || tx.type == 'interest';
                                    final color = isPositive ? Colors.green.shade700 : Colors.red.shade700;
                                    final amountPrefix = isPositive ? '+ ' : '- ';
                                    final amountText = '$amountPrefix${currencyFormatter.format(tx.amount)}';
                                    final isSelected = _selectedTransactions.contains(tx.id);

                                    DateTime? pDate;
                                    try {
                                      pDate = DateTime.parse(tx.date);
                                    } catch (_) {}
                                    final formattedDate = pDate != null
                                        ? DateFormat('dd/MM/yyyy').format(pDate)
                                        : tx.date;

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedTransactions.remove(tx.id);
                                          } else {
                                            _selectedTransactions.add(tx.id);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedTransactions.add(tx.id);
                                                  } else {
                                                    _selectedTransactions.remove(tx.id);
                                                  }
                                                });
                                              },
                                              activeColor: AppColors.primary,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    (tx.description ?? 'TRANSACCIÓN').toUpperCase(),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: AppColors.azulOscuro,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        formattedDate,
                                                        style: TextStyle(
                                                          color: Colors.grey.shade600,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                      if (tx.reference != null && tx.reference!.isNotEmpty) ...[
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          '• Ref: ${tx.reference}',
                                                          style: TextStyle(
                                                            color: Colors.grey.shade500,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              amountText,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── PANEL DERECHO: Resumen y Conciliación (Scrollable para evitar overflow) ──
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título Sección 1
                      const Text(
                        'Datos del Banco',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Input Saldo Final Banco
                      CustomTextField(
                        controller: _saldoBancoCtrl,
                        label: 'Saldo Final (según el Banco)',
                        hintText: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        prefixIcon: Icons.account_balance_outlined,
                      ),
                      const SizedBox(height: 10),

                      // Selector de Fecha de Corte
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _fechaCorte,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _fechaCorte = date;
                              _fechaCorteCtrl.text = DateFormat('dd/MM/yyyy').format(date);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: _fechaCorteCtrl,
                            label: 'Fecha de Corte',
                            readOnly: true,
                            suffixIcon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                      const Divider(height: 20),

                      // Título Sección 2
                      const Text(
                        'Resumen de Conciliación',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildSummaryRow(
                        'Saldo en Libros',
                        currencyFormatter.format(saldoLibros),
                        Colors.grey.shade600,
                        AppColors.azulOscuro,
                      ),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        'Saldo Conciliado (${_selectedTransactions.length} marcadas)',
                        currencyFormatter.format(saldoConciliado),
                        Colors.grey.shade600,
                        AppColors.azulOscuro,
                      ),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        'Saldo Banco',
                        currencyFormatter.format(saldoBanco),
                        Colors.grey.shade600,
                        AppColors.azulOscuro,
                      ),

                      const Divider(height: 20),

                      // Caja de Diferencia
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: diferencia.abs() < 0.001
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: diferencia.abs() < 0.001
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Diferencia',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: diferencia.abs() < 0.001
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(diferencia),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: diferencia.abs() < 0.001
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón Completar Conciliación
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canComplete ? _completarConciliacion : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canComplete ? AppColors.primary : Colors.grey.shade300,
                            foregroundColor: canComplete ? Colors.white : Colors.grey.shade500,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Completar Conciliación',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: labelColor, fontSize: 11.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 12),
        ),
      ],
    );
  }
}
