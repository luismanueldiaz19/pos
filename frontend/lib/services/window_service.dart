import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  static bool _initialized = false;
  static final ValueNotifier<bool> isFullScreenNotifier =
      ValueNotifier<bool>(false);

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static Window? get _window {
    if (!isDesktop) return null;
    return WindowManager.instance.getCurrent() ??
        WindowManager.instance.getAll().firstOrNull;
  }

  /// Inicializa la gestión de ventana y escucha el atajo F11
  static Future<void> init() async {
    if (!isDesktop || _initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool startFullScreen = prefs.getBool('start_fullscreen') ?? false;

      final win = _window;
      if (win != null) {
        if (startFullScreen) {
          win.isFullScreen = true;
          isFullScreenNotifier.value = true;
        } else {
          isFullScreenNotifier.value = win.isFullScreen;
        }

        win.addListener((event) {
          if (event is WindowEnteredFullScreenEvent) {
            isFullScreenNotifier.value = true;
          } else if (event is WindowExitedFullScreenEvent) {
            isFullScreenNotifier.value = false;
          }
        });
      }

      // Captura global de teclado para tecla F11 (o Fn + F11 en portátiles)
      HardwareKeyboard.instance.addHandler(_handleGlobalKey);

      _initialized = true;
    } catch (e) {
      debugPrint('Error en WindowService.init: $e');
    }
  }

  static bool _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      toggleFullScreen();
      return true;
    }
    return false;
  }

  /// Alterna entre modo ventana normal y pantalla completa (sin barra de título ni barra de tareas de Windows)
  static Future<void> toggleFullScreen() async {
    if (!isDesktop) return;
    try {
      final win = _window;
      if (win != null) {
        final next = !win.isFullScreen;
        win.isFullScreen = next;
        isFullScreenNotifier.value = next;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('start_fullscreen', next);
      }
    } catch (e) {
      debugPrint('Error en toggleFullScreen: $e');
    }
  }

  /// Activa o desactiva explícitamente el modo pantalla completa
  static Future<void> setFullScreen(bool full) async {
    if (!isDesktop) return;
    try {
      final win = _window;
      if (win != null) {
        win.isFullScreen = full;
        isFullScreenNotifier.value = full;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('start_fullscreen', full);
      }
    } catch (e) {
      debugPrint('Error en setFullScreen: $e');
    }
  }
}
