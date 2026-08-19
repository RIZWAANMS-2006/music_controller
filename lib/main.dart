import 'dart:io';
import 'package:flutter/material.dart';
import "package:window_size/window_size.dart";
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Rusic/managers/settings_manager.dart';
import 'package:Rusic/managers/database_manager.dart';
import 'package:Rusic/managers/widget_manager.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:Rusic/ui/splash_screen.dart';

Future<void> main() async {
  // Initialize Flutter Bindings and preserve native splash
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.rusic.app.channel.audio',
    androidNotificationChannelName: 'Rusic Audio Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    notificationColor: const Color(0xFFE53935),
    androidShowNotificationBadge: true,
  );
  JustAudioMediaKit.ensureInitialized();

  await SettingsManager.init();
  await DatabaseManager
      .instance
      .database; // Ensure database & cache initialized

  if (Platform.isAndroid || Platform.isIOS) {
    await WidgetManager.initWidget();
  }

  // Request Android permissions asynchronously without blocking the splash screen
  if (Platform.isAndroid) {
    Permission.storage.request().then((_) {
      Permission.manageExternalStorage.request();
    });
  }

  // Initialize Supabase
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Set Preferred Orientations and System UI Mode
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  // Set Window Size Constraints for Desktop Platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(500, 1005)); //logical width height
    // setWindowMaxSize(const Size(10000, 10000)); //logical width height
  }

  // Remove native splash screen after asynchronous setup is complete
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SettingsManager.systemTheme,
        SettingsManager.fontFamily,
      ]),
      builder: (context, child) {
        final value = SettingsManager.systemTheme.value;
        final themeMode = value == "System"
            ? ThemeMode.system
            : (value == "Light" ? ThemeMode.light : ThemeMode.dark);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: SettingsManager().lightTheme,
          darkTheme: SettingsManager().darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
