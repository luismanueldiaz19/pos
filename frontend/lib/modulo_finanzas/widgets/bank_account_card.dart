import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/banco_models.dart';
import '../../palletes/app_colors.dart';

class BankAccountCard extends StatefulWidget {
  final BankAccountModel account;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const BankAccountCard({
    super.key,
    required this.account,
    required this.onTap,
    this.onEdit,
  });

  @override
  State<BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<BankAccountCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'es_DO',
      symbol: '\$ ',
      decimalDigits: 2,
    );
    final formattedBalance = formatCurrency.format(widget.account.currentBalance);

    final isGeneralCash = widget.account.name.toLowerCase().contains('caja') ||
        (widget.account.bank?.name.toLowerCase().contains('caja') ?? false);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.grey.shade200,
              width: _isHovered ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.02),
                blurRadius: _isHovered ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── FILA SUPERIOR: Icono tipo cuenta, Edición y Estado ────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isGeneralCash
                          ? Colors.teal.shade50
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isGeneralCash
                          ? Icons.point_of_sale_rounded
                          : Icons.account_balance_rounded,
                      color: isGeneralCash
                          ? Colors.teal.shade700
                          : AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      color: Colors.grey.shade600,
                      tooltip: 'Editar Cuenta',
                      onPressed: widget.onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      splashRadius: 16,
                    ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.account.isActive
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.account.isActive
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      widget.account.isActive ? 'ACTIVA' : 'INACTIVA',
                      style: TextStyle(
                        color: widget.account.isActive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              // ── SECCIÓN CENTRAL: Nombres y número de cuenta ──────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.account.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppColors.azulOscuro,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.account.bank?.name ?? 'Banco Principal',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '# ${widget.account.accountNumber}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Divider(height: 10, thickness: 0.8),

              // ── SECCIÓN INFERIOR: Balance y Moneda ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.account.currency.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Text(
                    formattedBalance,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
