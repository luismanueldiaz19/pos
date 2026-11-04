import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/banco_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/configuracion_contable_provider.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';

class BankAccountDialog extends ConsumerStatefulWidget {
  final BankAccountModel? account;
  const BankAccountDialog({super.key, this.account});

  @override
  ConsumerState<BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends ConsumerState<BankAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedBankId;
  int? _selectedAccountingAccountId;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _accountNumberCtrl = TextEditingController();
  final TextEditingController _currencyCtrl = TextEditingController(text: 'DOP');
  final TextEditingController _initialBalanceCtrl = TextEditingController(text: '0');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(token);
      }
    });

    if (widget.account != null) {
      _selectedBankId = widget.account!.bankId;
      _nameCtrl.text = widget.account!.name;
      _accountNumberCtrl.text = widget.account!.accountNumber;
      _currencyCtrl.text = widget.account!.currency;
      _initialBalanceCtrl.text = widget.account!.currentBalance.toString();
      _selectedAccountingAccountId = widget.account!.accountingAccountId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _currencyCtrl.dispose();
    _initialBalanceCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate() || _selectedBankId == null) {
      if (_selectedBankId == null && mounted) {
        showToast(context, 'Por favor, selecciona un banco', bgColor: Colors.orange);
      }
      return;
    }

    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    final data = {
      'bank_id': _selectedBankId,
      'name': _nameCtrl.text.trim(),
      'account_number': _accountNumberCtrl.text.trim(),
      'currency': _currencyCtrl.text.trim().toUpperCase(),
      'current_balance': double.tryParse(_initialBalanceCtrl.text) ?? 0,
      'accounting_account_id': _selectedAccountingAccountId,
      'is_active': true,
    };

    try {
      if (widget.account == null) {
        await ref.read(bankProvider.notifier).createAccount(token, data);
        if (mounted) showToast(context, 'Cuenta creada exitosamente', bgColor: Colors.green);
      } else {
        await ref.read(bankProvider.notifier).updateAccount(token, widget.account!.id, data);
        if (mounted) showToast(context, 'Cuenta actualizada correctamente', bgColor: Colors.green);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error al guardar: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankProvider);
    final contableState = ref.watch(configuracionContableProvider);

    // Encuentra la cuenta principal "ACTIVOS CORRIENTES"
    final bancoParent = contableState.catalogoCuentasCompleto
        .where((c) => c.nombre.toUpperCase().trim() == 'ACTIVOS CORRIENTES')
        .firstOrNull;

    List<int> descendientesIds = [];
    if (bancoParent != null) {
      void buscarHijos(int id) {
        final hijos = contableState.catalogoCuentasCompleto
            .where((c) => c.padreId == id)
            .toList();
        for (var h in hijos) {
          descendientesIds.add(h.id);
          buscarHijos(h.id);
        }
      }

      buscarHijos(bancoParent.id);
    }

    // Filtrar cuentas de banco (descendientes de ACTIVOS CORRIENTES que permiten movimiento)
    final cuentasBancos = contableState.catalogoCuentasCompleto
        .where((c) => descendientesIds.contains(c.id) && c.permiteMovimiento)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ────────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.account_balance_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.account == null
                                ? 'Nueva Cuenta Bancaria'
                                : 'Editar Cuenta Bancaria',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.azulOscuro,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        splashRadius: 16,
                      ),
                    ],
                  ),
                  const Divider(height: 18),

                  // ── BANCO ASOCIADO ─────────────────────────────────────────
                  const Text(
                    'Banco / Institución',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedBankId,
                    isDense: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    items: state.banks
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              b.name,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBankId = v),
                    validator: (v) => v == null ? 'Selecciona una institución' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── NOMBRE DE LA CUENTA ────────────────────────────────────
                  CustomTextField(
                    controller: _nameCtrl,
                    label: 'Nombre de la cuenta',
                    hintText: 'Ej: Cuenta Corriente Operativa',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── NÚMERO DE CUENTA ───────────────────────────────────────
                  CustomTextField(
                    controller: _accountNumberCtrl,
                    label: 'Número de Cuenta',
                    hintText: 'Ej: 987654321',
                    keyboardType: TextInputType.text,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── MONEDA Y BALANCE ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: CustomTextField(
                          controller: _currencyCtrl,
                          label: 'Moneda',
                          hintText: 'DOP',
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: _initialBalanceCtrl,
                          label: widget.account == null
                              ? 'Balance Inicial'
                              : 'Balance Actual',
                          hintText: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          prefixIcon: Icons.attach_money,
                          validator: (v) {
                            if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── CUENTA CONTABLE ASOCIADA ───────────────────────────────
                  const Text(
                    'Cuenta Contable Asociada (Opcional)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedAccountingAccountId,
                    isDense: true,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text(
                          '-- Sin vincular contabilidad --',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      ...cuentasBancos.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.codigo} - ${c.nombre}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedAccountingAccountId = v),
                  ),

                  const SizedBox(height: 20),

                  // ── BOTONES DE ACCIÓN ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.account == null ? 'Guardar Cuenta' : 'Actualizar Cuenta',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
