import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importaciones de paquetes y utilidades locales
import 'package:sistema_restaurante/providers/auth_state.dart';
import 'package:sistema_restaurante/widgets/custom_sidebar.dart';

// Importaciones de pantallas y dialogos
import 'package:sistema_restaurante/screens/profile_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/add_factura.dart';
// import 'package:sistema_restaurante/pedidos/screens/pedidos_screen.dart';
// import 'package:sistema_restaurante/pedidos/screens/add_pedido.dart';
// import 'package:sistema_restaurante/pedidos/providers/pedidos_provider.dart';
import 'package:sistema_restaurante/modulo_mesas/screens/mesas_screen.dart';
import 'package:sistema_restaurante/modulo_cliente/screens/screen_client_admin.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_productos.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_recetas.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_catalogo_base.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_movimientos_inventario.dart';
import 'package:sistema_restaurante/modulo_compras/screens/nueva_compra_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/compras_list_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/proveedores_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/cxp_list_screen.dart';
import '../modulo_compras/screens/historial_pagos_cxp_screen.dart';
import '../modulo_compras/screens/registrar_gasto_screen.dart';
import '../modulo_compras/screens/gastos_list_screen.dart';
import '../modulo_cxc/screens/cxc_list_screen.dart';
import '../modulo_cxc/screens/historial_pagos_cxc_screen.dart';
import '../modulo_finanzas/screens/bancos_dashboard_screen.dart';
import '../modulo_contabilidad/screens/mayor_general_screen.dart';
import '../modulo_contabilidad/screens/balance_general_screen.dart';
import '../modulo_contabilidad/screens/estado_resultados_screen.dart';
import '../modulo_contabilidad/screens/estado_resultados_tabla_screen.dart';
import '../modulo_contabilidad/screens/catalogo_cuentas_screen.dart';
import '../facturacion/screens/metodos_pago_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/historial_caja_screen.dart';
import 'package:sistema_restaurante/modulo_caja/screens/apertura_caja_screen.dart';
import 'package:sistema_restaurante/modulo_caja/widgets/cierre_caja_dialog.dart';
import 'package:sistema_restaurante/screens/libro_diario_screen.dart';
import 'package:sistema_restaurante/screens/configuracion_contable_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/nomina_dashboard_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/empleado_list_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/screens/add_nomina_screen.dart';
import 'package:sistema_restaurante/modulo_nomina/providers/nomina_provider.dart';
import 'package:sistema_restaurante/modulo_dgii/screens/dgii_dashboard_screen.dart';
import 'package:sistema_restaurante/modulo_dgii/screens/ecf_dashboard_screen.dart';
import 'package:sistema_restaurante/modulo_dgii/screens/ncf_secuencias_screen.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/crear_cotizacion_screen.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/historial_cotizaciones_screen.dart';
import 'package:sistema_restaurante/facturacion/screens/gestion_documentos_screen.dart';

class MenuBuilder {
  /// Retorna la lista de [SidebarItem] basada en la estructura de módulos de negocio y los permisos del usuario.
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

    return [
      // 1. DASHBOARD
      SidebarItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        onTap: onDashboardTap,
      ),

      // 2. MESAS (Top / Salón)
      SidebarItem(
        title: 'Mesas',
        icon: Icons.table_restaurant_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MesasScreen()),
        ),
      ),

      // MI PERFIL (Conservado para facilidad de acceso)
      SidebarItem(
        title: 'Mi Perfil',
        icon: Icons.person_pin_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),

      // 3. PEDIDOS
      // SidebarItem(
      //   title: 'Pedidos',
      //   icon: Icons.restaurant_menu_rounded,
      //   subItems: [
      //     SidebarSubItem(
      //       title: 'Nuevo Pedido',
      //       onTap: () async {
      //         final result = await Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (_) => const CrearPedidoPage()),
      //         );
      //         if (result == true) {
      //           ref.read(pedidosProvider).fetchPedidos();
      //         }
      //       },
      //     ),
      //     SidebarSubItem(s
      //       title: 'Gestión de Pedidos',
      //       onTap: () => Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (_) => const PedidosScreen()),
      //       ),
      //     ),
      //   ],
      // ),

      // 3. VENTAS
      if (auth.hasPermission('ver_facturas') ||
          auth.hasPermission('ver_clientes') ||
          isAdmin)
        SidebarItem(
          title: 'Ventas',
          icon: Icons.point_of_sale_outlined,
          subItems: [
            if (auth.hasPermission('crear_facturas') || isAdmin)
              SidebarSubItem(
                title: 'Nueva Venta',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearFacturaPage()),
                ),
              ),
            if (auth.hasPermission('ver_facturas') || isAdmin)
              SidebarSubItem(
                title: 'Facturas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GestionDocumentosScreen(),
                  ),
                ),
              ),
            if (auth.hasPermission('ver_clientes') || isAdmin)
              SidebarSubItem(
                title: 'Clientes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenClientAdmin()),
                ),
              ),
          ],
        ),

      // 4. COTIZACIONES
      if (!isCajero &&
          (auth.hasPermission('ver_facturas') ||
              auth.hasPermission('crear_facturas') ||
              isAdmin))
        SidebarItem(
          title: 'Cotizaciones',
          icon: Icons.request_quote_outlined,
          subItems: [
            if (auth.hasPermission('crear_facturas') || isAdmin)
              SidebarSubItem(
                title: 'Nueva Cotización',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CrearCotizacionScreen(),
                  ),
                ),
              ),
            if (auth.hasPermission('ver_facturas') || isAdmin)
              SidebarSubItem(
                title: 'Historial de Cotizaciones',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialCotizacionesScreen(),
                  ),
                ),
              ),
          ],
        ),

      // 5. INVENTARIO
      if (!isCajero &&
          (auth.hasPermission('ver_inventario') ||
              auth.hasPermission('ver_productos') ||
              isAdmin))
        SidebarItem(
          title: 'Inventario',
          icon: Icons.inventory_2_outlined,
          subItems: [
            if (auth.hasPermission('ver_productos') ||
                auth.hasPermission('ver_inventario') ||
                isAdmin)
              SidebarSubItem(
                title: 'Productos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenProductos()),
                ),
              ),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(
                title: 'Categorías',
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
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(
                title: 'Marcas',
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
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(
                title: 'Unid. Medida',
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
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(
                title: 'Kardex & Existencias',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScreenMovimientosInventario(),
                  ),
                ),
              ),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(
                title: 'Ajustes de Inventario',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScreenMovimientosInventario(),
                  ),
                ),
              ),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(title: 'Transferencias', onTap: () {}),
            if (auth.hasPermission('ver_inventario') || isAdmin)
              SidebarSubItem(
                title: 'Recetas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreenRecetas()),
                ),
              ),
          ],
        ),

      // 6. COMPRAS
      if (!isCajero &&
          (auth.hasPermission('ver_compras') ||
              auth.hasPermission('ver_proveedores') ||
              isAdmin))
        SidebarItem(
          title: 'Compras',
          icon: Icons.shopping_bag_outlined,
          subItems: [
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Nueva Compra',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevaCompraScreen()),
                ),
              ),
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Historial de Compras',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComprasListScreen()),
                ),
              ),
            if (auth.hasPermission('ver_proveedores') || isAdmin)
              SidebarSubItem(
                title: 'Proveedores',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProveedoresScreen()),
                ),
              ),
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Cuentas por Pagar',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CxpListScreen()),
                ),
              ),
            if (auth.hasPermission('ver_compras') || isAdmin)
              SidebarSubItem(
                title: 'Pagos Realizados',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialPagosCxpScreen(),
                  ),
                ),
              ),
          ],
        ),

      // 7. FINANZAS
      if (auth.hasPermission('gestionar_caja') ||
          auth.hasPermission('ver_cxc') ||
          auth.hasPermission('ver_gastos') ||
          isAdmin ||
          isCajero ||
          isContador)
        SidebarItem(
          title: 'Finanzas',
          icon: Icons.monetization_on_outlined,
          subItems: [
            if (auth.hasPermission('gestionar_caja') ||
                isAdmin ||
                isCajero) ...[
              SidebarSubItem(
                title: 'Apertura de Caja',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AperturaCajaScreen()),
                ),
              ),
              SidebarSubItem(
                title: 'Cierre de Caja',
                onTap: () => CierreCajaDialog.show(context, ref),
              ),
              SidebarSubItem(
                title: 'Movimientos de Caja',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistorialCajaScreen(),
                  ),
                ),
              ),
            ],
            if (!isCajero)
              SidebarSubItem(
                title: 'Bancos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BancosDashboardScreen(),
                    ),
                  );
                },
              ),
            if (!isCajero &&
                (auth.hasPermission('ver_cxc') || isAdmin || isContador))
              SidebarSubItem(
                title: 'Cuentas por Cobrar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CxcListScreen()),
                  );
                },
              ),
            if (!isCajero &&
                (auth.hasPermission('ver_cxc') || isAdmin || isContador))
              SidebarSubItem(
                title: 'Historial de Cobros',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistorialPagosCxcScreen(),
                    ),
                  );
                },
              ),
            if (isAdmin || isContador) ...[
              SidebarSubItem(
                title: 'Gestión de Gastos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GastosListScreen(),
                    ),
                  );
                },
              ),
              SidebarSubItem(
                title: 'Registrar Gasto',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegistrarGastoScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),

      // 8. CONTABILIDAD
      if (isAdmin || isContador)
        SidebarItem(
          title: 'Contabilidad',
          icon: Icons.account_balance_rounded,
          subItems: [
            SidebarSubItem(
              title: 'Catálogo de Cuentas',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CatalogoCuentasScreen(),
                ),
              ),
            ),
            SidebarSubItem(
              title: 'Configuración Contable',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConfiguracionContableScreen(),
                ),
              ),
            ),
            SidebarSubItem(
              title: 'Diario General',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibroDiarioScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Mayor General',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MayorGeneralScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Balance General',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BalanceGeneralScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Estado de Resultados',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EstadoResultadosScreen(),
                ),
              ),
            ),
            SidebarSubItem(
              title: 'Estado de Resultados (Excel)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EstadoResultadosTablaScreen(),
                ),
              ),
            ),
          ],
        ),

      // 9. RRHH
      if (!isCajero &&
          (isAdmin ||
              isContador ||
              isAuxContable ||
              auth.hasPermission('ver_nomina')))
        SidebarItem(
          title: 'RRHH',
          icon: Icons.people_outline,
          subItems: [
            SidebarSubItem(
              title: 'Dashboard Nómina',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NominaDashboardScreen(),
                ),
              ),
            ),
            SidebarSubItem(
              title: 'Empleados',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmpleadoListScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Generar Nómina',
              onTap: () async {
                final result = await showDialog(
                  context: context,
                  builder: (_) => const AddNominaDialog(),
                );
                // Si se generó con éxito, recargar historial
                if (result == true && context.mounted) {
                  ref.read(nominaProvider.notifier).fetchHistorial();
                }
              },
            ),
            SidebarSubItem(title: 'Vacaciones', onTap: () {}),
            SidebarSubItem(title: 'Asistencia', onTap: () {}),
          ],
        ),

      // 10. DGII
      if (isAdmin || isContador)
        SidebarItem(
          title: 'DGII',
          icon: Icons.receipt_outlined,
          subItems: [
            SidebarSubItem(
              title: 'e-CF (Electrónica)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EcfDashboardScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'Impuestos & 606/607',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DgiiDashboardScreen()),
              ),
            ),
            SidebarSubItem(
              title: 'NCF',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NcfSecuenciasScreen()),
              ),
            ),
          ],
        ),

      // // 9. REPORTES
      // if (!isCajero &&
      //     (auth.hasPermission('ver_reportes') || isAdmin || isContador))
      //   SidebarItem(
      //     title: 'Reportes',
      //     icon: Icons.bar_chart_outlined,
      //     subItems: [
      //       SidebarSubItem(
      //         title: 'Ventas',
      //         onTap: () => Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (_) => const ReporteVentasScreen()),
      //         ),
      //       ),
      //       SidebarSubItem(title: 'Compras', onTap: () {}),
      //       SidebarSubItem(title: 'Inventario', onTap: () {}),
      //       SidebarSubItem(title: 'Finanzas', onTap: () {}),
      //       SidebarSubItem(title: 'RRHH', onTap: () {}),
      //       SidebarSubItem(title: 'Contabilidad', onTap: () {}),
      //     ],
      //   ),

      // 10. ADMINISTRACION
      if (!isCajero && (auth.hasPermission('gestionar_usuarios') || isAdmin))
        SidebarItem(
          title: 'Administración',
          icon: Icons.settings_outlined,
          subItems: [
            SidebarSubItem(title: 'Usuarios', onTap: () {}),
            SidebarSubItem(title: 'Roles', onTap: () {}),
            SidebarSubItem(
              title: 'Métodos de Pago',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MetodosPagoScreen()),
              ),
            ),
            SidebarSubItem(title: 'Permisos', onTap: () {}),
            SidebarSubItem(title: 'Configuración', onTap: () {}),
            SidebarSubItem(title: 'Auditoría', onTap: () {}),
          ],
        ),
    ];
  }
}
