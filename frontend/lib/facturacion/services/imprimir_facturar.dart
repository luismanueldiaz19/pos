import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:intl/intl.dart';

import '../../model/company.dart';
import 'printer_service.dart';

/// Servicio especializado exclusivamente para la impresión de tickets de facturas.
///
/// Encapsula el formato visual del ticket de venta (plantilla Factura_efc.png),
/// el manejo de metadatos fiscales/temporales, el envío de bytes ESC/POS,
/// y la generación automática de doble ticket (Original + Copia para cuadre de caja)
/// cuando la venta se realiza con tarjeta o transferencia.
class ImprimirFacturar {
  ImprimirFacturar._();
  static final ImprimirFacturar instance = ImprimirFacturar._();

  static final _numberFormat = NumberFormat('#,##0.00', 'en_US');
  static final _cantFormat = NumberFormat('#,##0.##', 'en_US');

  /// Imprime el ticket de una factura térmica de 80mm.
  ///
  /// - Por defecto [modoTemporalVenta] = true aplica el formato ligero sin NCF
  ///   ni QR solicitado para la venta ágil.
  /// - Si [modoTemporalVenta] = false aplica el formato fiscal completo (e-CF con QR DGII).
  /// - Si la venta es con Tarjeta o Transferencia bancaria (o si [imprimirCopia] = true),
  ///   se imprimen automáticamente 2 tickets (Original para cliente y Copia para cuadre de caja).
  Future<ResultadoImpresora> imprimirFactura({
    required String nombreNegocio,
    required String direccion,
    required String rncOCedula,
    required String numeroFactura,
    String? ncf,
    required DateTime fecha,
    required List<ItemFactura> items,
    required double subtotal,
    required double impuesto,
    required double descuento,
    required double total,
    String? cliente,
    String? rncCliente,
    String? nota,
    String? tipoPago,
    String? metodoPago,
    double? montoRecibido,
    double? devuelta,
    String? qrUrl,
    String? codigoSeguridad,
    String? fechaFirma,
    String? cajero,
    bool modoTemporalVenta = true,
    bool? imprimirCopia,
    bool esCopia = false,
    bool abrirCajon = false,
    Printer? printer,
  }) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 2);
      List<int> bytes = [];

      // Determinar si corresponde imprimir copia para la cajera (cuadre de caja)
      final bool debeImprimirCopia =
          !esCopia && (imprimirCopia ?? _requiereCopia(metodoPago, tipoPago));

      // ── APERTURA DE CAJÓN DE DINERO (UNA SOLA VEZ AL INICIO) ─────────
      // Solo en el primer ticket/impresión inicial, NUNCA en la copia para evitar doble apertura.
      if (abrirCajon && !esCopia) {
        bytes += [
          0x1B, 0x70, 0x00, 0x19, 0xFA, // Pin 2 (m=0, 50ms ON, 500ms OFF)
          0x1B, 0x70, 0x01, 0x19, 0xFA, // Pin 5 (m=1, 50ms ON, 500ms OFF)
        ];
      }

      // ── TICKET 1: ORIGINAL (para el cliente) ──────────────────────
      bytes += generator.reset();
      bytes += _generarBytesTicket(
        generator: generator,
        nombreNegocio: nombreNegocio,
        direccion: direccion,
        rncOCedula: rncOCedula,
        numeroFactura: numeroFactura,
        ncf: ncf,
        fecha: fecha,
        items: items,
        subtotal: subtotal,
        impuesto: impuesto,
        descuento: descuento,
        total: total,
        cliente: cliente,
        rncCliente: rncCliente,
        nota: nota,
        tipoPago: tipoPago,
        metodoPago: metodoPago,
        montoRecibido: montoRecibido,
        devuelta: devuelta,
        qrUrl: qrUrl,
        codigoSeguridad: codigoSeguridad,
        fechaFirma: fechaFirma,
        cajero: cajero,
        modoTemporalVenta: modoTemporalVenta,
        esCopia: esCopia,
      );
      bytes += generator.cut();

      // ── TICKET 2: COPIA PARA CUADRE DE CAJA (Tarjeta o Transferencia) ──
      if (debeImprimirCopia) {
        bytes += generator.reset();
        bytes += _generarBytesTicket(
          generator: generator,
          nombreNegocio: nombreNegocio,
          direccion: direccion,
          rncOCedula: rncOCedula,
          numeroFactura: numeroFactura,
          ncf: ncf,
          fecha: fecha,
          items: items,
          subtotal: subtotal,
          impuesto: impuesto,
          descuento: descuento,
          total: total,
          cliente: cliente,
          rncCliente: rncCliente,
          nota: nota,
          tipoPago: tipoPago,
          metodoPago: metodoPago,
          montoRecibido: montoRecibido,
          devuelta: devuelta,
          qrUrl: qrUrl,
          codigoSeguridad: codigoSeguridad,
          fechaFirma: fechaFirma,
          cajero: cajero,
          modoTemporalVenta: modoTemporalVenta,
          esCopia: true,
        );
        bytes += generator.cut();
      }

      // Enviar bytes a la impresora mediante el servicio centralizado
      return await ThermalPrinterService.instance.printBytes(
        bytes,
        printer: printer,
      );
    } catch (e) {
      return ResultadoImpresora(exito: false, mensaje: 'Error al imprimir: $e');
    }
  }

  /// Construye la lista de bytes ESC/POS de un ticket individual (Original o Copia).
  List<int> _generarBytesTicket({
    required Generator generator,
    required String nombreNegocio,
    required String direccion,
    required String rncOCedula,
    required String numeroFactura,
    String? ncf,
    required DateTime fecha,
    required List<ItemFactura> items,
    required double subtotal,
    required double impuesto,
    required double descuento,
    required double total,
    String? cliente,
    String? rncCliente,
    String? nota,
    String? tipoPago,
    String? metodoPago,
    double? montoRecibido,
    double? devuelta,
    String? qrUrl,
    String? codigoSeguridad,
    String? fechaFirma,
    String? cajero,
    required bool modoTemporalVenta,
    required bool esCopia,
  }) {
    final nombreLimpio = _limpiarTexto(nombreNegocio.toUpperCase());
    final direccionLimpia = _limpiarTexto('C.E.P.F');
    // final direccionLimpia = _limpiarTexto(direccion);
    final clienteLimpio = _limpiarTexto(cliente ?? 'Consumidor Final');

    List<int> bytes = [];

    if (modoTemporalVenta) {
      // ── ENCABEZADO TEMPORAL ───────────────────────────────────────
      if (esCopia) {
        bytes += generator.text(
          '*** COPIA CAJA ***',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );
        bytes += generator.emptyLines(1);
      }

      bytes += generator.text(
        '----- Factura -----',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      if (direccionLimpia.isNotEmpty) {
        bytes += generator.text(
          direccionLimpia,
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.hr(ch: '-');

      // ── METADATOS DE LA FACTURA ──────────────────────────────────
      bytes += generator.text(
        'Fecha Emision: ${_formatFecha(fecha)}',
        styles: const PosStyles(align: PosAlign.left),
      );

      if (cajero != null && cajero.isNotEmpty) {
        bytes += generator.text(
          'Cajera       : ${_limpiarTexto(cajero)}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      bytes += generator.text(
        'Cliente      : $clienteLimpio',
        styles: const PosStyles(align: PosAlign.left),
      );

      if (rncCliente != null &&
          rncCliente.isNotEmpty &&
          !RegExp(r'^0+$').hasMatch(rncCliente.replaceAll('-', ''))) {
        bytes += generator.text(
          'RNC/Cedula   : $rncCliente',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      final String condicionPago = (metodoPago != null && metodoPago.isNotEmpty)
          ? '${tipoPago ?? "CONTADO"} ($metodoPago)'
          : (tipoPago ?? "CONTADO");
      bytes += generator.text(
        'Tipo de Pago : $condicionPago',
        styles: const PosStyles(align: PosAlign.left),
      );

      bytes += generator.text(
        'Factura No.  : $numeroFactura',
        styles: const PosStyles(align: PosAlign.left),
      );

      if (nota != null && nota.isNotEmpty) {
        bytes += generator.text(
          'Nota         : ${_limpiarTexto(nota)}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      // ── ENCABEZADO DE ITEMS (1 SOLA LÍNEA) ────────────────────────
      // Ancho exacto 48 columnas (80mm): Cant (5) | Detalle (21) | ITBIS (10) | Total (12)
      bytes += generator.hr(ch: '-');

      String buildHeaderLine() {
        return 'Cant'.padRight(5) +
            'Detalle'.padRight(21) +
            'ITBIS'.padLeft(10) +
            'Total'.padLeft(12);
      }

      bytes += generator.text(
        buildHeaderLine(),
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.hr(ch: '-');

      // ── DETALLE DE ITEMS (TODO EN UNA SOLA LÍNEA) ─────────────────
      for (final item in items) {
        final cantStr = _fmtCant(item.cantidad);
        final descLimpia = _limpiarTexto(item.descripcion);
        final descLines = _wrapTexto(descLimpia, 21);

        final itbisStr = _fmtNumero(item.itbis);
        final pTotStr = _fmtNumero(item.total);

        // Renglón del producto en una sola línea
        final line =
            cantStr.padRight(5) +
            descLines[0].padRight(21) +
            itbisStr.padLeft(10) +
            pTotStr.padLeft(12);
        bytes += generator.text(
          line,
          styles: const PosStyles(align: PosAlign.left),
        );

        // Si el nombre del producto es extenso, continúa debajo en la columna Detalle
        for (int i = 1; i < descLines.length; i++) {
          final extraLine =
              ''.padRight(5) +
              descLines[i].padRight(21) +
              ''.padLeft(10) +
              ''.padLeft(12);
          bytes += generator.text(
            extraLine,
            styles: const PosStyles(align: PosAlign.left),
          );
        }
      }
      bytes += generator.hr(ch: '-');

      // ── TOTALES ───────────────────────────────────────────────────
      String buildTotalRow(String label, String value) {
        return label.padRight(28) + value.padLeft(20);
      }

      bytes += generator.text(
        buildTotalRow('Subtotal Gravado:', _fmtMoneda(subtotal)),
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        buildTotalRow('Total ITBIS:', _fmtMoneda(impuesto)),
        styles: const PosStyles(align: PosAlign.left),
      );

      if (descuento > 0) {
        bytes += generator.text(
          buildTotalRow('Descuento:', '-${_fmtMoneda(descuento)}'),
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      // Total en tamaño estándar y negrita (sin distorsión)
      bytes += generator.text(
        buildTotalRow('TOTAL:', _fmtMoneda(total)),
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.hr(ch: '-');

      // ── PAGO Y CAMBIO (DEVUELTA) ───────────────────────────────────
      final double? efectivoRecibido = montoRecibido;
      final double cambioEfectivo = (devuelta != null && devuelta > 0)
          ? devuelta
          : ((efectivoRecibido != null && efectivoRecibido > total)
                ? (efectivoRecibido - total)
                : 0.0);

      if (efectivoRecibido != null || cambioEfectivo > 0) {
        final String etiquetaMetodo =
            (metodoPago != null && metodoPago.isNotEmpty)
            ? '${metodoPago.toUpperCase()}:'
            : 'EFECTIVO:';

        if (efectivoRecibido != null) {
          bytes += generator.text(
            buildTotalRow(etiquetaMetodo, _fmtMoneda(efectivoRecibido)),
            styles: const PosStyles(align: PosAlign.left),
          );
        }

        if (cambioEfectivo > 0) {
          bytes += generator.text(
            buildTotalRow('CAMBIO:', _fmtMoneda(cambioEfectivo)),
            styles: const PosStyles(align: PosAlign.left, bold: true),
          );
        }
        bytes += generator.hr(ch: '-');
      }

      // ── PIE DE TICKET (DIFERENCIADO SEGÚN ORIGINAL O COPIA) ───────
      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'Referencia: FAC-$numeroFactura',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.emptyLines(1);

      if (esCopia) {
        // En la copia para cuadre de caja: línea de firma y sello de copia
        bytes += generator.text(
          'Firma Cliente: ________________________________',
          styles: const PosStyles(align: PosAlign.left),
        );
        bytes += generator.emptyLines(1);
        bytes += generator.text(
          '*** COPIA EXCLUSIVA PARA CUADRE DE CAJA ***',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
      } else {
        // En el original para el cliente: agradecimiento
        bytes += generator.text(
          '*** ¡GRACIAS POR SU COMPRA! ***',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
      }

      bytes += generator.emptyLines(1);
      bytes += generator.text(
        SystemInfo.ticketCredit,
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );
      bytes += generator.emptyLines(2);
    } else {
      // ── FORMATO FISCAL ESTÁNDAR (CON e-CF, NCF Y TIMBRE QR DGII) ──
      if (esCopia) {
        bytes += generator.text(
          '*** COPIA CAJA ***',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );
        bytes += generator.emptyLines(1);
      }

      bytes += generator.text(
        nombreLimpio,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        direccionLimpia,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Tel.: ${Company.current.telefono}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'RNC: $rncOCedula',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(1);

      bytes += generator.text(
        'Fecha: ${_formatFecha(fecha)}',
        styles: const PosStyles(align: PosAlign.left),
      );

      final String tipoDoc = _resolverTituloComprobante(ncf, rncCliente);
      bytes += generator.text(
        tipoDoc,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );

      final bool esEcf =
          ncf != null && ncf.toUpperCase().startsWith('E') && ncf != 'S/N';

      if (ncf != null && ncf.isNotEmpty && ncf != 'S/N') {
        bytes += generator.text(
          esEcf ? 'e-NCF: $ncf' : 'NCF: $ncf',
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
      }

      bytes += generator.text(
        'Factura No. : $numeroFactura',
        styles: const PosStyles(align: PosAlign.left),
      );
      if (rncCliente != null &&
          rncCliente.isNotEmpty &&
          !RegExp(r'^0+$').hasMatch(rncCliente.replaceAll('-', ''))) {
        bytes += generator.text(
          'RNC Cliente : $rncCliente',
          styles: const PosStyles(align: PosAlign.left),
        );
      }
      bytes += generator.text(
        'Cliente     : $clienteLimpio',
        styles: const PosStyles(align: PosAlign.left),
      );

      final String condicionPago = (metodoPago != null && metodoPago.isNotEmpty)
          ? '${tipoPago ?? "CONTADO"} ($metodoPago)'
          : (tipoPago ?? "CONTADO");
      bytes += generator.text(
        'Condicion   : $condicionPago',
        styles: const PosStyles(align: PosAlign.left),
      );

      if (nota != null && nota.isNotEmpty) {
        bytes += generator.text(
          'Nota        : ${_limpiarTexto(nota)}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      bytes += generator.hr(ch: '-');

      // Items en formato estándar
      for (final item in items) {
        final cant = _fmtCant(item.cantidad);
        final desc = _truncate(_limpiarTexto(item.descripcion), 20);
        final pUnit = _fmtNumero(item.precioUnitario);
        final pTot = _fmtNumero(item.total);

        bytes += generator.text(
          '$cant x $desc'.padRight(28) + pTot.padLeft(20),
          styles: const PosStyles(align: PosAlign.left),
        );
        if (item.cantidad > 1 || item.itbis > 0) {
          final itbisInfo = item.itbis > 0
              ? ' (ITBIS: ${_fmtMoneda(item.itbis)})'
              : '';
          bytes += generator.text(
            '  @ RD\$ $pUnit c/u$itbisInfo',
            styles: const PosStyles(
              align: PosAlign.left,
              fontType: PosFontType.fontB,
            ),
          );
        }
      }
      bytes += generator.hr(ch: '-');

      // Totales estándar
      String buildTotalRow(String label, String value) {
        return label.padLeft(28) + value.padLeft(20);
      }

      bytes += generator.text(
        buildTotalRow('Subtotal', _fmtMoneda(subtotal)),
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.text(
        buildTotalRow('ITBIS', _fmtMoneda(impuesto)),
        styles: const PosStyles(align: PosAlign.left),
      );

      if (descuento > 0) {
        bytes += generator.text(
          buildTotalRow('Descuento', '-${_fmtMoneda(descuento)}'),
          styles: const PosStyles(align: PosAlign.left),
        );
      }

      bytes += generator.text(
        buildTotalRow('TOTAL:', _fmtMoneda(total)),
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.hr(ch: '=');

      if (metodoPago != null || montoRecibido != null) {
        if (metodoPago != null && montoRecibido != null) {
          bytes += generator.text(
            buildTotalRow(metodoPago.toUpperCase(), _fmtMoneda(montoRecibido)),
            styles: const PosStyles(align: PosAlign.left),
          );
        }
        if (devuelta != null && devuelta > 0) {
          bytes += generator.text(
            buildTotalRow('Cambio', _fmtMoneda(devuelta)),
            styles: const PosStyles(align: PosAlign.left),
          );
        }
        bytes += generator.hr(ch: '=');
      }

      if (esEcf || (qrUrl != null && qrUrl.isNotEmpty)) {
        bytes += generator.emptyLines(1);

        final rncLimpio = rncOCedula.replaceAll(RegExp(r'[^0-9]'), '');
        final effectiveQr = (qrUrl != null && qrUrl.isNotEmpty)
            ? qrUrl
            : 'https://fc.dgii.gov.do/TesteCF/ConsultaTimbreFC?RncEmisor=$rncLimpio&ENCF=${ncf ?? numeroFactura}&MontoTotal=${total.toStringAsFixed(2)}&CodigoSeguridad=${codigoSeguridad ?? "PENDTE"}';

        bytes += generator.qrcode(effectiveQr);

        if (codigoSeguridad != null && codigoSeguridad.isNotEmpty) {
          bytes += generator.text(
            'Codigo de Seguridad: $codigoSeguridad',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        bytes += generator.text(
          'Fecha de Firma Digital: ${fechaFirma ?? _formatFecha(fecha)}',
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      bytes += generator.emptyLines(1);

      if (esCopia) {
        bytes += generator.text(
          'Firma: _________________________________________',
          styles: const PosStyles(align: PosAlign.left),
        );
        bytes += generator.emptyLines(1);
        bytes += generator.text(
          '*** COPIA PARA CUADRE DE CAJA ***',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
      } else {
        bytes += generator.text(
          'Revise su orden antes de retirarse. Para cualquier reclamo es indispensable presentar esta factura. No se devuelve efectivo.',
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      bytes += generator.emptyLines(1);
      bytes += generator.text(
        SystemInfo.ticketCredit,
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );

      bytes += generator.emptyLines(2);
    }

    return bytes;
  }

  // ─────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ─────────────────────────────────────────────

  /// Verifica si el método o tipo de pago requiere copia para cuadre de caja
  bool _requiereCopia(String? metodo, String? tipo) {
    final m = (metodo ?? '').toLowerCase();
    final t = (tipo ?? '').toLowerCase();
    return m.contains('tarjeta') ||
        m.contains('card') ||
        m.contains('transferencia') ||
        m.contains('transfer') ||
        t.contains('tarjeta') ||
        t.contains('transferencia');
  }

  String _resolverTituloComprobante(String? ncf, String? rncCliente) {
    final upper = (ncf ?? '').toUpperCase();
    if (upper.startsWith('E31')) return 'Factura de Credito Fiscal Electronica';
    if (upper.startsWith('E32')) return 'Factura de Consumo Electronica';
    if (upper.startsWith('E33')) return 'Nota de Debito Electronica';
    if (upper.startsWith('E34')) return 'Nota de Credito Electronica';
    if (upper.startsWith('E44')) return 'Regimenes Especiales Electronico';
    if (upper.startsWith('E45')) return 'Comprobante Gubernamental Electronico';
    if (upper.startsWith('E46')) return 'Comprobante Exportaciones Electronico';

    return (rncCliente != null &&
            rncCliente.replaceAll('-', '').length >= 9 &&
            !RegExp(r'^0+$').hasMatch(rncCliente.replaceAll('-', '')))
        ? 'Factura de Credito Fiscal'
        : 'Factura de Consumo';
  }

  String _formatFecha(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} $h:$m';
  }

  String _fmtMoneda(double v) => 'RD\$ ${_numberFormat.format(v)}';
  String _fmtNumero(double v) => _numberFormat.format(v);
  String _fmtCant(double v) => _cantFormat.format(v);

  List<String> _wrapTexto(String text, int maxLineLength) {
    if (text.isEmpty) return [''];
    if (text.length <= maxLineLength) return [text];

    final words = text.split(RegExp(r'\s+'));
    final List<String> lines = [];
    String currentLine = '';

    for (final word in words) {
      if (word.isEmpty) continue;
      if (currentLine.isEmpty) {
        if (word.length > maxLineLength) {
          lines.add(word.substring(0, maxLineLength));
          currentLine = word.substring(maxLineLength);
        } else {
          currentLine = word;
        }
      } else if ('$currentLine $word'.length <= maxLineLength) {
        currentLine = '$currentLine $word';
      } else {
        lines.add(currentLine);
        if (word.length > maxLineLength) {
          lines.add(word.substring(0, maxLineLength));
          currentLine = word.substring(maxLineLength);
        } else {
          currentLine = word;
        }
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines.isEmpty ? [text] : lines;
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max - 2)}..' : s;

  String _limpiarTexto(String text) {
    if (text.isEmpty) return text;
    const conAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÑñ';
    const sinAcento = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuNn';
    String res = text;
    for (int i = 0; i < conAcento.length; i++) {
      res = res.replaceAll(conAcento[i], sinAcento[i]);
    }
    return res;
  }
}

// Aliases para máxima compatibilidad de nombres
typedef ImprimirFacturaService = ImprimirFacturar;
typedef ImprimirFacturarService = ImprimirFacturar;
