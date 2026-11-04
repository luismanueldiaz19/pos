import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_restaurante/palletes/app_colors.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_loading.dart';
import 'home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  bool? obscureText = true;
  final FocusNode _focusNode = FocusNode();
  late TextEditingController controllerUsuario = TextEditingController();
  late TextEditingController controllerClave = TextEditingController();

  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'Admin',
      'username': 'ludeveloper',
      'pass': '199512',
      'icon': Icons.admin_panel_settings_outlined,
    },
    {
      'name': 'Cajero 1',
      'username': 'cajero',
      'pass': 'cajero123',
      'icon': Icons.point_of_sale_outlined,
    },
  ];

  int _selectedProfileIndex = 0;

  void _selectProfile(int index) {
    setState(() {
      _selectedProfileIndex = index;
      controllerUsuario.text = _profiles[index]['username']!;
      controllerClave.text = _profiles[index]['pass']!;
    });
  }

  final authService = AuthService();
  bool isLoading = false;

  late AnimationController _animationController;

  bool showBorderGlow = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Esperar a que el ZoomIn termine (600ms) para iniciar el giro del borde
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => showBorderGlow = true);
        _animationController.repeat();
      }
    });
  }

  void iniciarSeccion() async {
    setState(() => isLoading = true);

    // 1. Mostrar Dialogo de Carga (CustomLoading)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CustomLoading(
              text: 'Autenticando sesión...',
              size: 90,
            ),
          ),
        ),
      ),
    );

    final auth = ref.read(authProvider.notifier);

    final success = await auth.login(
      controllerUsuario.text.trim(),
      controllerClave.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Esperar brevemente solo si el login es correcto
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }

    // 2. Cerrar Dialogo
    Navigator.pop(context);

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    } else {
      showToast(context, 'Credenciales incorrectas', bgColor: Colors.red);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    controllerClave.dispose();
    controllerUsuario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(child: Image.asset(background, fit: BoxFit.cover)),
          // 2. Overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          // 3. Center Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ZoomIn(
                animate: showBorderGlow,
                duration: const Duration(milliseconds: 600),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(3.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(21),
                          gradient: showBorderGlow
                              ? SweepGradient(
                                  center: Alignment.center,
                                  transform: GradientRotation(
                                    _animationController.value * 2 * math.pi,
                                  ),
                                  colors: const [
                                    Colors.transparent,
                                    AppColors.success,
                                    Colors.transparent,
                                  ],
                                  stops: const [0.4, 0.5, 0.6],
                                )
                              : null,
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Left Section (Branding)
                            if (size.width > 750)
                              Expanded(
                                flex: 4,
                                child: Container(
                                  color: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Spacer(),
                                      Text(
                                        appName[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 72,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                          fontFamily: 'Serif',
                                        ),
                                      ),
                                      Text(
                                        appName.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2.0,
                                          color: AppColors.azulOscuro,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '© ${appName.toUpperCase()} SOFT, INC.',
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.grey.shade500,
                                          fontSize: 9.5,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'HANDCRAFTED BY ${developer.toUpperCase()}',
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.grey.shade400,
                                          fontSize: 8,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // 2. Right Section (Form)
                            Expanded(
                              flex: 5,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.grey.shade100,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 22,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¡Bienvenido!',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.azulOscuro,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Inicia sesión para continuar',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // /// 👤 SELECTOR DE PERFIL (CHIPS RÁPIDOS COMPACTOS)
                                    // Text(
                                    //   'ACCESO RÁPIDO',
                                    //   style: TextStyle(
                                    //     fontSize: 9.5,
                                    //     fontWeight: FontWeight.w700,
                                    //     color: Colors.grey.shade500,
                                    //     letterSpacing: 0.8,
                                    //   ),
                                    // ),

                                    // const SizedBox(height: 6),
                                    // Wrap(
                                    //   spacing: 6,
                                    //   runSpacing: 6,
                                    //   children: List.generate(_profiles.length, (
                                    //     index,
                                    //   ) {
                                    //     final isSelected =
                                    //         _selectedProfileIndex == index;
                                    //     final profile = _profiles[index];
                                    //     return InkWell(
                                    //       onTap: () => _selectProfile(index),
                                    //       borderRadius: BorderRadius.circular(
                                    //         8,
                                    //       ),
                                    //       child: AnimatedContainer(
                                    //         duration: const Duration(
                                    //           milliseconds: 200,
                                    //         ),
                                    //         padding: const EdgeInsets.symmetric(
                                    //           horizontal: 8,
                                    //           vertical: 4,
                                    //         ),
                                    //         decoration: BoxDecoration(
                                    //           color: isSelected
                                    //               ? AppColors.azulOscuro
                                    //               : Colors.grey.shade50,
                                    //           borderRadius:
                                    //               BorderRadius.circular(8),
                                    //           border: Border.all(
                                    //             color: isSelected
                                    //                 ? AppColors.azulOscuro
                                    //                 : Colors.grey.shade300,
                                    //             width: 1,
                                    //           ),
                                    //           boxShadow: isSelected
                                    //               ? [
                                    //                   BoxShadow(
                                    //                     color: AppColors
                                    //                         .azulOscuro
                                    //                         .withValues(
                                    //                           alpha: 0.25,
                                    //                         ),
                                    //                     blurRadius: 4,
                                    //                     offset: const Offset(
                                    //                       0,
                                    //                       1.5,
                                    //                     ),
                                    //                   ),
                                    //                 ]
                                    //               : [],
                                    //         ),
                                    //         child: Row(
                                    //           mainAxisSize: MainAxisSize.min,
                                    //           children: [
                                    //             Icon(
                                    //               profile['icon'] as IconData,
                                    //               size: 13,
                                    //               color: isSelected
                                    //                   ? Colors.white
                                    //                   : Colors.grey.shade700,
                                    //             ),
                                    //             const SizedBox(width: 5),
                                    //             Text(
                                    //               profile['name'] as String,
                                    //               style: TextStyle(
                                    //                 color: isSelected
                                    //                     ? Colors.white
                                    //                     : Colors.grey.shade800,
                                    //                 fontWeight: isSelected
                                    //                     ? FontWeight.w700
                                    //                     : FontWeight.w500,
                                    //                 fontSize: 11,
                                    //               ),
                                    //             ),
                                    //             const SizedBox(width: 4),
                                    //             Container(
                                    //               padding:
                                    //                   const EdgeInsets.symmetric(
                                    //                     horizontal: 4,
                                    //                     vertical: 1,
                                    //                   ),
                                    //               decoration: BoxDecoration(
                                    //                 color: isSelected
                                    //                     ? Colors.white
                                    //                           .withValues(
                                    //                             alpha: 0.2,
                                    //                           )
                                    //                     : Colors.grey.shade200,
                                    //                 borderRadius:
                                    //                     BorderRadius.circular(
                                    //                       4,
                                    //                     ),
                                    //               ),
                                    //               child: Text(
                                    //                 '@${profile['username']}',
                                    //                 style: TextStyle(
                                    //                   color: isSelected
                                    //                       ? Colors.white
                                    //                             .withValues(
                                    //                               alpha: 0.95,
                                    //                             )
                                    //                       : Colors
                                    //                             .grey
                                    //                             .shade600,
                                    //                   fontSize: 9.5,
                                    //                   fontWeight:
                                    //                       FontWeight.w500,
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //       ),
                                    //     );
                                    //   }),
                                    // ),
                                    const SizedBox(height: 10),

                                    // USER FIELD
                                    textFieldWidgetUI(
                                      width: double.infinity,
                                      label: 'Usuario',
                                      prefixIcon: Icons.account_circle_outlined,
                                      controller: controllerUsuario,
                                      onEditingComplete: () =>
                                          _focusNode.requestFocus(),
                                    ),

                                    // PASSWORD FIELD
                                    textFieldWidgetUI(
                                      width: double.infinity,
                                      label: 'Contraseña / PIN',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: obscureText,
                                      focusNode: _focusNode,
                                      controller: controllerClave,
                                      suffixIcon: obscureText!
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      onSuffixTap: () {
                                        setState(
                                          () => obscureText = !obscureText!,
                                        );
                                      },
                                      onEditingComplete: iniciarSeccion,
                                    ),

                                    const SizedBox(height: 14),

                                    // LOGIN BUTTON (SMALL / COMPACT)
                                    CustomButton(
                                      width: double.infinity,
                                      height: 42,
                                      borderRadius: 8,
                                      fontSize: 13.5,
                                      title: 'INGRESAR',
                                      isLoading: isLoading,
                                      onPressed: iniciarSeccion,
                                      backgroundColor: AppColors.secondary,
                                    ),

                                    const SizedBox(height: 10),
                                    Center(
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                        ),
                                        child: Text(
                                          '¿Olvidaste tu acceso? Contacta a Soporte',
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
