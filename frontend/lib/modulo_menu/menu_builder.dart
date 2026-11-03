import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importaciones de estado y widgets de navegación
import 'package:sistema_restaurante/providers/auth_state.dart';
import 'package:sistema_restaurante/widgets/custom_sidebar.dart';

// Módulo 1: Ventas & Front-Office
import 'package:sistema_restaurante/modulo_mesas/screens/mesas_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/add_factura.dart';
import 'package:sistema_restaurante/facturacion/screens/gestion_documentos_screen.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/crear_cotizacion_screen.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/historial_cotizaciones_screen.dart';
import 'package:sistema_restaurante/modulo_caja/screens/apertura_caja_screen.dart';
import 'package:sistema_restaurante/modulo_caja/widgets/cierre_caja_dialog.dart';
import 'package:sistema_restaurante/facturacion/screens/historial_caja_screen.dart';

// Módulo 2: Clientes y Proveedores (Contactos)
import 'package:sistema_restaurante/modulo_cliente/screens/screen_client_admin.dart';
import 'package:sistema_restaurante/modulo_compras/screens/proveedores_screen.dart';

// Módulo 3: Inventario & Almacén
import 'package:sistema_restaurante/modulo_producto/screens/screen_productos.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_catalogo_base.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_movimientos_inventario.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_recetas.dart';
import 'package:sistema_restaurante/modulo_compras/screens/nueva_compra_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/compras_list_screen.dart';
import 'package:sistema_restaurante/modulo_ordenes_compra/screens/crear_orden_compra_screen.dart';
import 'package:sistema_restaurante/modulo_ordenes_compra/screens/historial_ordenes_compra_screen.dart';

// Módulo 4: Finanzas & Contabilidad (Back-Office)
import 'package:sistema_restaurante/modulo_finanzas/screens/bancos_dashboard_screen.dart';
import 'package:sistema_restaurante/modulo_cxc/screens/cxc_list_screen.dart';
import 'package:sistema_restaurante/modulo_cxc/screens/historial_pagos_cxc_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/cxp_list_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/historial_pagos_cxp_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/registrar_gasto_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/gastos_list_screen.dart';
import 'package:sistema_restaurante/modulo_contabilidad/screens/catalogo_cuentas_screen.dart';
import 'package:sistema_restaurante/screens/libro_diario_screen.dart';
import 'package:sistema_restaurante/modulo_contabilidad/screens/mayor_general_screen.dart';
import 'package:sistema_restaurante/screens/configuracion_contable_screen.dart';

// Módulo 5: Reportes, Fiscal & Sistema
import 'package:sistema_restaurante/modulo_contabilidad/screens/balance_general_screen.dart';
import 'package:sistema_restaurante/modulo_contabilidad/screens/estado_resultados_screen.dart';
import 'package:sistema_restaurante/modulo_contabilidad/screens/estado_resultados_tabla_screen.dart';
import 'package:sistema_restaurante/modulo_dgii/screens/ecf_dashboard_screen.dart';
import 'package:sistema_restaurante/modulo_dgii/screens/dgii_dashboard_screen.dart';
import 'package:sistema_restaurante/modulo_dgii/screens/ncf_secuencias_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/nomina_dashboard_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/empleado_list_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/add_nomina_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/providers/nomina_provider.dart';
import 'package:sistema_restaurante/screens/usuarios/usuarios_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/metodos_pago_screen.dart';
import 'package:sistema_restaurante/screens/profile_screen.dart';

class MenuBuilder {
  /// Limpia encabezados huérfanos que no tengan elementos interactivos subsiguientes
  static List<SidebarSubItem> _cleanSubItems(List<SidebarSubItem> raw) {
    final List<SidebarSubItem> cleaned = [];
    SidebarSubItem? pendingHeader;

    for (final item in raw) {
      if (item.isHeader) {
        pendingHeader = item;
      } else {
        if (pendingHeader != null) {
          cleaned.add(pendingHeader);
          pendingHeader = null;
        }
        cleaned.add(item);
      }
    }
    return cleaned;
  }

  /// Retorna la lista estructurada de [SidebarItem] organizada bajo los 5 pilares estándar ERP.
  static List<SidebarItem> buildMenu({
    required BuildContext context,
    required AuthState auth,
    required WidgetRef ref,
    required VoidCallback onDashboardTap,
  }) {
    final bool isAdmin = auth.roles.contains('admin');
    final bool isContador = auth.roles.contains('contador');
    final bool isCajero = auth.roles.any((r) => r.toLowerCase() == 'cajero');
    final bool isAuxContable = auth.roles.contains('auxiliar contable');

    final List<SidebarItem> menu = [];

    // ==========================================
    // 0. DASHBOARD PRINCIPAL
    // ==========================================
    menu.add(
      SidebarItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        onTap: onDashboardTap,
      ),
    );

    // ==========================================
    // 1. VENTAS (Comercial / Front-Office)
    // ==========================================
    final List<SidebarSubItem> ventasRaw = [
      SidebarSubItem.header('Punto de Venta & Salón'),
      if (auth.hasPermission('ver_facturas') || isCajero || isAdmin)
        SidebarSubItem(
          title: 'Punto de Venta (Mesas)',
          icon: Icons.table_restaurant_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MesasScreen()),
          ),
        ),
      if (auth.hasPermission('crear_facturas') || isAdmin)
        SidebarSubItem(
          title: 'Facturación Estándar',
          icon: Icons.add_shopping_cart_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearFacturaPage()),
          ),
        ),
      if (auth.hasPermission('ver_facturas') || isAdmin)
        SidebarSubItem(
          title: 'Historial de Facturas',
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GestionDocumentosScreen()),
          ),
        ),

      SidebarSubItem.header('Cotizaciones & Pedidos'),
      if (!isCajero && (auth.hasPermission('crear_facturas') || isAdmin))
        SidebarSubItem(
          title: 'Nueva Cotización',
          icon: Icons.note_add_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearCotizacionScreen()),
          ),
        ),
      if (!isCajero && (auth.hasPermission('ver_facturas') || isAdmin))
        SidebarSubItem(
          title: 'Historial de Cotizaciones',
          icon: Icons.history_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistorialCotizacionesScreen()),
          ),
        ),

      SidebarSubItem.header('Control de Turnos POS'),
      if (auth.hasPermission('gestionar_caja') || isAdmin || isCajero) ...[
        SidebarSubItem(
          title: 'Apertura de Caja',
          icon: Icons.lock_open_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AperturaCajaScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Cierre de Turno',
          icon: Icons.lock_clock_outlined,
          onTap: () => CierreCajaDialog.show(context, ref),
        ),
        SidebarSubItem(
          title: 'Movimientos de Caja',
          icon: Icons.payments_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistorialCajaScreen()),
          ),
        ),
      ],
    ];

    final ventasCleaned = _cleanSubItems(ventasRaw);
    if (ventasCleaned.isNotEmpty) {
      menu.add(
        SidebarItem(
          title: '1. Ventas',
          icon: Icons.point_of_sale_outlined,
          subItems: ventasCleaned,
        ),
      );
    }

    // ==========================================
    // 2. CLIENTES Y PROVEEDORES (Contactos)
    // ==========================================
    final List<SidebarSubItem> contactosRaw = [
      SidebarSubItem.header('Clientes'),
      if (auth.hasPermission('ver_clientes') || isAdmin || isCajero)
        SidebarSubItem(
          title: 'Directorio de Clientes',
          icon: Icons.person_search_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenClientAdmin()),
          ),
        ),

      SidebarSubItem.header('Proveedores (Suplidores)'),
      if (!isCajero &&
          (auth.hasPermission('ver_proveedores') ||
              auth.hasPermission('ver_compras') ||
              isAdmin))
        SidebarSubItem(
          title: 'Directorio de Proveedores',
          icon: Icons.local_shipping_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProveedoresScreen()),
          ),
        ),
    ];

    final contactosCleaned = _cleanSubItems(contactosRaw);
    if (contactosCleaned.isNotEmpty) {
      menu.add(
        SidebarItem(
          title: '2. Contactos',
          icon: Icons.people_alt_outlined,
          subItems: contactosCleaned,
        ),
      );
    }

    // ==========================================
    // 3. INVENTARIO (Almacén y Productos)
    // ==========================================
    final List<SidebarSubItem> inventarioRaw = [
      SidebarSubItem.header('Catálogo & Stock'),
      if (!isCajero &&
          (auth.hasPermission('ver_productos') ||
              auth.hasPermission('ver_inventario') ||
              isAdmin))
        SidebarSubItem(
          title: 'Productos y Servicios',
          icon: Icons.inventory_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenProductos()),
          ),
        ),
      if (!isCajero && (auth.hasPermission('ver_inventario') || isAdmin)) ...[
        SidebarSubItem(
          title: 'Kardex & Movimientos',
          icon: Icons.swap_vert_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenMovimientosInventario()),
          ),
        ),
        SidebarSubItem(
          title: 'Ajustes de Inventario',
          icon: Icons.tune_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenMovimientosInventario()),
          ),
        ),
        SidebarSubItem(
          title: 'Recetas & Producción',
          icon: Icons.menu_book_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScreenRecetas()),
          ),
        ),
      ],

      SidebarSubItem.header('Clasificación'),
      if (!isCajero && (auth.hasPermission('ver_inventario') || isAdmin)) ...[
        SidebarSubItem(
          title: 'Categorías',
          icon: Icons.category_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScreenCatalogoBase(
                titulo: 'Categorías',
                endpoint: 'categorias',
              ),
            ),
          ),
        ),
        SidebarSubItem(
          title: 'Marcas',
          icon: Icons.branding_watermark_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScreenCatalogoBase(
                titulo: 'Marcas',
                endpoint: 'marcas',
              ),
            ),
          ),
        ),
        SidebarSubItem(
          title: 'Unidades de Medida',
          icon: Icons.straighten_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScreenCatalogoBase(
                titulo: 'Unidades de Medida',
                endpoint: 'unidades-medida',
              ),
            ),
          ),
        ),
      ],

      SidebarSubItem.header('Compras de Mercancía'),
      if (!isCajero && (auth.hasPermission('ver_compras') || isAdmin)) ...[
        SidebarSubItem(
          title: 'Nueva Compra (Recepción)',
          icon: Icons.add_business_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevaCompraScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Historial de Compras',
          icon: Icons.shopping_bag_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComprasListScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Nueva Orden de Compra',
          icon: Icons.post_add_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearOrdenCompraScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Órdenes de Compra',
          icon: Icons.assignment_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HistorialOrdenesCompraScreen(),
            ),
          ),
        ),
      ],
    ];

    final inventarioCleaned = _cleanSubItems(inventarioRaw);
    if (inventarioCleaned.isNotEmpty) {
      menu.add(
        SidebarItem(
          title: '3. Inventario',
          icon: Icons.inventory_2_outlined,
          subItems: inventarioCleaned,
        ),
      );
    }

    // ==========================================
    // 4. FINANZAS Y CONTABILIDAD (Tesorería & Back-Office)
    // ==========================================
    final List<SidebarSubItem> finanzasRaw = [
      SidebarSubItem.header('Tesorería & Cajas'),
      if (!isCajero &&
          (auth.hasPermission('gestionar_caja') || isAdmin || isContador))
        SidebarSubItem(
          title: 'Cuentas Bancarias',
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BancosDashboardScreen()),
          ),
        ),

      SidebarSubItem.header('Cuentas por Cobrar (CxC)'),
      if (!isCajero &&
          (auth.hasPermission('ver_cxc') || isAdmin || isContador)) ...[
        SidebarSubItem(
          title: 'Gestión CxC (Saldos)',
          icon: Icons.request_page_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CxcListScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Historial de Cobros',
          icon: Icons.price_check_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistorialPagosCxcScreen()),
          ),
        ),
      ],

      SidebarSubItem.header('Cuentas por Pagar (CxP)'),
      if (!isCajero &&
          (auth.hasPermission('ver_compras') || isAdmin || isContador)) ...[
        SidebarSubItem(
          title: 'Gestión CxP (Facturas)',
          icon: Icons.receipt_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CxpListScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Historial de Pagos CxP',
          icon: Icons.credit_score_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistorialPagosCxpScreen()),
          ),
        ),
      ],

      SidebarSubItem.header('Gastos Operativos'),
      if (isAdmin || isContador) ...[
        SidebarSubItem(
          title: 'Registrar Gasto',
          icon: Icons.money_off_csred_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegistrarGastoScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Historial de Gastos',
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GastosListScreen()),
          ),
        ),
      ],

      SidebarSubItem.header('Contabilidad General'),
      if (isAdmin || isContador) ...[
        SidebarSubItem(
          title: 'Catálogo de Cuentas',
          icon: Icons.account_tree_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CatalogoCuentasScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Diario General (Pólizas)',
          icon: Icons.auto_stories_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LibroDiarioScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Mayor General',
          icon: Icons.menu_book_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MayorGeneralScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Configuración Contable',
          icon: Icons.settings_suggest_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ConfiguracionContableScreen(),
            ),
          ),
        ),
      ],
    ];

    final finanzasCleaned = _cleanSubItems(finanzasRaw);
    if (finanzasCleaned.isNotEmpty) {
      menu.add(
        SidebarItem(
          title: '4. Finanzas & Contab.',
          icon: Icons.account_balance_outlined,
          subItems: finanzasCleaned,
        ),
      );
    }

    // ==========================================
    // 5. REPORTES Y SISTEMA (Fiscal, RRHH & Configuración)
    // ==========================================
    final List<SidebarSubItem> reportesRaw = [
      SidebarSubItem.header('Reportes Financieros'),
      if (isAdmin || isContador) ...[
        SidebarSubItem(
          title: 'Balance General',
          icon: Icons.balance_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BalanceGeneralScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Estado de Resultados',
          icon: Icons.trending_up_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EstadoResultadosScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Estado de Resultados (Excel)',
          icon: Icons.table_chart_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EstadoResultadosTablaScreen(),
            ),
          ),
        ),
      ],

      SidebarSubItem.header('Fiscal DGII'),
      if (isAdmin || isContador) ...[
        SidebarSubItem(
          title: 'Facturación e-CF',
          icon: Icons.cloud_done_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EcfDashboardScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Impuestos & 606/607',
          icon: Icons.insert_chart_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DgiiDashboardScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Secuencias NCF',
          icon: Icons.confirmation_number_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NcfSecuenciasScreen()),
          ),
        ),
      ],

      SidebarSubItem.header('Recursos Humanos (RRHH)'),
      if (!isCajero &&
          (isAdmin ||
              isContador ||
              isAuxContable ||
              auth.hasPermission('ver_nomina'))) ...[
        SidebarSubItem(
          title: 'Dashboard Nómina',
          icon: Icons.badge_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NominaDashboardScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Directorio Empleados',
          icon: Icons.group_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmpleadoListScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Generar Nómina',
          icon: Icons.post_add_outlined,
          onTap: () async {
            final result = await showDialog(
              context: context,
              builder: (_) => const AddNominaDialog(),
            );
            if (result == true && context.mounted) {
              ref.read(nominaProvider.notifier).fetchHistorial();
            }
          },
        ),
      ],

      SidebarSubItem.header('Configuración & Sistema'),
      if (!isCajero && (auth.hasPermission('gestionar_usuarios') || isAdmin)) ...[
        SidebarSubItem(
          title: 'Usuarios y Roles',
          icon: Icons.manage_accounts_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UsuariosScreen()),
          ),
        ),
        SidebarSubItem(
          title: 'Métodos de Pago',
          icon: Icons.payment_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MetodosPagoScreen()),
          ),
        ),
      ],
      SidebarSubItem(
        title: 'Mi Perfil de Usuario',
        icon: Icons.person_pin_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
    ];

    final reportesCleaned = _cleanSubItems(reportesRaw);
    if (reportesCleaned.isNotEmpty) {
      menu.add(
        SidebarItem(
          title: '5. Reportes & Sistema',
          icon: Icons.tune_outlined,
          subItems: reportesCleaned,
        ),
      );
    }

    return menu;
  }
}
