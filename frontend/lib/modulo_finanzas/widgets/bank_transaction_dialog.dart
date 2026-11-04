import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';

class BankTransactionDialog extends ConsumerStatefulWidget {
  final int accountId;

  const BankTransactionDialog({super.key, required this.accountId});

  @override
  ConsumerState<BankTransactionDialog> createState() =>
      _BankTransactionDialogState();
}

class _BankTransactionDialogState extends ConsumerState<BankTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'deposit';
  DateTime _selectedDate = DateTime.now();
  late final TextEditingController _dateCtrl;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _referenceCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
    );
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    final data = {
      'bank_account_id': widget.accountId,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'type': _selectedType,
      'amount': double.tryParse(_amountCtrl.text) ?? 0,
      'reference': _referenceCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
    };

    try {
      await ref.read(bankProvider.notifier).registerTransaction(token, data);
      if (mounted) {
        showToast(context, 'Transacción registrada correctamente', bgColor: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Error al registrar: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                              Icons.receipt_long_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Registrar Transacción',
                            style: TextStyle(
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

                  // ── TIPO DE TRANSACCIÓN ────────────────────────────────────
                  const Text(
                    'Tipo de Movimiento',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
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
                    items: const [
                      DropdownMenuItem(
                        value: 'deposit',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text('Depósito / Ingreso (+)', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'withdrawal',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Retiro / Egreso (-)', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'fee',
                        child: Row(
                          children: [
                            Icon(Icons.price_check_rounded, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Text('Comisión / Cargo bancario (-)', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'interest',
                        child: Row(
                          children: [
                            Icon(Icons.trending_up_rounded, color: Colors.teal, size: 16),
                            SizedBox(width: 8),
                            Text('Interés a favor (+)', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 12),

                  // ── MONTO Y FECHA ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _amountCtrl,
                          label: 'Monto',
                          hintText: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          prefixIcon: Icons.attach_money,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (double.tryParse(v) == null) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                                _dateCtrl.text = DateFormat('dd/MM/yyyy').format(date);
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: _dateCtrl,
                              label: 'Fecha',
                              readOnly: true,
                              suffixIcon: Icons.calendar_today_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── REFERENCIA ─────────────────────────────────────────────
                  CustomTextField(
                    controller: _referenceCtrl,
                    label: 'Referencia / No. Comprobante',
                    hintText: 'Ej: DEP-00123 / REF-9842',
                  ),
                  const SizedBox(height: 12),

                  // ── DESCRIPCIÓN ────────────────────────────────────────────
                  CustomTextField(
                    controller: _descriptionCtrl,
                    label: 'Concepto / Descripción',
                    hintText: 'Detalle o justificación del movimiento',
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
                            : const Text(
                                'Registrar Movimiento',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
