import 'dart:convert';

import 'package:sistema_restaurante/model/detalle.dart';
import 'package:sistema_restaurante/model/user.dart';

import '../modulo_cliente/models/cliente.dart';
import '../modulo_dgii/models/ecf_models.dart';

List<Factura> facturaFromJson(String str) =>
    List<Factura>.from(json.decode(str).map((x) => Factura.fromJson(x)));

String facturaToJson(List<Factura> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Factura {
  final int? id;
  final int? ncfSecuenciaId;
  final int? clienteId;
  final String? ncf;
  final String? tipoFactura;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final String? subtotal;
  final String? descuentoTotal;
  final String? itbis;
  final String? total;
  final String? estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? userId;
  final Cliente? cliente;
  final List<Detalle>? detalles;
  final User? user;
  final EcfSummary? ecfDocumento;
  final List<PagoFactura>? pagos;

  Factura({
    this.id,
    this.clienteId,
    this.ncfSecuenciaId,
    this.ncf,
    this.tipoFactura,
    this.fechaEmision,
    this.fechaVencimiento,
    this.subtotal,
    this.descuentoTotal,
    this.itbis,
    this.total,
    this.estado,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.cliente,
    this.detalles,
    this.user,
    this.ecfDocumento,
    this.pagos,
  });

  Factura copyWith({
    int? id,
    int? clienteId,
    String? ncf,
    String? tipoFactura,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    String? subtotal,
    String? descuentoTotal,
    String? itbis,
    String? total,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? userId,
    Cliente? cliente,
    List<Detalle>? detalles,
    User? user,
    EcfSummary? ecfDocumento,
    List<PagoFactura>? pagos,
  }) => Factura(
    id: id ?? this.id,
    clienteId: clienteId ?? this.clienteId,
    ncf: ncf ?? this.ncf,
    tipoFactura: tipoFactura ?? this.tipoFactura,
    fechaEmision: fechaEmision ?? this.fechaEmision,
    fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
    subtotal: subtotal ?? this.subtotal,
    descuentoTotal: descuentoTotal ?? this.descuentoTotal,
    itbis: itbis ?? this.itbis,
    total: total ?? this.total,
    estado: estado ?? this.estado,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userId: userId ?? this.userId,
    cliente: cliente ?? this.cliente,
    detalles: detalles ?? this.detalles,
    user: user ?? this.user,
    ecfDocumento: ecfDocumento ?? this.ecfDocumento,
    pagos: pagos ?? this.pagos,
  );

  String get metodoPagoNombre {
    if (pagos != null && pagos!.isNotEmpty) {
      final metodos = pagos!
          .map((p) => p.metodoPago?.trim().toUpperCase())
          .where((m) => m != null && m.isNotEmpty)
          .cast<String>()
          .toSet();
      if (metodos.isNotEmpty) {
        return metodos.join(', ');
      }
    }
    if (estado?.toLowerCase() == 'pendiente') {
      return 'PENDIENTE';
    }
    return (tipoFactura != null && tipoFactura!.isNotEmpty)
        ? tipoFactura!.toUpperCase()
        : 'EFECTIVO';
  }

  factory Factura.fromJson(Map<String, dynamic> json) => Factura(
    id: json["id"],
    clienteId: json["cliente_id"],
    ncfSecuenciaId: json['ncf_secuencia_id'],
    ncf: json["ncf"],
    tipoFactura: json["tipo_factura"],
    fechaEmision: json["fecha_emision"] != null
        ? DateTime.parse(json["fecha_emision"])
        : null,
    fechaVencimiento: json["fecha_vencimiento"] != null
        ? DateTime.parse(json["fecha_vencimiento"])
        : null,
    subtotal: json["subtotal"]?.toString(),
    descuentoTotal: json["descuento_total"]?.toString(),
    itbis: json["itbis"]?.toString(),
    total: json["total"]?.toString(),
    estado: json["estado"],
    createdAt: json["created_at"] != null
        ? DateTime.parse(json["created_at"])
        : null,
    updatedAt: json["updated_at"] != null
        ? DateTime.parse(json["updated_at"])
        : null,
    userId: json["user_id"],
    cliente: json["cliente"] != null
        ? Cliente.fromJson(json["cliente"])
        : null,
    detalles: json["detalles"] != null
        ? List<Detalle>.from(json["detalles"].map((x) => Detalle.fromJson(x)))
        : [],
    user: json["user"] != null ? User.fromJson(json["user"]) : null,
    ecfDocumento: json["ecf_documento"] != null
        ? EcfSummary.fromJson(Map<String, dynamic>.from(json["ecf_documento"]))
        : null,
    pagos: json["pagos"] != null
        ? List<PagoFactura>.from(
            (json["pagos"] as List).map((x) => PagoFactura.fromJson(x)),
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "cliente_id": clienteId,
    "ncf": ncf,
    "ncf_secuencia_id": ncfSecuenciaId,
    "tipo_factura": tipoFactura,
    "fecha_emision":
        "${fechaEmision?.year.toString().padLeft(4, '0')}-${fechaEmision?.month.toString().padLeft(2, '0')}-${fechaEmision?.day.toString().padLeft(2, '0')}",
    "fecha_vencimiento":
        "${fechaVencimiento?.year.toString().padLeft(4, '0')}-${fechaVencimiento?.month.toString().padLeft(2, '0')}-${fechaVencimiento?.day.toString().padLeft(2, '0')}",
    "subtotal": subtotal,
    "descuento_total": descuentoTotal,
    "itbis": itbis,
    "total": total,
    "estado": estado,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "user_id": userId,
    "cliente": cliente?.toJson(),
    "detalles": List<dynamic>.from((detalles ?? []).map((x) => x.toJson())),
    "user": user?.toJson(),
    "ecf_documento": ecfDocumento?.toJson(),
    "pagos": pagos != null
        ? List<dynamic>.from(pagos!.map((x) => x.toJson()))
        : null,
  };
}

class PagoFactura {
  final int? id;
  final String? metodoPago;
  final String? montoPagado;
  final String? montoRecibido;
  final String? devuelta;
  final String? referenciaPago;

  PagoFactura({
    this.id,
    this.metodoPago,
    this.montoPagado,
    this.montoRecibido,
    this.devuelta,
    this.referenciaPago,
  });

  factory PagoFactura.fromJson(Map<String, dynamic> json) => PagoFactura(
        id: json["id"],
        metodoPago: json["metodo_pago"]?.toString(),
        montoPagado: json["monto_pagado"]?.toString(),
        montoRecibido: json["monto_recibido"]?.toString(),
        devuelta: json["devuelta"]?.toString(),
        referenciaPago: json["referencia_pago"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "metodo_pago": metodoPago,
        "monto_pagado": montoPagado,
        "monto_recibido": montoRecibido,
        "devuelta": devuelta,
        "referencia_pago": referenciaPago,
      };
}
