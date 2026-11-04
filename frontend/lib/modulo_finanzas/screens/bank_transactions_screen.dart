import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../model/banco_models.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../widgets/bank_transaction_dialog.dart';
import 'bank_reconciliation_screen.dart';
import '../../widgets/custom_text_field.dart';

class BankTransactionsScreen extends ConsumerStatefulWidget {
  final BankAccountModel account;

  const BankTransactionsScreen({super.key, required this.account});

  @override
  ConsumerState<BankTransactionsScreen> createState() => _BankTransactionsScreenState();
}

class _BankTransactionsScreenState extends ConsumerState<BankTransactionsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'todas'; // todas, deposit, withdrawal, pending, completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(bankProvider.notifier).loadTransactions(token, widget.account.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirDialogoNuevaTransaccion() {
    showDialog(
      context: context,
      builder: (ctx) => BankTransactionDialog(accountId: widget.account.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankProvider);
    final auth = ref.watch(authProvider);

    // Obtener la cuenta más actualizada
    final currentAccount = state.accounts.firstWhere(
      (acc) => acc.id == widget.account.id,
      orElse: () => widget.account,
    );

    final allTransactions = state.transactions
        .where((tx) => tx.bankAccountId == widget.account.id)
        .toList();

    // Filtrar según búsqueda y tipo
    final query = _searchCtrl.text.trim().toLowerCase();
    final transactions = allTransactions.where((tx) {
      final matchesSearch = query.isEmpty ||
          (tx.description ?? '').toLowerCase().contains(query) ||
          (tx.reference ?? '').toLowerCase().contains(query);

      if (!matchesSearch) return false;

      if (_selectedFilter == 'deposit') return tx.type == 'deposit' || tx.type == 'interest';
      if (_selectedFilter == 'withdrawal') return tx.type == 'withdrawal' || tx.type == 'fee';
      if (_selectedFilter == 'pending') {
        final s = tx.status.toLowerCase();
        return s == 'pending' || s == 'en tránsito' || s != 'completed';
      }
      if (_selectedFilter == 'completed') {
        final s = tx.status.toLowerCase();
        return s == 'completed' || s == 'completado';
      }
      return true;
    }).toList();

    // Formateadores
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_DO',
      symbol: '\$ ',
      decimalDigits: 2,
    );

    final totalIngresos = allTransactions
        .where((t) => t.type == 'deposit' || t.type == 'interest')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final totalEgresos = allTransactions
        .where((t) => t.type == 'withdrawal' || t.type == 'fee')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final pendientesCount = allTransactions.where((t) {
      final s = t.status.toLowerCase();
      return s != 'completed' && s != 'completado';
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRANSACCIONES: ${currentAccount.name.toUpperCase()}',
              style: const TextStyle(
                color: AppColors.azulOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '${currentAccount.bank?.name ?? 'Banco'} • Cuenta: #${currentAccount.accountNumber}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          // Botón Conciliar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BankReconciliationScreen(account: currentAccount),
                  ),
                );
              },
              icon: const Icon(Icons.fact_check_outlined, size: 15),
              label: const Text(
                'Conciliar',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.azulOscuro,
                side: const BorderSide(color: AppColors.azulOscuro),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón Registrar Movimiento
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton.icon(
              onPressed: _abrirDialogoNuevaTransaccion,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Nueva Transacción',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.azulOscuro, size: 20),
            tooltip: 'Actualizar',
            onPressed: () {
              if (auth.token != null) {
                ref.read(bankProvider.notifier).loadTransactions(auth.token!, widget.account.id);
                ref.read(bankProvider.notifier).loadDashboardData(auth.token!);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── RESUMEN SUPERIOR COMPACTO (KPIs) ───────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _buildKpiCard(
                  label: 'BALANCE EN LIBROS',
                  value: '${currentAccount.currency} ${currencyFormatter.format(currentAccount.currentBalance)}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  isPrimary: true,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  label: 'TOTAL INGRESOS',
                  value: currencyFormatter.format(totalIngresos),
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  label: 'TOTAL EGRESOS',
                  value: currencyFormatter.format(totalEgresos),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  label: 'POR CONCILIAR',
                  value: '$pendientesCount pendientes',
                  icon: Icons.pending_actions_rounded,
                  color: Colors.orange.shade800,
                ),
              ],
            ),
          ),

          // ── BARRA DE BÚSQUEDA Y FILTROS COMPACTOS ─────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Buscador
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: '',
                    hintText: 'Buscar transacción por descripción o referencia...',
                    controller: _searchCtrl,
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => setState(() {}),
                    suffixIcon: _searchCtrl.text.isNotEmpty ? Icons.clear_rounded : null,
                    onSuffixIconTap: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Filtros de tipo
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todas', 'todas', null),
                        const SizedBox(width: 6),
                        _buildFilterChip('Ingresos (+)', 'deposit', Colors.green.shade700),
                        const SizedBox(width: 6),
                        _buildFilterChip('Egresos (-)', 'withdrawal', Colors.red.shade700),
                        const SizedBox(width: 6),
                        _buildFilterChip('En Tránsito', 'pending', Colors.orange.shade800),
                        const SizedBox(width: 6),
                        _buildFilterChip('Completadas', 'completed', Colors.teal.shade700),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── LISTA DE TRANSACCIONES ─────────────────────────────────────────
          Expanded(
            child: state.isLoading && allTransactions.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(
                              'No se encontraron transacciones',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Registra una nueva transacción con el botón superior',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isPositive = tx.type == 'deposit' || tx.type == 'interest';

                          final color = isPositive ? Colors.green.shade700 : Colors.red.shade700;
                          final bgColor = isPositive ? Colors.green.shade50 : Colors.red.shade50;
                          final icon = isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

                          final amountPrefix = isPositive ? '+ ' : '- ';
                          final amountText = '$amountPrefix${currencyFormatter.format(tx.amount)}';

                          // Estado
                          final isCompleted = tx.status.toLowerCase() == 'completed' ||
                              tx.status.toLowerCase() == 'completado';
                          final statusText = isCompleted ? 'CONCILIADA' : 'EN TRÁNSITO';
                          final statusColor = isCompleted ? Colors.teal.shade700 : Colors.orange.shade800;
                          final statusBg = isCompleted ? Colors.teal.shade50 : Colors.orange.shade50;

                          DateTime? parsedDate;
                          try {
                            parsedDate = DateTime.parse(tx.date);
                          } catch (_) {}

                          final formattedDate = parsedDate != null
                              ? DateFormat('dd/MM/yyyy').format(parsedDate)
                              : tx.date;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // Icono de tipo
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(icon, color: color, size: 16),
                                ),
                                const SizedBox(width: 12),

                                // Descripción y Metadatos
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (tx.description ?? 'TRANSACCIÓN').toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: AppColors.azulOscuro,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined,
                                              size: 11, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (tx.reference != null &&
                                              tx.reference!.trim().isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '•  Ref: ${tx.reference}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Monto y Badge de Estado
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      amountText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color? color) {
    final isSelected = _selectedFilter == value;
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? color.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? color.withValues(alpha: 0.2) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
