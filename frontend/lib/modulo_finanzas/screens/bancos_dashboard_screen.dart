import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import 'bank_transactions_screen.dart';
import '../widgets/bank_account_dialog.dart';
import '../widgets/bank_account_card.dart';

class BancosDashboardScreen extends ConsumerStatefulWidget {
  const BancosDashboardScreen({super.key});

  @override
  ConsumerState<BancosDashboardScreen> createState() =>
      _BancosDashboardScreenState();
}

class _BancosDashboardScreenState extends ConsumerState<BancosDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(bankProvider.notifier).loadDashboardData(token);
      }
    });
  }

  void _abrirDialogoNuevaCuenta() {
    showDialog(context: context, builder: (ctx) => const BankAccountDialog());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankProvider);
    final auth = ref.watch(authProvider);

    // Métricas rápidas para la barra ejecutiva
    final totalCuentas = state.accounts.length;
    final totalBalance = state.accounts.fold<double>(
      0.0,
      (sum, acc) => sum + acc.currentBalance,
    );
    final cuentasActivas = state.accounts.where((a) => a.isActive).length;
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$ ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'BANCOS Y CUENTAS',
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton.icon(
              onPressed: _abrirDialogoNuevaCuenta,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Nueva Cuenta',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.azulOscuro),
            tooltip: 'Actualizar',
            onPressed: () {
              if (auth.token != null) {
                ref.read(bankProvider.notifier).loadDashboardData(auth.token!);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.isLoading && state.accounts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.errorMessage != null && state.accounts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar cuentas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.errorMessage!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (auth.token != null) {
                              ref.read(bankProvider.notifier).loadDashboardData(auth.token!);
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reintentar', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulOscuro,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ── BARRA SUPERIOR DE RESUMEN EJECUTIVO (KPIs) ─────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          _buildKpiCard(
                            label: 'TOTAL CUENTAS',
                            value: '$totalCuentas',
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.azulOscuro,
                          ),
                          const SizedBox(width: 10),
                          _buildKpiCard(
                            label: 'BALANCE TOTAL',
                            value: currencyFormatter.format(totalBalance),
                            icon: Icons.monetization_on_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          _buildKpiCard(
                            label: 'CUENTAS ACTIVAS',
                            value: '$cuentasActivas de $totalCuentas',
                            icon: Icons.check_circle_outline_rounded,
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),

                    // ── CONTENIDO PRINCIPAL: GRID DE CUENTAS ──────────────────
                    Expanded(
                      child: state.accounts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_outlined,
                                    size: 52,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay cuentas o cajas registradas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Presiona "Nueva Cuenta" para registrar la primera cuenta bancaria o caja',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 340,
                                  childAspectRatio: 1.55,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: state.accounts.length,
                                itemBuilder: (context, index) {
                                  final cuenta = state.accounts[index];
                                  return BankAccountCard(
                                    account: cuenta,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BankTransactionsScreen(
                                            account: cuenta,
                                          ),
                                        ),
                                      );
                                    },
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) =>
                                            BankAccountDialog(account: cuenta),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: color),
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
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
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
