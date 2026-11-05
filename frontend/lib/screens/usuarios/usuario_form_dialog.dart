import 'package:flutter/material.dart';
import '../../model/user.dart';
import '../../palletes/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';

class UsuarioFormDialog extends StatefulWidget {
  final User? usuario;
  final List<String> rolesDisponibles;
  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const UsuarioFormDialog({
    super.key,
    this.usuario,
    required this.rolesDisponibles,
    required this.onSave,
  });

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  late final Set<String> _selectedRoles;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get isEditing => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _passwordCtrl = TextEditingController();

    _selectedRoles = (u?.roles.isNotEmpty ?? false)
        ? u!.roles.where((r) => r.toLowerCase() != 'vendedor').toSet()
        : {'cajero'};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple.shade700;
      case 'cajero':
        return Colors.green.shade700;
      case 'contador':
        return Colors.indigo.shade700;
      case 'auxiliar contable':
        return Colors.teal.shade700;
      default:
        return AppColors.azulOscuro;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'cajero':
        return Icons.point_of_sale_outlined;
      case 'contador':
        return Icons.account_balance_outlined;
      case 'auxiliar contable':
        return Icons.calculate_outlined;
      default:
        return Icons.badge_outlined;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoles.isEmpty) {
      showToast(context, 'Debes asignar al menos un rol al usuario', bgColor: Colors.orange);
      return;
    }

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'username': _usernameCtrl.text.trim().toLowerCase(),
      'email': _emailCtrl.text.trim().toLowerCase(),
      'roles': _selectedRoles.toList(),
    };

    if (_passwordCtrl.text.isNotEmpty) {
      payload['password'] = _passwordCtrl.text;
    }

    setState(() => _isLoading = true);
    final success = await widget.onSave(payload);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesList = widget.rolesDisponibles.isNotEmpty
        ? widget.rolesDisponibles
            .where((r) => r.toLowerCase() != 'vendedor')
            .toList()
        : ['admin', 'cajero', 'contador', 'auxiliar contable'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── ENCABEZADO ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.manage_accounts_outlined : Icons.person_add_alt_1_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Modifica los datos personales y roles asignados'
                              : 'Completa los campos para registrar un nuevo usuario',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── FORMULARIO SCROLLABLE ─────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nombre Completo
                        CustomTextField(
                          label: 'Nombre Completo',
                          hintText: 'Ej. Juan Pérez',
                          controller: _nameCtrl,
                          prefixIcon: Icons.badge_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'El nombre es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Username y Email en 2 columnas
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Nombre de Usuario',
                                hintText: 'Ej. jperez',
                                controller: _usernameCtrl,
                                prefixIcon: Icons.alternate_email_rounded,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'El usuario es obligatorio';
                                  }
                                  if (val.contains(' ')) {
                                    return 'Sin espacios en blanco';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Correo Electrónico',
                                hintText: 'correo@ejemplo.com',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.mail_outline_rounded,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'El correo es obligatorio';
                                  }
                                  if (!val.contains('@') || !val.contains('.')) {
                                    return 'Correo inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Contraseña
                        CustomTextField(
                          label: isEditing ? 'Nueva Contraseña (Opcional)' : 'Contraseña',
                          hintText: isEditing ? 'Dejar en blanco para conservar la actual' : 'Mínimo 6 caracteres',
                          controller: _passwordCtrl,
                          isPassword: _obscurePassword,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          onSuffixIconTap: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          validator: (val) {
                            if (!isEditing) {
                              if (val == null || val.isEmpty) {
                                return 'La contraseña es obligatoria';
                              }
                              if (val.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                            } else if (val != null && val.isNotEmpty && val.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // ── ASIGNAR ROLES ─────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Asignar Roles / Permisos:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                            Text(
                              '${_selectedRoles.length} seleccionado(s)',
                              style: TextStyle(
                                fontSize: 11,
                                color: _selectedRoles.isEmpty ? Colors.red : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: rolesList.map((role) {
                              final isSelected = _selectedRoles.contains(role);
                              final color = _getRoleColor(role);

                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getRoleIcon(role),
                                      size: 15,
                                      color: isSelected ? Colors.white : color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : color,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: color,
                                backgroundColor: color.withValues(alpha: 0.08),
                                side: BorderSide(
                                  color: isSelected ? color : color.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedRoles.add(role);
                                    } else {
                                      _selectedRoles.remove(role);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── BOTONES DE ACCIÓN ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isEditing ? 'Guardar Cambios' : 'Crear Usuario',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

