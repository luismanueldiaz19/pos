import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../config/app_config.dart';

class WindowService with WindowListener {
  static bool _initialized = false;
  static final ValueNotifier<bool> isFullScreenNotifier = ValueNotifier<bool>(
    false,
  );
  static final WindowService _instance = WindowService._();

  WindowService._();

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Inicializa la gestión de ventana, límites de tamaño estándar y escucha el atajo F11
  static Future<void> init() async {
    if (!isDesktop || _initialized) return;

    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(_instance);

      // Dimensiones mínimas y estándar de escritorio (evita contraer excesivamente la app)
      const minSize = Size(AppConfig.minWindowWidth, AppConfig.minWindowHeight);
      const defaultSize = Size(
        AppConfig.defaultWindowWidth,
        AppConfig.defaultWindowHeight,
      );

      // Fijar límite físico mínimo de ventana en el sistema operativo
      await windowManager.setMinimumSize(minSize);

      final prefs = await SharedPreferences.getInstance();
      final bool startFullScreen = prefs.getBool('start_fullscreen') ?? false;

      if (startFullScreen) {
        await windowManager.setFullScreen(true);
        isFullScreenNotifier.value = true;
      } else {
        // Si el tamaño actual guardado es menor que el mínimo estándar, ajustarlo y centrar
        final currentSize = await windowManager.getSize();
        if (currentSize.width < minSize.width ||
            currentSize.height < minSize.height) {
          await windowManager.setSize(defaultSize);
          await windowManager.center();
        }
        final isFull = await windowManager.isFullScreen();
        isFullScreenNotifier.value = isFull;
      }

      await windowManager.show();
      await windowManager.focus();

      // Captura global de teclado para tecla F11 (o Fn + F11 en portátiles)
      HardwareKeyboard.instance.addHandler(_handleGlobalKey);

      _initialized = true;
    } catch (e) {
      debugPrint('Error en WindowService.init: $e');
    }
  }

  @override
  void onWindowEnterFullScreen() {
    isFullScreenNotifier.value = true;
  }

  @override
  void onWindowLeaveFullScreen() {
    isFullScreenNotifier.value = false;
  }

  static bool _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      toggleFullScreen();
      return true;
    }
    return false;
  }

  /// Alterna entre modo ventana normal y pantalla completa
  static Future<void> toggleFullScreen() async {
    if (!isDesktop) return;
    try {
      final isFull = await windowManager.isFullScreen();
      final next = !isFull;
      await windowManager.setFullScreen(next);
      isFullScreenNotifier.value = next;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('start_fullscreen', next);
    } catch (e) {
      debugPrint('Error en toggleFullScreen: $e');
    }
  }

  /// Activa o desactiva explícitamente el modo pantalla completa
  static Future<void> setFullScreen(bool full) async {
    if (!isDesktop) return;
    try {
      await windowManager.setFullScreen(full);
      isFullScreenNotifier.value = full;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('start_fullscreen', full);
    } catch (e) {
      debugPrint('Error en setFullScreen: $e');
    }
  }
}
