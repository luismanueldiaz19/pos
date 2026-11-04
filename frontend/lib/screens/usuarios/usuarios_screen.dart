import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/user.dart';
import '../../palletes/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../utils/helpers.dart';
// import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/custom_text_field.dart';
import 'usuario_form_dialog.dart';

class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});

  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider).token;
      if (token != null) {
        ref.read(usuarioProvider.notifier).cargarDatos(token);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple.shade700;
      case 'cajero':
        return Colors.green.shade700;
      case 'vendedor':
        return Colors.orange.shade800;
      case 'contador':
        return Colors.indigo.shade700;
      case 'auxiliar contable':
        return Colors.teal.shade700;
      default:
        return AppColors.azulOscuro;
    }
  }

  void _abrirFormularioUsuario({User? usuario}) {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    final state = ref.read(usuarioProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UsuarioFormDialog(
        usuario: usuario,
        rolesDisponibles: state.rolesDisponibles,
        onSave: (payload) async {
          final notifier = ref.read(usuarioProvider.notifier);
          bool ok;
          if (usuario != null && usuario.id != null) {
            ok = await notifier.actualizarUsuario(token, usuario.id!, payload);
            if (ok && mounted) {
              showToast(
                context,
                'Usuario actualizado correctamente',
                bgColor: Colors.green,
              );
            }
          } else {
            ok = await notifier.crearUsuario(token, payload);
            if (ok && mounted) {
              showToast(
                context,
                'Usuario creado correctamente',
                bgColor: Colors.green,
              );
            }
          }

          if (!ok && mounted) {
            final err =
                ref.read(usuarioProvider).error ?? 'Error en la operación';
            showToast(context, err, bgColor: Colors.red);
          }
          return ok;
        },
      ),
    );
  }

  /*
  Future<void> _confirmarEliminacion(User user) async {
    final token = ref.read(authProvider).token;
    final currentUserId = ref.read(authProvider).user?.id;

    if (token == null || user.id == null) return;

    if (user.id == currentUserId) {
      showToast(context, 'No puedes eliminar tu propio usuario en sesión', bgColor: Colors.orange);
      return;
    }

    final confirmed = await CustomConfirmDialog.show(
      context,
      title: '¿Eliminar Usuario?',
      message: '¿Estás seguro de que deseas eliminar al usuario "${user.name}" (@${user.username})? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      icon: Icons.person_remove_outlined,
      primaryColor: Colors.red,
    );

    if (confirmed == true && mounted) {
      final ok = await ref.read(usuarioProvider.notifier).eliminarUsuario(token, user.id!);
      if (mounted) {
        if (ok) {
          showToast(context, 'Usuario eliminado correctamente', bgColor: Colors.green);
        } else {
          final err = ref.read(usuarioProvider).error ?? 'No se pudo eliminar el usuario';
          showToast(context, err, bgColor: Colors.red);
        }
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuarioProvider);
    final auth = ref.watch(authProvider);

    final isSuperDev = auth.user?.username?.toLowerCase().trim() == 'ludeveloper';
    if (!isSuperDev) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'ACCESO RESTRINGIDO',
            style: TextStyle(
              color: AppColors.azulOscuro,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_outlined, size: 56, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Acceso Exclusivo para ludeveloper',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Únicamente el desarrollador principal (ludeveloper) tiene permisos para gestionar usuarios y roles.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Contadores rápidos para la franja de resumen
    final totalUsuarios = state.usuarios.length;
    final totalAdmins = state.usuarios
        .where((u) => u.roles.any((r) => r.toLowerCase() == 'admin'))
        .length;
    final totalCajeros = state.usuarios
        .where((u) => u.roles.any((r) => r.toLowerCase() == 'cajero'))
        .length;
    final totalVendedores = state.usuarios
        .where((u) => u.roles.any((r) => r.toLowerCase() == 'vendedor'))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'GESTIÓN DE USUARIOS Y ROLES',
          style: TextStyle(
            color: AppColors.azulOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.azulOscuro),
        actions: [
          // Botón Nuevo Usuario en AppBar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () => _abrirFormularioUsuario(),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
              label: const Text(
                'Nuevo Usuario',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.azulOscuro),
            tooltip: 'Recargar',
            onPressed: () {
              if (auth.token != null) {
                ref.read(usuarioProvider.notifier).cargarDatos(auth.token!);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── BARRA DE BÚSQUEDA Y FILTRO POR ROL ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Buscador en vivo
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: '',
                    hintText: 'Buscar por nombre, @usuario o correo...',
                    controller: _searchController,
                    prefixIcon: Icons.search_rounded,
                    onChanged: (val) {
                      if (auth.token != null) {
                        ref
                            .read(usuarioProvider.notifier)
                            .onSearchChanged(auth.token!, val);
                      }
                    },
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Icons.clear_rounded
                        : null,
                    onSuffixIconTap: () {
                      _searchController.clear();
                      if (auth.token != null) {
                        ref
                            .read(usuarioProvider.notifier)
                            .onSearchChanged(auth.token!, '');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 14),

                // Filtros de Roles en Chips compactos
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleFilterChip(
                          label: 'Todos',
                          isSelected: state.selectedRoleFilter == null,
                          onTap: () {
                            if (auth.token != null) {
                              ref
                                  .read(usuarioProvider.notifier)
                                  .filtrarPorRol(auth.token!, null);
                            }
                          },
                        ),
                        ...(state.rolesDisponibles.isNotEmpty
                                ? state.rolesDisponibles
                                : const [
                                    'admin',
                                    'vendedor',
                                    'cajero',
                                    'contador',
                                    'auxiliar contable',
                                  ])
                            .map((r) {
                              final isSelected =
                                  state.selectedRoleFilter?.toLowerCase() ==
                                  r.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _buildRoleFilterChip(
                                  label: r.toUpperCase(),
                                  isSelected: isSelected,
                                  color: _getRoleColor(r),
                                  onTap: () {
                                    if (auth.token != null) {
                                      ref
                                          .read(usuarioProvider.notifier)
                                          .filtrarPorRol(auth.token!, r);
                                    }
                                  },
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── TARJETAS KPI DE RESUMEN ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _buildKpiCard(
                  label: 'TOTAL USUARIOS',
                  value: '$totalUsuarios',
                  icon: Icons.people_alt_outlined,
                  color: AppColors.azulOscuro,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  label: 'ADMINISTRADORES',
                  value: '$totalAdmins',
                  icon: Icons.admin_panel_settings_outlined,
                  color: Colors.purple.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  label: 'CAJEROS',
                  value: '$totalCajeros',
                  icon: Icons.point_of_sale_outlined,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  label: 'VENDEDORES',
                  value: '$totalVendedores',
                  icon: Icons.storefront_outlined,
                  color: Colors.orange.shade800,
                ),
              ],
            ),
          ),

          // ── LISTADO PRINCIPAL DE USUARIOS ─────────────────────────────────
          Expanded(
            child: state.isLoading && state.usuarios.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.usuarios.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No se encontraron usuarios',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prueba ajustando los filtros o registra uno nuevo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: state.usuarios.length,
                    itemBuilder: (context, index) {
                      final user = state.usuarios[index];
                      return _buildUserCard(user, auth.user?.id);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user, int? currentUserId) {
    final isMe = user.id != null && user.id == currentUserId;
    final initials = (user.name ?? 'U')
        .trim()
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    final primaryRole = user.roles.isNotEmpty ? user.roles.first : 'vendedor';
    final roleColor = _getRoleColor(primaryRole);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar con Iniciales
          CircleAvatar(
            radius: 20,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: roleColor,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Información del Usuario (Nombre, username, email)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TÚ',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '@${user.username ?? 'usuario'}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.mail_outline,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.email ?? '---',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Roles Asignados (Chips con iconos)
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: user.roles.map((r) {
                final c = _getRoleColor(r);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: c.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    r.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: c,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Acción Editar (Los usuarios no se eliminan por trazabilidad histórica)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.azulOscuro,
            tooltip: 'Editar Usuario y Roles',
            onPressed: () => _abrirFormularioUsuario(usuario: user),
          ),
        ],
      ),
    );
  }
}
