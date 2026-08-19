import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lottie/lottie.dart';
import 'package:Rusic/rusic.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status.isCompleted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Rusic(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLottieLoaded(LottieComposition composition) async {
    _controller.duration = Duration(
      milliseconds:
          (composition.duration.inMilliseconds / 1.5).round(),
    );
    _controller.reset();

    // Remove the native splash screen if not already removed
    FlutterNativeSplash.remove();

    // On Android, wait for the native OS splash dismissal/fade-out to complete
    // so the Lottie animation starts right as it becomes visible.
    if (Platform.isAndroid) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size;
    // final animationSize = (size.shortestSide * 0.65).clamp(280.0, 380.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: RepaintBoundary(
          child: Lottie.asset(
            'assets/lottie_files/splash_screen_new.json',
            controller: _controller,
            frameRate: const FrameRate(60),
            renderCache: RenderCache.drawingCommands,
            filterQuality: FilterQuality.medium,
            // width: animationSize,
            // height: animationSize,
            fit: BoxFit.contain,
            onLoaded: _onLottieLoaded,
          ),
        ),
      ),
    );
  }
}
