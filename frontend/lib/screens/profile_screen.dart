import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_confirm_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _searchPermisoCtrl = TextEditingController();
  String _filtroPermiso = '';

  @override
  void dispose() {
    _searchPermisoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Mi Perfil',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'No hay sesión activa',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    // Identificar el rol principal para la temática visual
    String primaryRole = 'usuario';
    final roles = auth.roles.map((r) => r.toLowerCase()).toList();
    if (roles.contains('admin')) {
      primaryRole = 'admin';
    } else if (roles.contains('cajero')) {
      primaryRole = 'cajero';
    } else if (roles.contains('contador')) {
      primaryRole = 'contador';
    } else if (roles.isNotEmpty) {
      primaryRole = roles.first;
    }

    Color roleColor;
    Color roleBgColor;
    IconData roleIcon;
    String roleLabel;

    switch (primaryRole) {
      case 'admin':
        roleColor = const Color(0xFF1D4ED8);
        roleBgColor = const Color(0xFFEFF6FF);
        roleIcon = Icons.admin_panel_settings_rounded;
        roleLabel = 'Administrador del Sistema';
        break;
      case 'cajero':
        roleColor = const Color(0xFF059669);
        roleBgColor = const Color(0xFFECFDF5);
        roleIcon = Icons.point_of_sale_rounded;
        roleLabel = 'Cajero / Facturación';
        break;
      case 'contador':
        roleColor = const Color(0xFF4F46E5);
        roleBgColor = const Color(0xFFEEF2FF);
        roleIcon = Icons.account_balance_rounded;
        roleLabel = 'Contabilidad y Finanzas';
        break;
      default:
        roleColor = const Color(0xFF475569);
        roleBgColor = const Color(0xFFF1F5F9);
        roleIcon = Icons.person_rounded;
        roleLabel = 'Usuario Estándar';
    }

    // Filtrar permisos según el texto de búsqueda
    final permisos = auth.permissions.where((p) {
      if (_filtroPermiso.isEmpty) return true;
      return p.toLowerCase().contains(_filtroPermiso.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 880;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Tarjeta Resumen de Identidad del Usuario
                    _buildUserSummaryCard(
                      user: user,
                      roleColor: roleColor,
                      roleBgColor: roleBgColor,
                      roleIcon: roleIcon,
                      roleLabel: roleLabel,
                    ),

                    const SizedBox(height: 16),

                    // 2. Contenido en 2 columnas (si es pantalla amplia) o apilado
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Columna Izquierda: Datos de la Cuenta + Sistema
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildAccountDetailsCard(user, roleLabel),
                                const SizedBox(height: 14),
                                _buildSystemInfoCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Columna Derecha: Permisos Asignados
                          Expanded(
                            flex: 6,
                            child: _buildPermissionsCard(
                              permisosTotal: auth.permissions.length,
                              permisosFiltrados: permisos,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildAccountDetailsCard(user, roleLabel),
                          const SizedBox(height: 14),
                          _buildPermissionsCard(
                            permisosTotal: auth.permissions.length,
                            permisosFiltrados: permisos,
                          ),
                          const SizedBox(height: 14),
                          _buildSystemInfoCard(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: Color(0xFF1E293B),
        ),
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: 'Regresar',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Mi Perfil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          Text(
            'Información de la cuenta de usuario y permisos del sistema',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(
              Icons.logout_rounded,
              size: 14,
              color: Color(0xFFDC2626),
            ),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              backgroundColor: const Color(0xFFFEF2F2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
    );
  }

  Widget _buildUserSummaryCard({
    required dynamic user,
    required Color roleColor,
    required Color roleBgColor,
    required IconData roleIcon,
    required String roleLabel,
  }) {
    final String initial = (user.name != null && user.name!.trim().isNotEmpty)
        ? user.name!.trim()[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar compacto con badge de estado
          Stack(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [roleColor.withValues(alpha: 0.85), roleColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Información central (Nombre, correo y badges)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 10,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Activo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        user.email ?? 'Sin correo registrado',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Badge del Rol
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: roleBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 12, color: roleColor),
                          const SizedBox(width: 5),
                          Text(
                            roleLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: roleColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Badge de ID de usuario
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tag_rounded,
                            size: 11,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'ID: #${user.id ?? 1}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard(dynamic user, String roleLabel) {
    String fechaAlta = 'Vigente';
    if (user.createdAt != null) {
      try {
        fechaAlta = DateFormat('dd/MM/yyyy').format(user.createdAt!);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, size: 16, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Datos de la Cuenta',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Nombre completo',
            user.name ?? '---',
            Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Correo institucional',
            user.email ?? '---',
            Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Rol operativo', roleLabel, Icons.security_rounded),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Empresa / Entidad',
            AppConfig.nombreEmpresa,
            Icons.business_rounded,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'RNC Empresa',
            AppConfig.rnc,
            Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Fecha de creación',
            fechaAlta,
            Icons.calendar_today_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsCard({
    required int permisosTotal,
    required List<String> permisosFiltrados,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de permisos con contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.vpn_key_outlined,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Permisos Asignados',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '$permisosTotal activos',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Buscador de permisos (útil cuando son muchos)
          if (permisosTotal > 4)
            Container(
              height: 32,
              margin: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _searchPermisoCtrl,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar permiso...',
                  hintStyle: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 32),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _filtroPermiso = val;
                  });
                },
              ),
            ),

          // Lista de badges de permisos
          if (permisosFiltrados.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                _filtroPermiso.isEmpty
                    ? 'No hay permisos asignados para este usuario.'
                    : 'No se encontraron permisos con "$_filtroPermiso".',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: permisosFiltrados
                  .map((p) => _buildPermissionBadge(p))
                  .toList(),
            ),

          const SizedBox(height: 14),

          // Nota informativa de seguridad
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los permisos asignados determinan los módulos y acciones operativas habilitadas para este usuario.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBadge(String permission) {
    // Determinar color y categoría por el nombre del permiso
    Color badgeColor;
    Color bgColor;
    IconData badgeIcon;

    final lower = permission.toLowerCase();
    if (lower.contains('cliente')) {
      badgeColor = const Color(0xFF0284C7); // Celeste / Sky
      bgColor = const Color(0xFFF0F9FF);
      badgeIcon = Icons.people_alt_rounded;
    } else if (lower.contains('factura') || lower.contains('venta')) {
      badgeColor = const Color(0xFF059669); // Verde esmeralda
      bgColor = const Color(0xFFECFDF5);
      badgeIcon = Icons.receipt_long_rounded;
    } else if (lower.contains('producto') || lower.contains('inventario')) {
      badgeColor = const Color(0xFFD97706); // Ámbar / Naranja
      bgColor = const Color(0xFFFFFBEB);
      badgeIcon = Icons.inventory_2_rounded;
    } else if (lower.contains('caja')) {
      badgeColor = const Color(0xFF7C3AED); // Púrpura
      bgColor = const Color(0xFFF5F3FF);
      badgeIcon = Icons.point_of_sale_rounded;
    } else {
      badgeColor = const Color(0xFF475569); // Slate
      bgColor = const Color(0xFFF8FAFC);
      badgeIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            permission.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.devices_rounded, size: 15, color: Color(0xFF64748B)),
              SizedBox(width: 7),
              Text(
                'Información del Sistema',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniSystemStat('Software', AppConfig.appName),
              _buildMiniSystemStat('Versión', 'v${AppConfig.appVersion}'),
              _buildMiniSystemStat('Entorno', 'Conectado'),
              _buildMiniSystemStat('Motor', 'AGY 2.0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSystemStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmar = await CustomConfirmDialog.show(
      context,
      title: '¿Cerrar Sesión?',
      message: 'Se cerrará tu sesión activa de usuario en esta terminal.',
      confirmText: 'Sí, Salir',
      cancelText: 'Cancelar',
      primaryColor: const Color(0xFFDC2626),
      icon: Icons.logout_rounded,
    );

    if (confirmar == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}
