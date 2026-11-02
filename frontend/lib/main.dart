import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'screens/login_page.dart';
import 'services/api_services.dart';
import 'services/window_service.dart';
import 'utils/navigation_service.dart';

bool _isLoggingOut = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar gestión de ventana de escritorio (Pantalla Completa y F11)
  await WindowService.init();

  final container = ProviderContainer();

  ApiService.onUnauthorized = () async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;

    await Future.delayed(const Duration(milliseconds: 300));

    // Usar el container para cerrar sesión
    await container.read(authProvider.notifier).logout();

    NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );

    _isLoggingOut = false;
  };

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}
