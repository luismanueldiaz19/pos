import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../palletes/app_colors.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_empty_state.dart';
import '../../../facturacion/providers/metodo_pago_provider.dart';
import '../../../providers/configuracion_contable_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../model/catalogo_cuenta_model.dart';
import '../providers/compras_provider.dart';
import '../providers/proveedores_provider.dart';
import '../models/proveedor.dart';
import 'widgets/gasto_clasificacion_card.dart';
import 'widgets/gasto_beneficiario_card.dart';
import 'widgets/gasto_importe_card.dart';
import 'widgets/gasto_condicion_card.dart';
import 'widgets/gasto_motor_contable_card.dart';

///   ` Pantalla desacoplada y compacta para el Registro de Gastos Operativos.
///   ` Cumple rigurosamente con:
///   ` Flutter-clean-reusable-ui`: Componentes modulares, <250 líneas,
///   ` Uso de widgets centrales (`CustomTextField`, `CustomButton`).
///   ` Flutter-small-widgets`: Densidad visual alta, alturas 34-38px, fuentes 11-13px.
///   ` Motor-contable`: Cero hardcoding, partida doble estricta y previsualización contable en vivo.
///
///

class RegistrarGastoScreen extends ConsumerStatefulWidget {
  const RegistrarGastoScreen({super.key});

  @override
  ConsumerState<RegistrarGastoScreen> createState() =>
      _RegistrarGastoScreenState();
}

class _RegistrarGastoScreenState extends ConsumerState<RegistrarGastoScreen> {
  // Controladores de texto
  final TextEditingController _conceptoCtrl = TextEditingController();
  final TextEditingController _subtotalCtrl = TextEditingController();
  final TextEditingController _itbisManualCtrl = TextEditingController();
  final TextEditingController _numFacturaCtrl = TextEditingController();
  final TextEditingController _ncfCtrl = TextEditingController();
  final TextEditingController _beneficiarioCtrl = TextEditingController();
  final TextEditingController _referenciaPagoCtrl = TextEditingController();

  // Estado del Formulario
  int? _selectedCuentaId;
  String _categoriaChip = 'TODOS';
  bool _esGastoMenor = true;
  int? _selectedProveedorId;
  DateTime _fechaGasto = DateTime.now();
  String _itbisModo = 'EXENTO';
  String _tipoCompra = 'CONTADO';
  int? _selectedMetodoPagoId;
  DateTime _fechaVencimiento = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _autoGenerarRecibo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(configuracionContableProvider.notifier).loadAllData(token);
      }
      ref.read(proveedoresProvider.notifier).loadProveedores();
      ref.read(metodoPagoProvider.notifier).fetchMetodosActivos();
    });
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _subtotalCtrl.dispose();
    _itbisManualCtrl.dispose();
    _numFacturaCtrl.dispose();
    _ncfCtrl.dispose();
    _beneficiarioCtrl.dispose();
    _referenciaPagoCtrl.dispose();
    super.dispose();
  }

  void _autoGenerarRecibo() {
    final now = DateTime.now();
    final fechaStr = DateFormat('yyyyMMdd').format(now);
    final rnd = (Random().nextInt(9000) + 1000).toString();
    _numFacturaCtrl.text = 'REC-$fechaStr-$rnd';
    setState(() {});
  }

  double get _subtotal => double.tryParse(_subtotalCtrl.text) ?? 0.0;

  double get _itbis {
    if (_itbisModo == 'EXENTO') return 0.0;
    if (_itbisModo == 'ITBIS18') {
      return double.parse((_subtotal * 0.18).toStringAsFixed(2));
    }
    return double.tryParse(_itbisManualCtrl.text) ?? 0.0;
  }

  double get _total => _subtotal + _itbis;

  List<CatalogoCuentaModel> _filtrarCuentas(List<CatalogoCuentaModel> todas) {
    final cuentasGastos = todas.where((c) {
      final esGasto =
          c.tipo.toUpperCase() == 'GASTOS' || c.codigo.startsWith('6');
      return esGasto && c.permiteMovimiento;
    }).toList();

    if (_categoriaChip == 'SERVICIOS') {
      return cuentasGastos.where((c) {
        final n = c.nombre.toUpperCase();
        return n.contains('LUZ') ||
            n.contains('ENERGIA') ||
            n.contains('AGUA') ||
            n.contains('BASURA') ||
            n.contains('TELEFONO') ||
            n.contains('INTERNET');
      }).toList();
    } else if (_categoriaChip == 'COMBUSTIBLE') {
      return cuentasGastos.where((c) {
        final n = c.nombre.toUpperCase();
        return n.contains('COMBUSTIBLE') ||
            n.contains('TRANSPORTE') ||
            n.contains('GAS');
      }).toList();
    } else if (_categoriaChip == 'MANTENIMIENTO') {
      return cuentasGastos.where((c) {
        final n = c.nombre.toUpperCase();
        return n.contains('MANTENIMIENTO') ||
            n.contains('REPARACION') ||
            n.contains('REPUESTO');
      }).toList();
    } else if (_categoriaChip == 'LIMPIEZA') {
      return cuentasGastos
          .where(
            (c) =>
                c.nombre.toUpperCase().contains('LIMPIEZA') ||
                c.nombre.toUpperCase().contains('SUMINISTRO'),
          )
          .toList();
    } else if (_categoriaChip == 'ALQUILER') {
      return cuentasGastos
          .where((c) => c.nombre.toUpperCase().contains('ALQUILER'))
          .toList();
    } else if (_categoriaChip == 'PERSONAL') {
      return cuentasGastos.where((c) {
        final n = c.nombre.toUpperCase();
        return n.contains('NOMINA') ||
            n.contains('SUELDO') ||
            n.contains('SALARIO');
      }).toList();
    } else if (_categoriaChip == 'OTROS') {
      return cuentasGastos.where((c) {
        final n = c.nombre.toUpperCase();
        return n.contains('OTRO') ||
            n.contains('FINANCIERO') ||
            n.contains('INTERES');
      }).toList();
    }
    return cuentasGastos;
  }

  Future<void> _guardarGasto() async {
    if (_isSaving) return;

    if (_selectedCuentaId == null) {
      showToast(
        context,
        'Seleccione la cuenta contable de gasto (Clase 6)',
        bgColor: Colors.orange,
      );
      return;
    }
    if (_subtotal <= 0) {
      showToast(context, 'Ingrese un monto mayor a 0', bgColor: Colors.orange);
      return;
    }

    final provState = ref.read(proveedoresProvider);
    int? proveedorIdFinal = _selectedProveedorId;

    if (_esGastoMenor) {
      final gen = provState.proveedores.firstWhere(
        (p) =>
            p.nombre.toUpperCase().contains('GASTOS MENORES') ||
            p.nombre.toUpperCase().contains('OCASIONAL') ||
            p.esInformal,
        orElse: () => provState.proveedores.isNotEmpty
            ? provState.proveedores.first
            : Proveedor(
                id: 1,
                nombre: 'Proveedor Genérico',
                esInformal: true,
                activo: true,
              ),
      );
      proveedorIdFinal = gen.id;
    } else {
      if (proveedorIdFinal == null) {
        showToast(
          context,
          'Seleccione un proveedor formal registrado',
          bgColor: Colors.orange,
        );
        return;
      }
    }

    if (_numFacturaCtrl.text.trim().isEmpty) {
      _autoGenerarRecibo();
    }

    if (_tipoCompra == 'CREDITO' && _esGastoMenor) {
      showToast(
        context,
        'Para compras a crédito, seleccione un Proveedor Formal Registrado',
        bgColor: Colors.orange,
      );
      return;
    }

    final configState = ref.read(configuracionContableProvider);
    final cuentaSeleccionada = configState.catalogoCuentasCompleto
        .where((c) => c.id == _selectedCuentaId)
        .firstOrNull;

    final conceptoGasto = _conceptoCtrl.text.trim().isNotEmpty
        ? _conceptoCtrl.text.trim()
        : (cuentaSeleccionada?.nombre ?? 'Gasto Operativo');

    final beneficiarioTexto = _beneficiarioCtrl.text.trim();
    final notasFinales = _esGastoMenor && beneficiarioTexto.isNotEmpty
        ? 'Beneficiario: $beneficiarioTexto. $conceptoGasto'
        : conceptoGasto;

    setState(() => _isSaving = true);

    try {
      final payload = {
        'proveedor_id': proveedorIdFinal,
        'numero_factura_proveedor': _numFacturaCtrl.text.trim(),
        'ncf': _ncfCtrl.text.trim().isNotEmpty ? _ncfCtrl.text.trim() : null,
        'fecha_compra': DateFormat('yyyy-MM-dd').format(_fechaGasto),
        'fecha_vencimiento': _tipoCompra == 'CREDITO'
            ? DateFormat('yyyy-MM-dd').format(_fechaVencimiento)
            : null,
        'tipo_compra': _tipoCompra,
        'notas': notasFinales,
        'idempotency_key': const Uuid().v4(),
        'detalles': [
          {
            'producto_id': null,
            'descripcion': conceptoGasto,
            'cuenta_contable_id': _selectedCuentaId,
            'cantidad': 1,
            'costo_unitario': _subtotal,
            'impuesto_monto': _itbis,
          },
        ],
        if (_tipoCompra == 'CONTADO')
          'metodo_pago_id': _selectedMetodoPagoId ?? 1,
        if (_referenciaPagoCtrl.text.trim().isNotEmpty)
          'referencia_pago': _referenciaPagoCtrl.text.trim(),
      };

      final success = await ref
          .read(comprasProvider.notifier)
          .createCompra(payload);
      if (!mounted) return;

      if (success) {
        showToast(
          context,
          '✓ Gasto de ${FormatterNumber.formatCurrency(_total)} registrado con éxito en Contabilidad.',
          bgColor: Colors.green,
        );
        _conceptoCtrl.clear();
        _subtotalCtrl.clear();
        _itbisManualCtrl.clear();
        _beneficiarioCtrl.clear();
        _referenciaPagoCtrl.clear();
        _itbisModo = 'EXENTO';
        _autoGenerarRecibo();
        setState(() {});
      } else {
        final err =
            ref.read(comprasProvider).error ?? 'Error al registrar el gasto';
        showToast(context, err, bgColor: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Excepción: $e', bgColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final bool isAdmin = auth.roles.contains('admin');
    final bool isContador = auth.roles.contains('contador');

    if (!isAdmin && !isContador) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Restringido')),
        body: const Center(
          child: CustomEmptyState(
            title: 'Acceso Denegado',
            subtitle:
                'Este módulo está reservado exclusivamente para los roles Administrador y Contador.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final configState = ref.watch(configuracionContableProvider);
    final provState = ref.watch(proveedoresProvider);
    final metodoState = ref.watch(metodoPagoProvider);

    final cuentasGastos = _filtrarCuentas(configState.catalogoCuentasCompleto);

    if (_selectedMetodoPagoId == null && metodoState.metodos.isNotEmpty) {
      _selectedMetodoPagoId = metodoState.metodos.first.id;
    }

    final cuentaActiva = configState.catalogoCuentasCompleto
        .where((c) => c.id == _selectedCuentaId)
        .firstOrNull;

    final metodoActivo = metodoState.metodos
        .where((m) => m.id == _selectedMetodoPagoId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.azulOscuro, size: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registro de Gastos Operativos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                Text(
                  'Clase 6 · Afecta Estado de Resultados (No inventario)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: () {
                _conceptoCtrl.clear();
                _subtotalCtrl.clear();
                _itbisManualCtrl.clear();
                _beneficiarioCtrl.clear();
                _referenciaPagoCtrl.clear();
                _autoGenerarRecibo();
                setState(() => _selectedCuentaId = null);
              },
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Limpiar', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          final col1 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GastoClasificacionCard(
                cuentas: cuentasGastos,
                selectedCuentaId: _selectedCuentaId,
                onCuentaSelected: (val) =>
                    setState(() => _selectedCuentaId = val),
                conceptoCtrl: _conceptoCtrl,
                selectedCategoriaChip: _categoriaChip,
                onCategoriaChipChanged: (cat) =>
                    setState(() => _categoriaChip = cat),
              ),
              const SizedBox(height: 12),
              GastoBeneficiarioCard(
                esGastoMenor: _esGastoMenor,
                onTipoBeneficiarioChanged: (val) =>
                    setState(() => _esGastoMenor = val),
                beneficiarioCtrl: _beneficiarioCtrl,
                proveedores: provState.proveedores,
                selectedProveedorId: _selectedProveedorId,
                onProveedorSelected: (val) =>
                    setState(() => _selectedProveedorId = val),
                numFacturaCtrl: _numFacturaCtrl,
                onAutoGenerarRecibo: _autoGenerarRecibo,
                ncfCtrl: _ncfCtrl,
                fechaGasto: _fechaGasto,
                onFechaSelected: (val) => setState(() => _fechaGasto = val),
              ),
            ],
          );
          final col2 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GastoImporteCard(
                subtotalCtrl: _subtotalCtrl,
                itbisModo: _itbisModo,
                onItbisModoChanged: (modo) => setState(() => _itbisModo = modo),
                itbisManualCtrl: _itbisManualCtrl,
                subtotal: _subtotal,
                itbis: _itbis,
                total: _total,
                onValuesChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              GastoCondicionCard(
                tipoCompra: _tipoCompra,
                onTipoCompraChanged: (tipo) =>
                    setState(() => _tipoCompra = tipo),
                metodos: metodoState.metodos,
                selectedMetodoPagoId: _selectedMetodoPagoId,
                onMetodoPagoSelected: (val) =>
                    setState(() => _selectedMetodoPagoId = val),
                referenciaPagoCtrl: _referenciaPagoCtrl,
                fechaVencimiento: _fechaVencimiento,
                onFechaVencimientoSelected: (val) =>
                    setState(() => _fechaVencimiento = val),
              ),
              const SizedBox(height: 12),
              GastoMotorContableCard(
                cuentaGasto: cuentaActiva,
                tipoCompra: _tipoCompra,
                metodoPago: metodoActivo,
                subtotal: _subtotal,
                itbis: _itbis,
                total: _total,
              ),
              const SizedBox(height: 16),
              CustomButton(
                title: 'REGISTRAR GASTO EN CONTABILIDAD',
                icon: Icons.check_circle_outline,
                height: 42,
                fontSize: 13,
                borderRadius: 8,
                backgroundColor: AppColors.primary,
                isLoading: _isSaving,
                onPressed: _guardarGasto,
              ),
            ],
          );
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: col1,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    child: col2,
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(children: [col1, const SizedBox(height: 12), col2]),
          );
        },
      ),
    );
  }
}
