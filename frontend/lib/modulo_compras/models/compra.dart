import '../../modulo_producto/models/producto.dart';
import '../../model/catalogo_cuenta_model.dart';
import '../../model/user.dart';
import 'proveedor.dart';

class Compra {
  final int id;
  final int proveedorId;
  final Proveedor? proveedor;
  final String numeroFacturaProveedor;
  final String? ncf;
  final User? usuario;
  final DateTime fechaCompra;
  final DateTime? fechaVencimiento;
  final String tipoCompra; // CONTADO, CREDITO
  final double subtotal;
  final double impuestos;
  final double total;
  final String estado; // PENDIENTE, PAGADA, ANULADA
  final String? notas;
  final List<CompraDetalle> detalles;
  final String? pdfUrl;
  final int? asientoId;
  final Map<String, dynamic>? asiento;
  final Map<String, dynamic>? cuentaPorPagar;

  bool get esGasto => detalles.isNotEmpty && detalles.every((d) => d.productoId == null);

  Compra({
    required this.id,
    required this.proveedorId,
    this.proveedor,
    required this.numeroFacturaProveedor,
    this.ncf,
    this.usuario,
    required this.fechaCompra,
    this.fechaVencimiento,
    required this.tipoCompra,
    required this.subtotal,
    required this.impuestos,
    required this.total,
    required this.estado,
    this.notas,
    this.detalles = const [],
    this.pdfUrl,
    this.asientoId,
    this.asiento,
    this.cuentaPorPagar,
  });

  factory Compra.fromJson(Map<String, dynamic> json) {
    return Compra(
      id: json['id'],
      proveedorId: json['proveedor_id'],
      proveedor: json['proveedor'] != null ? Proveedor.fromJson(json['proveedor']) : null,
      numeroFacturaProveedor: json['numero_factura_proveedor'] ?? '',
      ncf: json['ncf'],
      usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
      fechaCompra: DateTime.parse(json['fecha_compra']),
      fechaVencimiento: json['fecha_vencimiento'] != null ? DateTime.parse(json['fecha_vencimiento']) : null,
      tipoCompra: json['tipo_compra'] ?? 'CONTADO',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      impuestos: double.tryParse(json['impuestos']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      estado: json['estado'] ?? 'PENDIENTE',
      notas: json['notas'],
      pdfUrl: json['pdf_url'],
      asientoId: json['asiento_id'],
      asiento: json['asiento'] is Map<String, dynamic> ? json['asiento'] : null,
      cuentaPorPagar: json['cuenta_por_pagar'] is Map<String, dynamic> ? json['cuenta_por_pagar'] : null,
      detalles: json['detalles'] != null
          ? (json['detalles'] as List).map((d) => CompraDetalle.fromJson(d)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proveedor_id': proveedorId,
      'numero_factura_proveedor': numeroFacturaProveedor,
      'ncf': ncf,
      'fecha_compra': fechaCompra.toIso8601String().split('T').first,
      'fecha_vencimiento': fechaVencimiento?.toIso8601String().split('T').first,
      'tipo_compra': tipoCompra,
      'subtotal': subtotal,
      'impuestos': impuestos,
      'total': total,
      'estado': estado,
      'notas': notas,
      'detalles': detalles.map((d) => d.toJson()).toList(),
    };
  }
}

class CompraDetalle {
  final int? id;
  final int? compraId;
  final int? productoId;
  final Producto? producto;
  final String? descripcion;
  final int? cuentaContableId;
  final CatalogoCuentaModel? cuentaContable;
  final double cantidad;
  final double costoUnitario;
  final double subtotal;
  final double impuestoMonto;
  final double total;

  CompraDetalle({
    this.id,
    this.compraId,
    this.productoId,
    this.producto,
    this.descripcion,
    this.cuentaContableId,
    this.cuentaContable,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
    required this.impuestoMonto,
    required this.total,
  });

  factory CompraDetalle.fromJson(Map<String, dynamic> json) {
    return CompraDetalle(
      id: json['id'],
      compraId: json['compra_id'],
      productoId: json['producto_id'],
      producto: json['producto'] != null ? Producto.fromJson(json['producto']) : null,
      descripcion: json['descripcion'],
      cuentaContableId: json['cuenta_contable_id'],
      cuentaContable: json['cuenta_contable'] != null ? CatalogoCuentaModel.fromJson(json['cuenta_contable']) : null,
      cantidad: double.tryParse(json['cantidad']?.toString() ?? '0') ?? 0.0,
      costoUnitario: double.tryParse(json['costo_unitario']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      impuestoMonto: double.tryParse(json['impuesto_monto']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'costo_unitario': costoUnitario,
      'subtotal': subtotal,
      'impuesto_monto': impuestoMonto,
      'total': total,
    };
  }
}
