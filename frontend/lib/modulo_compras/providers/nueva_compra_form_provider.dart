import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

// ── Generador de UUID v4 ─────────────────────────────────────────────────────
// Se usa para crear idempotency_key únicos por formulario.
const _uuid = Uuid();

// ─────────────────────────────────────────────────────────────────────────────

class NuevaCompraDetalleItem {
  final int? productoId;
  final String? productoNombre;
  final int? cuentaContableId;
  final String? descripcionGasto;
  final String presentacion;
  final double factorConversion;
  final double cantidad;
  final double costoUnitario;
  final double impuestoTasa;
  final double impuestoMonto;

  NuevaCompraDetalleItem({
    this.productoId,
    this.productoNombre,
    this.cuentaContableId,
    this.descripcionGasto,
    this.presentacion = 'Unidad',
    this.factorConversion = 1.0,
    required this.cantidad,
    required this.costoUnitario,
    this.impuestoTasa = 0.0,
    required this.impuestoMonto,
  });

  double get subtotal => cantidad * costoUnitario;
  double get total => subtotal + impuestoMonto;

  double get costoUnitarioConItbis {
    if (cantidad <= 0) return costoUnitario;
    return total / cantidad;
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'cuenta_contable_id': cuentaContableId,
      'descripcion': descripcionGasto ?? productoNombre,
      'presentacion': presentacion,
      'factor_conversion': factorConversion,
      'cantidad': cantidad,
      'costo_unitario': costoUnitario,
      'impuesto_tasa': impuestoTasa,
      'impuesto_monto': impuestoMonto,
    };
  }
}

class NuevaCompraFormState {
  final List<NuevaCompraDetalleItem> detalles;
  final String tipoCompra;
  final DateTime fechaCompra;
  final DateTime? fechaVencimiento;
  final String? proveedorId;
  final String ncf;
  final String numFactura;
  final String notas;
  final int? metodoPagoId;
  final String? referenciaPago;

  /// UUID v4 generado una sola vez al crear/resetear el formulario.
  /// Se envía al backend en cada intento de POST para garantizar idempotencia:
  /// si el servidor ya procesó este key, devuelve la compra existente
  /// sin duplicar ningún registro contable, CxP ni pago.
  final String idempotencyKey;

  NuevaCompraFormState({
    this.detalles = const [],
    this.tipoCompra = 'CONTADO',
    required this.fechaCompra,
    this.fechaVencimiento,
    this.proveedorId,
    this.ncf = '',
    this.numFactura = '',
    this.notas = '',
    this.metodoPagoId,
    this.referenciaPago,
    String? idempotencyKey,
  }) : idempotencyKey = idempotencyKey ?? _uuid.v4();

  double get subtotal => detalles.fold(0, (sum, item) => sum + item.subtotal);

  double get impuestos =>
      detalles.fold(0, (sum, item) => sum + item.impuestoMonto);

  double get total => subtotal + impuestos;

  NuevaCompraFormState copyWith({
    List<NuevaCompraDetalleItem>? detalles,
    String? tipoCompra,
    DateTime? fechaCompra,
    DateTime? fechaVencimiento,
    String? proveedorId,
    bool clearProveedor = false,
    bool clearFechaVencimiento = false,
    String? ncf,
    String? numFactura,
    String? notas,
    int? metodoPagoId,
    bool clearMetodoPago = false,
    String? referenciaPago,
    bool clearReferenciaPago = false,
    // idempotencyKey NO se expone en copyWith para evitar mutaciones accidentales.
    // Solo se renueva explícitamente con clearForm().
  }) {
    return NuevaCompraFormState(
      detalles: detalles ?? this.detalles,
      tipoCompra: tipoCompra ?? this.tipoCompra,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      fechaVencimiento: clearFechaVencimiento
          ? null
          : (fechaVencimiento ?? this.fechaVencimiento),
      proveedorId: clearProveedor ? null : (proveedorId ?? this.proveedorId),
      ncf: ncf ?? this.ncf,
      numFactura: numFactura ?? this.numFactura,
      notas: notas ?? this.notas,
      metodoPagoId: clearMetodoPago
          ? null
          : (metodoPagoId ?? this.metodoPagoId),
      referenciaPago: clearReferenciaPago
          ? null
          : (referenciaPago ?? this.referenciaPago),
      idempotencyKey: idempotencyKey, // mantiene el mismo key en cada copyWith
    );
  }
}

class NuevaCompraFormNotifier extends StateNotifier<NuevaCompraFormState> {
  NuevaCompraFormNotifier()
    : super(NuevaCompraFormState(fechaCompra: DateTime.now()));

  void addDetalle(NuevaCompraDetalleItem detalle) {
    state = state.copyWith(detalles: [...state.detalles, detalle]);
  }

  void updateDetalle(int index, NuevaCompraDetalleItem detalle) {
    final newList = List<NuevaCompraDetalleItem>.from(state.detalles);
    newList[index] = detalle;
    state = state.copyWith(detalles: newList);
  }

  void removeDetalle(int index) {
    final newList = List<NuevaCompraDetalleItem>.from(state.detalles);
    newList.removeAt(index);
    state = state.copyWith(detalles: newList);
  }

  void setProveedor(String? proveedorId) {
    state = state.copyWith(
      proveedorId: proveedorId,
      clearProveedor: proveedorId == null,
    );
  }

  void setTipoCompra(String tipo) {
    state = state.copyWith(tipoCompra: tipo);
  }

  void setFechaCompra(DateTime fecha) {
    state = state.copyWith(fechaCompra: fecha);
  }

  void setFechaVencimiento(DateTime? fecha) {
    state = state.copyWith(
      fechaVencimiento: fecha,
      clearFechaVencimiento: fecha == null,
    );
  }

  void setNcf(String ncf) {
    state = state.copyWith(ncf: ncf);
  }

  void setNumFactura(String numFactura) {
    state = state.copyWith(numFactura: numFactura);
  }

  void setNotas(String notas) {
    state = state.copyWith(notas: notas);
  }

  void setMetodoPago(int? id) {
    state = state.copyWith(metodoPagoId: id, clearMetodoPago: id == null);
  }

  void setReferenciaPago(String? ref) {
    state = state.copyWith(referenciaPago: ref, clearReferenciaPago: ref == null || ref.isEmpty);
  }

  /// Resetea el formulario y genera un NUEVO idempotency_key.
  /// Llamar esto solo al éxito o al descarte intencional del formulario.
  void clearForm() {
    // Al NO pasar idempotencyKey, el constructor generará uno nuevo automáticamente.
    state = NuevaCompraFormState(fechaCompra: DateTime.now());
  }
}

final nuevaCompraFormProvider =
    StateNotifierProvider<NuevaCompraFormNotifier, NuevaCompraFormState>((ref) {
      return NuevaCompraFormNotifier();
    });
