import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../palletes/app_colors.dart';
import '../model/catalogo_cuenta_model.dart';
import '../providers/auth_provider.dart';
import '../providers/configuracion_contable_provider.dart';
import '../utils/helpers.dart';
import 'custom_text_field.dart';

/// Diálogo con buscador optimizado y renderizado perezoso (ListView.builder)
/// para seleccionar o crear Cuentas Contables de Gasto (Clase 6).
class BuscadorCuentaGastoDialog extends ConsumerStatefulWidget {
  final List<CatalogoCuentaModel> cuentas;
  final int? selectedId;
  final String title;

  const BuscadorCuentaGastoDialog({
    super.key,
    required this.cuentas,
    this.selectedId,
    this.title = 'Seleccionar Cuenta de Gasto',
  });

  static Future<CatalogoCuentaModel?> show(
    BuildContext context, {
    required List<CatalogoCuentaModel> cuentas,
    int? selectedId,
    String title = 'Seleccionar Cuenta de Gasto',
  }) {
    return showDialog<CatalogoCuentaModel>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BuscadorCuentaGastoDialog(
        cuentas: cuentas,
        selectedId: selectedId,
        title: title,
      ),
    );
  }

  @override
  ConsumerState<BuscadorCuentaGastoDialog> createState() =>
      _BuscadorCuentaGastoDialogState();
}

class _BuscadorCuentaGastoDialogState
    extends ConsumerState<BuscadorCuentaGastoDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  late List<CatalogoCuentaModel> _cuentasLocales;

  @override
  void initState() {
    super.initState();
    _cuentasLocales = List.from(widget.cuentas);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CatalogoCuentaModel> get _cuentasFiltradas {
    if (_query.trim().isEmpty) return _cuentasLocales;
    final q = _query.trim().toLowerCase();
    return _cuentasLocales.where((c) {
      final matchCod = c.codigo.toLowerCase().contains(q);
      final matchNom = c.nombre.toLowerCase().contains(q);
      return matchCod || matchNom;
    }).toList();
  }

  String _sugerirSiguienteCodigo() {
    int maxSub = 0;
    for (final c in _cuentasLocales) {
      if (c.codigo.startsWith('6.')) {
        final partes = c.codigo.split('.');
        if (partes.length >= 2) {
          final numVal = int.tryParse(partes[1]);
          if (numVal != null && numVal > maxSub) {
            maxSub = numVal;
          }
        }
      }
    }
    return '6.${maxSub + 1}';
  }

  Future<void> _abrirCrearCuenta() async {
    final codigoSugerido = _sugerirSiguienteCodigo();
    final codigoCtrl = TextEditingController(text: codigoSugerido);
    final nombreCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final result = await showDialog<CatalogoCuentaModel>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_chart_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Nueva Cuenta de Gasto',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crea una nueva subcuenta contable de Clase 6 (Gastos).',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: codigoCtrl,
                      label: 'Código Contable *',
                      hintText: 'Ej: 6.14',
                      prefixIcon: Icons.numbers_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'El código es requerido';
                        if (!v.trim().startsWith('6'))
                          return 'Debe iniciar con 6 (Clase Gastos)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: nombreCtrl,
                      label: 'Nombre de la Cuenta *',
                      hintText: 'Ej: COMBUSTIBLE Y TRANSPORTE',
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'El nombre es requerido';
                        if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                icon: isSaving
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check, size: 16),
                label: Text(
                  isSaving ? 'Guardando...' : 'Crear Cuenta',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        try {
                          final token = ref.read(authProvider).token;
                          if (token == null) throw Exception('Sesión expirada');

                          // Buscar padre Clase 6 (id de la cuenta '6' si existe)
                          int? padreId;
                          final rootCuenta = ref
                              .read(configuracionContableProvider)
                              .catalogoCuentasCompleto
                              .where((c) => c.codigo == '6')
                              .toList();
                          if (rootCuenta.isNotEmpty) {
                            padreId = rootCuenta.first.id;
                          }

                          final payload = {
                            'codigo': codigoCtrl.text.trim(),
                            'nombre': nombreCtrl.text.trim().toUpperCase(),
                            'tipo': 'Gastos',
                            'nivel': 2,
                            'padre_id': padreId,
                            'permite_movimiento': true,
                          };

                          await ref
                              .read(configuracionContableProvider.notifier)
                              .crearCuenta(token, payload);

                          // Recargar catálogo actualizado
                          await ref
                              .read(configuracionContableProvider.notifier)
                              .loadAllData(token);

                          final catalogoActual = ref
                              .read(configuracionContableProvider)
                              .catalogoCuentas;

                          final creada = catalogoActual.firstWhere(
                            (c) => c.codigo == codigoCtrl.text.trim(),
                            orElse: () => CatalogoCuentaModel(
                              id: 0,
                              codigo: codigoCtrl.text.trim(),
                              nombre: nombreCtrl.text.trim().toUpperCase(),
                              tipo: 'Gastos',
                              nivel: 2,
                              padreId: padreId,
                              permiteMovimiento: true,
                            ),
                          );

                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx, creada);
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (dialogCtx.mounted) {
                            showToast(
                              dialogCtx,
                              'Error: $e',
                              bgColor: Colors.red,
                            );
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (!_cuentasLocales.any((c) => c.codigo == result.codigo)) {
          _cuentasLocales.add(result);
        }
      });
      // Retornar la cuenta recién creada de inmediato a la pantalla principal
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _cuentasFiltradas;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 520,
        height: 580,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${_cuentasLocales.length} cuentas disponibles · Clase 6',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),

            // Barra de búsqueda + Botón Crear
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText:
                            'Buscar por código o nombre (ej: "luz", "6.2", "comb")...',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (val) => setState(() => _query = val),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _abrirCrearCuenta,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Nueva Cuenta',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista virtualizada con ListView.builder
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 40,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _query.isEmpty
                                ? 'No hay cuentas de gasto registradas'
                                : 'No se encontraron cuentas con "$_query"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _abrirCrearCuenta,
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text(
                              'Crear esta cuenta ahora',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final cuenta = list[index];
                        final isSelected = widget.selectedId == cuenta.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cuenta.codigo,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            title: Text(
                              cuenta.nombre,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 18,
                                  )
                                : const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                            onTap: () => Navigator.pop(context, cuenta),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
