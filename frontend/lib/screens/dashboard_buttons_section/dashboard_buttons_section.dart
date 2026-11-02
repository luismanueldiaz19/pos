import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/dashboard_button.dart';

class DashboardButtonsSection extends ConsumerWidget {
  final void Function(String action) onAction;

  const DashboardButtonsSection({super.key, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isCajero = auth.roles.any((r) => r.toLowerCase() == 'cajero');

    final items = [
      if (auth.hasPermission('crear_facturas'))
        DashboardButton(
          title: 'Mesas',
          icon: Icons.table_restaurant_rounded,
          color: const Color(0xFFE65100),
          onTap: () => onAction('mesas'),
        ),
      if (auth.hasPermission('crear_facturas'))
        DashboardButton(
          title: 'Vender',
          icon: Icons.add_shopping_cart_rounded,
          color: Colors.green.shade600,
          onTap: () => onAction('venta'),
        ),
      // if (auth.hasPermission('crear_facturas'))
      //   DashboardButton(
      //     title: 'Pedidos',
      //     icon: Icons.restaurant_menu_rounded,
      //     color: Colors.amber.shade700,
      //     onTap: () => onAction('pedidos'),
      //   ),
      if (auth.hasPermission('ver_facturas'))
        DashboardButton(
          title: 'Ventas',
          icon: Icons.history_rounded,
          color: Colors.blue.shade600,
          onTap: () => onAction('historial_ventas'),
        ),
      if (auth.hasPermission('ver_clientes'))
        DashboardButton(
          title: 'Clientes',
          icon: Icons.people_alt_rounded,
          color: AppColors.azulOscuro,
          onTap: () => onAction('clientes'),
        ),
      // if (auth.hasPermission('ver_facturas'))
      //   DashboardButton(
      //     title: 'Reportes',
      //     icon: Icons.analytics_rounded,
      //     color: Colors.indigo,
      //     onTap: () => onAction('reportes'),
      //   ),
      if (!isCajero &&
          (auth.hasPermission('ver_inventario') ||
              auth.hasPermission('ver_productos')))
        DashboardButton(
          title: 'Productos',
          icon: Icons.fastfood_rounded,
          color: Colors.deepOrange,
          onTap: () => onAction('productos'),
        ),
      if (!isCajero && auth.hasPermission('crear_facturas'))
        DashboardButton(
          title: 'Cotizar',
          icon: Icons.request_quote_rounded,
          color: Colors.teal,
          onTap: () => onAction('crear_cotizacion'),
        ),
      if (!isCajero && auth.hasPermission('ver_facturas'))
        DashboardButton(
          title: 'Cotizaciones',
          icon: Icons.receipt_long_rounded,
          color: Colors.cyan.shade700,
          onTap: () => onAction('ver_cotizaciones'),
        ),
      // if (auth.hasPermission('crear_facturas'))
      //   DashboardButton(
      //     title: 'Crear O. Compra',
      //     icon: Icons.add_shopping_cart,
      //     color: Colors.deepPurple,
      //     onTap: () => onAction('crear_orden_compra'),
      //   ),
      // if (!isCajero && auth.hasPermission('ver_facturas'))
      //   DashboardButton(
      //     title: 'Órdenes Compra',
      //     icon: Icons.history,
      //     color: Colors.purple.shade700,
      //     onTap: () => onAction('ver_ordenes_compra'),
      //   ),
      if (!isCajero && auth.hasPermission('ver_cxp'))
        DashboardButton(
          title: 'Reg. Gasto',
          icon: Icons.request_quote_outlined,
          color: Colors.orange.shade700,
          onTap: () => onAction('registrar_gasto'),
        ),
      if (!isCajero && auth.hasPermission('ver_cxp'))
        DashboardButton(
          title: 'Cuenta por pagar',
          icon: Icons.money_off,
          color: Colors.red.shade600,
          onTap: () => onAction('ver_cxp'),
        ),
      if (!isCajero && auth.hasPermission('ver_cxc'))
        DashboardButton(
          title: 'Cuenta por cobrar',
          icon: Icons.attach_money,
          color: Colors.green.shade800,
          onTap: () => onAction('ver_cxc'),
        ),
    ];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;

            // print(width);

            // Ajuste de columnas usando la nueva clase ResponsiveUtils
            int crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(width);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1, // 👈 Más cuadrado para el nuevo diseño
              ),
              itemBuilder: (context, index) => items[index],
            );
          },
        ),
      ),
    );
  }
}
