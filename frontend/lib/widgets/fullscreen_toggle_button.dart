import 'package:flutter/material.dart';
import '../services/window_service.dart';

class FullscreenToggleButton extends StatelessWidget {
  final Color? color;
  final double size;
  final bool showBadgeOrBackground;

  const FullscreenToggleButton({
    super.key,
    this.color,
    this.size = 20,
    this.showBadgeOrBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!WindowService.isDesktop) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: WindowService.isFullScreenNotifier,
      builder: (context, isFullScreen, _) {
        final icon = isFullScreen
            ? Icons.fullscreen_exit_rounded
            : Icons.fullscreen_rounded;
        final tooltip = isFullScreen
            ? 'Salir de pantalla completa (F11)'
            : 'Pantalla completa (F11)';

        if (showBadgeOrBackground) {
          return Tooltip(
            message: tooltip,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: WindowService.toggleFullScreen,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isFullScreen
                      ? Colors.amber.withValues(alpha: 0.15)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFullScreen
                        ? Colors.amber.withValues(alpha: 0.4)
                        : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: size,
                  color: isFullScreen
                      ? Colors.amberAccent
                      : (color ?? Colors.white70),
                ),
              ),
            ),
          );
        }

        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: tooltip,
          icon: Icon(icon, size: size, color: color),
          onPressed: WindowService.toggleFullScreen,
        );
      },
    );
  }
}

