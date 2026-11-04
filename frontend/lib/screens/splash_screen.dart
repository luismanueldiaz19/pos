import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../palletes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_loading.dart';
import 'home_page.dart';
import 'login_page.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _letterAnimations;

  final String text1 = 'Menu';
  final String text2 = 'xa';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _createAnimations();
    _controller.forward();

    _checkSession();
  }

  void _createAnimations() {
    final totalLetters = text1.length + text2.length;

    _letterAnimations = List.generate(totalLetters, (index) {
      final start = index / totalLetters;
      final end = start + (1 / totalLetters);
      return Tween<Offset>(
        begin: const Offset(0, -1.5), // cae desde arriba
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  Future<void> _checkSession() async {
    await Future.delayed(
      const Duration(seconds: 3),
    ); // Un poco más para apreciar el splash
    if (!mounted) return;

    final auth = ref.read(authProvider.notifier);
    final isValid = await auth.verifySession();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isValid ? const MyHomePage() : const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    int animationIndex = 0;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(child: Image.asset(background, fit: BoxFit.cover)),
          // 2. Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          // 3. Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ===== TEXTO ANIMADO =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...text1.split('').map((letter) {
                      final anim = _letterAnimations[animationIndex++];
                      return SlideTransition(
                        position: anim,
                        child: Text(
                          letter,
                          style: textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    ...text2.split('').map((letter) {
                      final anim = _letterAnimations[animationIndex++];
                      return SlideTransition(
                        position: anim,
                        child: Text(
                          letter,
                          style: textTheme.displaySmall?.copyWith(
                            color: AppColors.azulClaro,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 40),

                // ===== CUSTOM LOADING =====
                const CustomLoading(text: 'Verificando acceso...', size: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
