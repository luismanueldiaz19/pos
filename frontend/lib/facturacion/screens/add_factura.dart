import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modulo_cliente/models/cliente.dart';
import '../../modulo_cliente/providers/cliente_admin_provider.dart';
import '../../modulo_producto/models/producto.dart';
import '../../modulo_producto/providers/producto_provider.dart';
import '../../modulo_producto/providers/producto_state.dart';
import '../../utils/helpers.dart';
import '../../model/company.dart';
import '../../providers/auth_provider.dart';
import '../models/factura_item.dart';
import '../providers/facturacion_provider.dart';
import '../services/facturacion_service.dart';
import '../../pedidos/services/pedido_service.dart';
import '../services/printer_service.dart';
import '../widgets/panel_configuracion.dart';
import '../widgets/carrito_lista.dart';
import '../widgets/pago_dialog.dart';
import '../widgets/panel_totales.dart';
import 'widgets/buscador_cliente_dialog.dart';
import '../../repositories/repo_comprobante.dart';
import '../../model/comprobante.dart';
import '../../palletes/app_colors.dart';
import '../../modulo_caja/providers/caja_provider.dart';
import '../../modulo_mesas/models/mesa_model.dart';
import '../../modulo_mesas/providers/mesas_provider.dart';
import '../widgets/seleccionar_mesa_dialog.dart';
import 'apertura_caja_page.dart';

class CrearFacturaPage extends ConsumerStatefulWidget {
  final MesaModel? mesaOrigen;

  const CrearFacturaPage({super.key, this.mesaOrigen});

  @override
  ConsumerState<CrearFacturaPage> createState() => _CrearFacturaPageState();
}

class _CrearFacturaPageState extends ConsumerState<CrearFacturaPage> {
  final ComprobanteRepository _comprobanteRepo = ComprobanteRepository();
  final FacturacionService _facturaService = FacturacionService();
  final PedidoService _pedidoService = PedidoService();
  final ImprimirFacturar _printer = ImprimirFacturar.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Comprobante> _comprobantes = [];
  String _searchQuery = "";
  bool _imprimirAutomaticamente = true;
  MesaModel? _mesaVinculada;

  @override
  void initState() {
    super.initState();
    _mesaVinculada = widget.mesaOrigen;
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarMesaAlCarrito(MesaModel mesa) {
    _mesaVinculada = mesa;
    final items =
        mesa.ordenActiva?.detalles.map((det) {
          return FacturaItem(
            id: (det.productoId ?? 0).toString(),
            descripcion: det.nombreProducto,
            precio: det.precioUnitario,
            cantidad: det.cantidad,
          );
        }).toList() ??
        [];

    ref
        .read(facturacionProvider.notifier)
        .cargarItemsDeMesa(items, nota: 'Mesa: ${mesa.nombre} (${mesa.area})');

    if (mounted) {
      showToast(
        context,
        '🍽️ Comanda de Mesa ${mesa.nombre} cargada al carrito',
        bgColor: Colors.green,
      );
      setState(() {});
    }
  }

  Future<void> _abrirSelectorMesa() async {
    final mesasState = ref.read(mesasProvider);
    await mesasState.fetchMesas(silent: true);

    if (!mounted) return;
    final seleccionada = await showDialog<MesaModel>(
      context: context,
      builder: (_) => SeleccionarMesaDialog(mesas: mesasState.mesas),
    );

    if (seleccionada != null) {
      _cargarMesaAlCarrito(seleccionada);
    }
  }

  Future<void> _handleBarcodeScan(
    String codigo,
    FacturacionNotifier factNotifier,
  ) async {
    if (codigo.trim().isEmpty) return;

    if (codigo.trim().length >= 10 &&
        RegExp(r'^\d+$').hasMatch(codigo.trim())) {
      try {
        final pedido = await _pedidoService.getPedidoByCodigo(codigo.trim());
        if (pedido != null) {
          factNotifier.limpiarCarrito();
          for (var detalle in pedido.detalles) {
            factNotifier.agregarProducto(
              FacturaItem(
                id: detalle.productoId.toString(),
                descripcion: detalle.nombreProducto,
                precio: detalle.precioUnitario,
                cantidad: detalle.cantidad,
              ),
            );
          }
          if (mounted) {
            showToast(
              context,
              'Pedido #${pedido.secuenciaDiaria} cargado',
              bgColor: Colors.green,
            );
            setState(() {
              _searchQuery = '';
              _searchController.clear();
            });
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          showToast(context, 'No se encontró pedido', bgColor: Colors.orange);
        }
      }
    }
  }

  Future<void> _initData() async {
    final auth = ref.read(authProvider);

    // 1. Limpiar o Cargar estado previo según mesa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mesaVinculada != null && _mesaVinculada!.ordenActiva != null) {
        _cargarMesaAlCarrito(_mesaVinculada!);
      } else {
        ref.read(facturacionProvider.notifier).resetState();
      }
    });

    // 2. Cargar comprobantes (Solo una vez al entrar)
    final results = await _comprobanteRepo.getComprabante(auth.token!);
    final validSalesNcf = results.where((c) {
      // 31: Crédito Fiscal, 32: Consumo, 44: Régimen Especial, 45: Gubernamental, 46: Exportaciones
      return [
        '31',
        '32',
        '44',
        '45',
        '46',
      ].contains(c.tipo.replaceAll(RegExp(r'[^0-9]'), ''));
    }).toList();
    setState(() => _comprobantes = validSalesNcf);

    // 3. Cargar clientes (Solo una vez al entrar)
    await ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);

    // 4. Cargar productos (Carga inicial con spinner)
    await ref
        .read(productoProvider.notifier)
        .loadProductos(auth.token!, search: '');

    // 5. Aplicar configuraciones por defecto
    _aplicarConfiguracionPorDefecto();
  }

  void _aplicarConfiguracionPorDefecto() {
    // Seleccionar comprobante de consumo por default
    final consumo = _comprobantes
        .where((c) => c.nombre.toLowerCase().contains('consumo'))
        .firstOrNull;
    if (consumo != null) {
      ref.read(facturacionProvider.notifier).seleccionarComprobante(consumo);
    }

    // Seleccionar cliente genérico por default
    final clients = ref.read(clienteAdminProvider).clientes;
    final generico = clients
        .where((c) => c.nombre!.toLowerCase().contains('generico'))
        .firstOrNull;
    if (generico != null) {
      ref.read(facturacionProvider.notifier).seleccionarCliente(generico);
    }
  }

  /// Reinicia la pantalla para la siguiente venta sin volver a pedir todo al servidor
  Future<void> _resetParaSiguienteVenta() async {
    final auth = ref.read(authProvider);

    // 1. Resetear el estado del proveedor (limpia carrito, etc)
    ref.read(facturacionProvider.notifier).resetState();

    // 2. Volver a aplicar cliente y comprobante por defecto (usando los datos ya cargados)
    _aplicarConfiguracionPorDefecto();

    // 3. Opcional: Actualizar stock de productos en segundo plano (silencioso)
    ref
        .read(productoProvider.notifier)
        .loadProductos(auth.token!, silent: true, search: '');
  }

  Future<void> _procesarVenta() async {
    final state = ref.read(facturacionProvider);
    final auth = ref.read(authProvider);

    if (state.clienteSeleccionado == null ||
        state.comprobanteSeleccionado == null) {
      showToast(
        context,
        'Seleccione cliente y comprobante',
        bgColor: Colors.orange,
      );
      return;
    }

    if (state.carrito.isEmpty) {
      showToast(context, 'El carrito está vacío', bgColor: Colors.orange);
      return;
    }

    // 🖨️ VERIFICACIÓN DE IMPRESORA
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    if (mounted) {
      Navigator.pop(context); // cerrar loader
    }

    Map<String, dynamic>? pagoInfo;
    bool imprimirTicket = _imprimirAutomaticamente;

    // Si es al contado, pedir el pago primero
    if (state.tipoFactura == 'contado') {
      pagoInfo = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PagoDialog(
          total: state.totales.total,
          initialImprimir: _imprimirAutomaticamente,
        ),
      );

      // Si cancela el diálogo, no procesar factura
      if (pagoInfo == null) return;

      imprimirTicket = pagoInfo['imprimir_factura'] ?? _imprimirAutomaticamente;
    }

    final result = await _facturaService.crearFactura(
      cliente: state.clienteSeleccionado!,
      comprobante: state.comprobanteSeleccionado!,
      items: state.carrito,
      token: auth.token!,
      userId: auth.user!.id!,
      tipoFactura: state.tipoFactura,
      diasCredito: state.diasCredito,
      nota: state.nota,
      pago: pagoInfo,
    );

    if (result['success'] && mounted) {
      // 🖨️ Imprimir ticket en impresora térmica USB si está activado
      if (imprimirTicket) {
        _imprimirTicket(state, result['data'], pagoInfo);
      }

      // Si la factura provino de una mesa, liberarla en el salón
      if (_mesaVinculada != null) {
        final mesaId = _mesaVinculada!.id;
        final mesaNombre = _mesaVinculada!.nombre;
        _mesaVinculada = null;
        try {
          await ref.read(mesasProvider).liberarMesa(mesaId, porFactura: true);
          if (mounted) {
            showToast(
              context,
              'Factura procesada y Mesa $mesaNombre liberada',
              bgColor: Colors.green,
            );
          }
        } catch (_) {}
      } else {
        showToast(context, 'Factura creada con éxito', bgColor: Colors.green);
      }

      // Resetear para la siguiente venta
      _resetParaSiguienteVenta();
    } else if (mounted) {
      showToast(context, result['message'], bgColor: Colors.red);
    }
  }

  /// Imprime el ticket de la factura recién creada.
  /// Se ejecuta de forma asíncrona sin bloquear la UI.
  Future<void> _imprimirTicket(
    FacturacionState state,
    Map<String, dynamic>? facturaData,
    Map<String, dynamic>? pagoInfo,
  ) async {
    final resultado = await _printer.imprimirFactura(
      nombreNegocio: Company.current.nombre,
      direccion: Company.current.direccionCompleta,
      rncOCedula: Company.current.rnc,
      numeroFactura: facturaData?['factura_id']?.toString() ?? 'S/N',
      ncf: facturaData?['ncf']?.toString(),
      fecha: DateTime.now(),
      items: state.carrito
          .map(
            (item) => ItemFactura(
              descripcion: item.descripcion,
              cantidad: item.cantidad,
              precioUnitario: item.precio,
              itbis: item.montoItbis,
              unidadMedida: 'UND',
            ),
          )
          .toList(),
      subtotal: state.totales.subtotal,
      impuesto: state.totales.itbis,
      descuento: state.totales.descuento,
      total: state.totales.total,
      cliente: state.clienteSeleccionado?.nombre,
      rncCliente: state.clienteSeleccionado?.rncCedula,
      nota: state.nota.isNotEmpty ? state.nota : null,
      tipoPago: state.tipoFactura == 'contado' ? 'CONTADO' : 'CREDITO',
      metodoPago: pagoInfo?['metodo_pago']?.toString().toUpperCase(),
      montoRecibido: double.tryParse(pagoInfo?['monto_recibido']?.toString() ?? ''),
      devuelta: double.tryParse(pagoInfo?['devuelta']?.toString() ?? ''),
      qrUrl: facturaData?['qr_url']?.toString(),
      codigoSeguridad: facturaData?['codigo_seguridad']?.toString(),
      fechaFirma: facturaData?['fecha_hora_firma']?.toString(),
      cajero: ref.read(authProvider).user?.name ?? 'Cajera',
      modoTemporalVenta: true,
    );

    if (!resultado.exito && mounted) {
      // Aviso no bloqueante — la factura ya se guardó en el servidor
      showToast(
        context,
        '🖨️ ${resultado.mensaje}',
        bgColor: Colors.orange.shade700,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final factState = ref.watch(facturacionProvider);
    final factNotifier = ref.read(facturacionProvider.notifier);
    final clienteState = ref.watch(clienteAdminProvider);
    final prodState = ref.watch(productoProvider);
    final cajaState = ref.watch(cajaProvider);

    if (cajaState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (cajaState.sesionActiva == null) {
      return const AperturaCajaPage();
    }

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vender',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
              ),
            ),
            Text(
              '${cajaState.sesionActiva?['caja']?['nombre'] ?? '...'} | ${cajaState.sesionActiva?['turno']?['nombre'] ?? '...'}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 8),
          // 🍽️ Indicador o botón selector de Mesa
          if (_mesaVinculada != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepOrange.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.table_restaurant_rounded,
                    size: 15,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Mesa: ${_mesaVinculada!.nombre}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() => _mesaVinculada = null);
                      factNotifier.limpiarCarrito();
                      showToast(context, 'Mesa desvinculada del cobro');
                    },
                    child: const Icon(
                      Icons.close,
                      size: 13,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            _buildCircleButton(
              icon: Icons.table_restaurant_rounded,
              color: Colors.deepOrange,
              tooltip: 'Cargar Comanda de Mesa',
              onTap: _abrirSelectorMesa,
            ),
            const SizedBox(width: 6),
          ],
          // 🖨️ Botón toggle de impresión automática
          _buildCircleButton(
            icon: _imprimirAutomaticamente ? Icons.print : Icons.print_disabled,
            color: _imprimirAutomaticamente ? Colors.teal : Colors.grey,
            tooltip: _imprimirAutomaticamente
                ? 'Impresión Automática: ON'
                : 'Impresión Automática: OFF',
            onTap: () {
              setState(() {
                _imprimirAutomaticamente = !_imprimirAutomaticamente;
              });
              showToast(
                context,
                _imprimirAutomaticamente
                    ? 'Impresión automática ACTIVADA'
                    : 'Impresión automática DESACTIVADA',
                bgColor: _imprimirAutomaticamente
                    ? Colors.teal
                    : Colors.grey.shade700,
              );
            },
          ),
          const SizedBox(width: 8),
          // 🖨️ Botón de prueba de impresora
          // _buildCircleButton(
          //   icon: Icons.receipt_long_outlined,
          //   color: Colors.blueAccent,
          //   tooltip: 'Probar Impresora',
          //   onTap: () async {
          //     final resultado = await _printer.imprimirFactura();

          //     if (mounted) {
          //       showToast(
          //         context,
          //         resultado.mensaje,
          //         bgColor: resultado.exito
          //             ? Colors.teal
          //             : Colors.orange.shade700,
          //       );
          //     }
          //   },
          // ),
          const SizedBox(width: 8),
          _buildCircleButton(
            icon: Icons.delete_sweep_outlined,
            color: Colors.redAccent,
            onTap: () => factNotifier.limpiarCarrito(),
            tooltip: 'Limpiar Carrito',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📋 PANEL IZQUIERDO: CONFIGURACIÓN
          SizedBox(
            width: 260,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: PanelConfiguracion(
                cliente: factState.clienteSeleccionado,
                comprobante: factState.comprobanteSeleccionado,
                comprobantes: _comprobantes,
                tipoFactura: factState.tipoFactura,
                diasCredito: factState.diasCredito,
                nota: factState.nota,
                onSelectCliente: () async {
                  final cliente = await showDialog<Cliente>(
                    context: context,
                    builder: (ctx) =>
                        BuscadorClienteDialog(clientes: clienteState.clientes),
                  );
                  if (cliente != null) {
                    factNotifier.seleccionarCliente(cliente);
                  }
                },
                onSelectComprobante: (c) =>
                    factNotifier.seleccionarComprobante(c!),
                onCambiarTipo: factNotifier.cambiarTipoFactura,
                onCambiarDias: factNotifier.cambiarDiasCredito,
                onCambiarNota: factNotifier.cambiarNota,
              ),
            ),
          ),

          // 🍕 PANEL CENTRAL: CATÁLOGO
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildProductCatalog(prodState, factNotifier),
            ),
          ),

          // 🛒 PANEL DERECHO: CARRITO Y TOTALES
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CarritoLista(
                        items: factState.carrito,
                        onUpdateCantidad: factNotifier.actualizarCantidad,
                        onRemove: factNotifier.removerProducto,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PanelTotales(
                    totales: factState.totales,
                    isLoading: factState.isLoading,
                    carrito: factState.carrito,
                    onProcesar: _procesarVenta,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCatalog(
    ProductoState prodState,
    FacturacionNotifier factNotifier,
  ) {
    if (prodState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    String normalize(String text) => text.trim().toLowerCase();

    final normalizeQuery = normalize(_searchQuery.toString());

    final filteredProducts = prodState.productos.where((p) {
      if (p.tipoProducto == 'MATERIA_PRIMA') return false;
      final name = p.nombre;
      return normalize(name ?? '').contains(normalizeQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onSubmitted: (v) => _handleBarcodeScan(v, factNotifier),
                    decoration: const InputDecoration(
                      hintText:
                          'Buscar producto o escanear ticket de pedido...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13),
                      icon: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.filter_list,
                color: AppColors.secondary,
                onTap: () {},
                tooltip: 'Filtrar',
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final prod = filteredProducts[index];
                    return _buildProductCard(prod, factNotifier);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Producto prod, FacturacionNotifier factNotifier) {
    final bool controlaStock = prod.manejaInventario ?? false;
    final double stock = prod.stockActual ?? 0;
    final double stockMin = prod.stockMinimo ?? 0;

    Color stockColor = AppColors.success;
    if (controlaStock) {
      if (stock <= 0) {
        stockColor = Colors.redAccent;
      } else if (stock <= stockMin) {
        stockColor = Colors.orange.shade700;
      }
    }

    return Tooltip(
      message: prod.nombre ?? '',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () {
          factNotifier.agregarProducto(
            FacturaItem(
              id: prod.id.toString(),
              descripcion: prod.nombre ?? 'Sin nombre',
              precio: prod.precioVenta ?? 0,
              itbisPorcentaje: prod.impuesto?.tasa ?? 0.0,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fastfood_outlined,
                      size: 28,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 28,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          prod.nombre ?? 'Sin nombre',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.18,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              FormatterNumber.formatCurrency(
                                prod.precioVenta ?? 0,
                              ),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                        if (controlaStock) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message:
                                'Stock disponible: ${FormatterNumber.formatNumber(stock)}',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: stockColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'S: ${FormatterNumber.formatNumber(stock)}',
                                style: TextStyle(
                                  color: stockColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 32, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Text(
            'No se encontraron productos',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
