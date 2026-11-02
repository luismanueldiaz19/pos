import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sistema_restaurante/facturacion/screens/add_factura.dart';
import 'package:sistema_restaurante/modulo_cliente/screens/screen_client_admin.dart';
import 'package:sistema_restaurante/modulo_producto/screens/screen_productos.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/crear_cotizacion_screen.dart';
import 'package:sistema_restaurante/modulo_cotizaciones/screens/historial_cotizaciones_screen.dart';
import 'package:sistema_restaurante/modulo_ordenes_compra/screens/crear_orden_compra_screen.dart';
import 'package:sistema_restaurante/modulo_ordenes_compra/screens/historial_ordenes_compra_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/cxp_list_screen.dart';
import 'package:sistema_restaurante/modulo_compras/screens/registrar_gasto_screen.dart';
import 'package:sistema_restaurante/modulo_cxc/screens/cxc_list_screen.dart';
import 'package:sistema_restaurante/pedidos/screens/pedidos_screen.dart';
import 'package:sistema_restaurante/widgets/custom_confirm_dialog.dart';
import 'package:sistema_restaurante/widgets/custom_sidebar.dart';
import '../facturacion/screens/historial_ventas_screen.dart';
import '../modulo_cliente/providers/cliente_admin_provider.dart';
import '../modulo_mesas/screens/mesas_screen.dart';
import '../modulo_caja/providers/caja_provider.dart';
import '../modulo_caja/widgets/cierre_caja_dialog.dart';
import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import '../modulo_menu/menu_builder.dart';
import 'dashboard_buttons_section/dashboard_buttons_section.dart';
import 'login_page.dart';
import '../modulo_ai/screens/chat_ia_screen.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});
  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _handleLogout() async {
    final bool? confirm = await CustomConfirmDialog.show(
      context,
      title: 'Salir de la sección',
      message:
          '¿Estás seguro que deseas cerrar sesión? Perderás el acceso hasta que vuelvas a ingresar.',
      confirmText: 'Salir',
      cancelText: 'Volver',
      icon: Icons.logout_rounded,
      primaryColor: Colors.redAccent,
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _handleCierreCaja(BuildContext context, WidgetRef ref) async {
    await CierreCajaDialog.show(context, ref);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.token != null) {
        ref.read(clienteAdminProvider.notifier).loadClients(auth.token!);
        ref.read(cajaProvider.notifier).checkEstado(auth.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    // Definición de Menús Dinámica externalizada
    final menuItems = MenuBuilder.buildMenu(
      context: context,
      auth: auth,
      ref: ref,
      onDashboardTap: () => setState(() => _selectedIndex = 0),
    );

    return Scaffold(
      key: scaffoldKey,
      drawer: !isDesktop
          ? CustomSidebar(
              selectedIndex: _selectedIndex,
              items: menuItems,
              onLogout: _handleLogout,
              userName: auth.user?.name ?? 'Usuario', // 👈 Nombre dinámico
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              },
            )
          : null,
      body: Row(
        children: [
          // 1. Sidebar (Solo en Desktop)
          if (isDesktop)
            CustomSidebar(
              selectedIndex: _selectedIndex,
              items: menuItems,
              onLogout: _handleLogout,
              userName: auth.user?.name ?? 'Usuario', // 👈 Nombre dinámico
              onItemSelected: (index) => setState(() => _selectedIndex = index),
            ),

          // 2. Main Content
          Expanded(
            child: Column(
              children: [
                // Custom Header / AppBar
                _buildHeader(isDesktop, auth),

                // Content Area
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _buildCurrentScreen(auth),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatIaScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          'Meta AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, AuthState auth) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
          Text(
            _getPageTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.azulOscuro,
            ),
          ),
          const Spacer(),
          _buildUserInfo(auth),
        ],
      ),
    );
  }

  Widget _buildUserInfo(AuthState auth) {
    final user = auth.user;
    final String initial = user?.name?.isNotEmpty == true
        ? user!.name![0].toUpperCase()
        : 'U';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Horario
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            final now = DateTime.now();
            final months = [
              'Ene',
              'Feb',
              'Mar',
              'Abr',
              'May',
              'Jun',
              'Jul',
              'Ago',
              'Sep',
              'Oct',
              'Nov',
              'Dic',
            ];
            final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
            final timeStr = DateFormat('hh:mm a').format(now);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 16),
        Container(width: 1, height: 30, color: Colors.grey.shade300),
        const SizedBox(width: 16),
        // Usuario
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              user?.name ?? 'Usuario',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            Text(
              auth.roles.isNotEmpty
                  ? auth.roles.first.toUpperCase()
                  : 'ROL NO DEFINIDO',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Imagen (Inicial del nombre)
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Principal';
      case 1:
        return 'Módulo de Ventas';
      case 2:
        return 'Gestión de Clientes';
      case 3:
        return 'Inventario y Stock';
      case 4:
        return 'Reportes Generales';
      default:
        return appName;
    }
  }

  Widget _buildCurrentScreen(AuthState auth) {
    if (_selectedIndex == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Parte Superior (Botones de Acceso Rápido)
            Expanded(
              child: SingleChildScrollView(
                child: DashboardButtonsSection(
                  onAction: (action) {
                    switch (action) {
                      case 'mesas':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MesasScreen(),
                          ),
                        );
                        break;
                      case 'venta':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrearFacturaPage(),
                          ),
                        );
                        break;
                      case 'historial_ventas':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistorialVentasScreen(),
                          ),
                        );
                        break;
                      case 'pedidos':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PedidosScreen(),
                          ),
                        );
                        break;
                      case 'clientes':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScreenClientAdmin(),
                          ),
                        );
                        break;
                      case 'productos':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScreenProductos(),
                          ),
                        );
                        break;
                      case 'crear_cotizacion':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrearCotizacionScreen(),
                          ),
                        );
                        break;
                      case 'ver_cotizaciones':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistorialCotizacionesScreen(),
                          ),
                        );
                        break;
                      case 'crear_orden_compra':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CrearOrdenCompraScreen(),
                          ),
                        );
                        break;
                      case 'ver_ordenes_compra':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const HistorialOrdenesCompraScreen(),
                          ),
                        );
                        break;
                      case 'ver_cxp':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CxpListScreen(),
                          ),
                        );
                        break;
                      case 'ver_cxc':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CxcListScreen(),
                          ),
                        );
                        break;
                      case 'registrar_gasto':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistrarGastoScreen(),
                          ),
                        );
                        break;
                      default:
                        showToast(
                          context,
                          'Módulo en desarrollo',
                          bgColor: Colors.blueGrey,
                        );
                    }
                  },
                ),
              ),
            ),

            // 2. Separador y Sección de Caja (Siempre abajo y Horizontal)
            if (auth.hasPermission('ver_facturas')) ...[
              const Divider(height: 20, thickness: 0.1),
              Consumer(
                builder: (context, ref, _) {
                  final cajaState = ref.watch(cajaProvider);
                  final session = cajaState.sesionActiva;
                  final bool isCajaAbierta = session != null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Información de Caja',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.azulOscuro,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (isCajaAbierta)
                            ElevatedButton.icon(
                              onPressed: () => _handleCierreCaja(context, ref),
                              icon: const Icon(
                                Icons.lock_clock_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'CERRAR CAJA',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildInfoCard(
                              title: 'Estado de Caja',
                              value: isCajaAbierta ? 'ABIERTA' : 'CERRADA',
                              subtitle: isCajaAbierta
                                  ? 'Desde: ${session['fecha_apertura']}'
                                  : 'No hay turno activo',
                              icon: isCajaAbierta
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                              color: isCajaAbierta ? Colors.green : Colors.grey,
                              width: 220,
                            ),
                            const SizedBox(width: 20),
                            if (isCajaAbierta) ...[
                              _buildInfoCard(
                                title: 'Fondo Inicial',
                                value: 'RD\$ ${session['monto_inicial']}',
                                subtitle: 'Base en efectivo',
                                icon: Icons.account_balance_wallet_rounded,
                                color: Colors.blue,
                                width: 220,
                              ),
                              const SizedBox(width: 20),
                              _buildInfoCard(
                                title: 'Cajero Responsable',
                                value: auth.user?.name ?? 'N/A',
                                subtitle: 'Sesión ID: #${session['id']}',
                                icon: Icons.person_rounded,
                                color: Colors.orange,
                                width: 220,
                              ),
                            ] else
                              _buildInfoCard(
                                title: 'Aviso',
                                value: 'Requiere Apertura',
                                subtitle: 'Inicie turno para facturar',
                                icon: Icons.info_outline,
                                color: Colors.red,
                                width: 220,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Text(
        'Pantalla en Desarrollo: ${_getPageTitle()}',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return FadeInRight(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.azulOscuro,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}


