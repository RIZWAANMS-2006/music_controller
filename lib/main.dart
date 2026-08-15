import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:Rusic/music_player/music_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import "package:window_size/window_size.dart";
import 'music_player/music_player.dart';
import 'settings/settings.dart';
import 'search/search_page.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Rusic/managers/settings_manager.dart';
import 'package:Rusic/managers/database_manager.dart';
import 'package:Rusic/managers/ui_manager.dart';
import 'package:Rusic/managers/widget_manager.dart';
import 'package:toastification/toastification.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

Future<void> main() async {
  // Initialize JustAudioMediaKit And Flutter Bindings
  WidgetsFlutterBinding.ensureInitialized();
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

  // Request Android permissions early (Android 11+)
  if (Platform.isAndroid) {
    // Request READ_EXTERNAL_STORAGE first (more reliable than MANAGE_EXTERNAL_STORAGE)
    await Permission.storage.request();

    // Also try MANAGE_EXTERNAL_STORAGE for broader access
    await Permission.manageExternalStorage.request();
  }

  // Custom Error Widget
  // ErrorWidget.builder = (FlutterErrorDetails details) {
  //   return Center(child: CircularProgressIndicator(color: Colors.redAccent));
  // };

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

  runApp(const Rusic());
}

//index for Navigation Bar
int navigationIndex = 1;

// Bottom Navigation Bar Items
// List<Widget> navigationBarDestinationsItems = [
//   const NavigationDestination(icon: Icon(Icons.search), label: "Search"),
//   const NavigationDestination(icon: Icon(Icons.music_note), label: "Home"),
//   const NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
// ];

List<SalomonBottomBarItem> getNavigationBarDestinations(BuildContext context) =>
    [
      SalomonBottomBarItem(
        icon: SvgPicture.asset(
          "assets/MusicIcons/search.svg",
          colorFilter: ColorFilter.mode(
            Theme.of(context).textTheme.bodyLarge!.color!,
            BlendMode.srcIn,
          ),
        ),
        title: const Text("Search"),
        activeIcon: SvgPicture.asset(
          "assets/MusicIcons/search.svg",
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primary,
            BlendMode.srcIn,
          ),
        ),
      ),

      SalomonBottomBarItem(
        icon: SvgPicture.asset(
          "assets/MusicIcons/home.svg",
          colorFilter: ColorFilter.mode(
            Theme.of(context).textTheme.bodyLarge!.color!,
            BlendMode.srcIn,
          ),
        ),
        title: const Text("Home"),
        activeIcon: SvgPicture.asset(
          "assets/MusicIcons/home.svg",
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primary,
            BlendMode.srcIn,
          ),
        ),
      ),

      SalomonBottomBarItem(
        icon: SvgPicture.asset(
          "assets/MusicIcons/settings.svg",
          colorFilter: ColorFilter.mode(
            Theme.of(context).textTheme.bodyLarge!.color!,
            BlendMode.srcIn,
          ),
        ),
        title: const Text("Settings"),
        activeIcon: SvgPicture.asset(
          "assets/MusicIcons/settings.svg",
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primary,
            BlendMode.srcIn,
          ),
        ),
      ),
    ];

// Navigation Rail Destinations
List<NavigationRailDestination> getNavigationRailDestinations(
  BuildContext context,
) => [
  NavigationRailDestination(
    icon: SvgPicture.asset(
      "assets/MusicIcons/search.svg",
      colorFilter: ColorFilter.mode(
        Theme.of(context).textTheme.bodyLarge!.color!,
        BlendMode.srcIn,
      ),
    ),
    selectedIcon: const Icon(Icons.search),
    label: const Text("Search"),
    padding: const EdgeInsets.symmetric(vertical: 5),
  ),
  NavigationRailDestination(
    icon: SvgPicture.asset(
      "assets/MusicIcons/home.svg",
      colorFilter: ColorFilter.mode(
        Theme.of(context).textTheme.bodyLarge!.color!,
        BlendMode.srcIn,
      ),
    ),
    label: const Text("Home"),
    padding: const EdgeInsets.symmetric(vertical: 5),
  ),
  NavigationRailDestination(
    icon: SvgPicture.asset(
      "assets/MusicIcons/settings.svg",
      colorFilter: ColorFilter.mode(
        Theme.of(context).textTheme.bodyLarge!.color!,
        BlendMode.srcIn,
      ),
    ),
    label: const Text("Settings"),
    padding: const EdgeInsets.symmetric(vertical: 5),
  ),
];

class Rusic extends StatefulWidget {
  const Rusic({super.key});

  @override
  State<Rusic> createState() => RusicState();
}

class RusicState extends State<Rusic> {
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: AnimatedBuilder(
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
            title: "Rusic",
            debugShowCheckedModeBanner: false,
            theme: SettingsManager().lightTheme,
            darkTheme: SettingsManager().darkTheme,
            themeMode: themeMode,
            builder: (context, child) {
              if (child == null) {
                return const SizedBox.shrink();
              }
              return child;
            },
            //ThemeMode.system,
            home: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth <= 700) {
                  return const CompactScreen();
                } else {
                  return const WideScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// Wide Screen Layout for larger displays
class WideScreen extends StatefulWidget {
  const WideScreen({super.key});

  @override
  State<WideScreen> createState() => WideScreenState();
}

class WideScreenState extends State<WideScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            // extended: true,
            destinations: getNavigationRailDestinations(context),
            groupAlignment: 0,
            // backgroundColor: const Color.fromRGBO(26, 26, 26, 1),
            labelType: NavigationRailLabelType.selected,
            indicatorShape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            selectedIndex: navigationIndex,
            onDestinationSelected: (value) => setState(() {
              navigationIndex = value;
            }),
          ),
          const VerticalDivider(
            color: Color.fromRGBO(255, 245, 245, 0.3),
            thickness: 0.5,
            width: 0.5,
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: wideScreenPanelsSwapped,
              builder: (context, isSwapped, _) {
                final double compactPaneWidth =
                    (MediaQuery.of(context).size.width * 0.3)
                        .clamp(350, 450)
                        .toDouble();

                final contentPane = IndexedStack(
                  index: navigationIndex,
                  children: const [Search(), Library(), Settings()],
                );

                const musicPane = FullSizeMusicController();

                return Stack(
                  children: [
                    Row(
                      children: isSwapped
                          ? [
                              const Expanded(child: musicPane),
                              SizedBox(
                                width: compactPaneWidth,
                                height: double.infinity,
                                child: contentPane,
                              ),
                            ]
                          : [
                              Expanded(child: contentPane),
                              SizedBox(
                                width: compactPaneWidth,
                                height: double.infinity,
                                child: musicPane,
                              ),
                            ],
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 4,
                      right: compactPaneWidth - 52,
                      child: IconButton(
                        onPressed: toggleWideScreenPanels,
                        icon: SvgPicture.asset("assets/MusicIcons/swap.svg"),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Compact Screen Layout for smaller displays
class CompactScreen extends StatefulWidget {
  const CompactScreen({super.key});

  @override
  State<CompactScreen> createState() => CompactScreenState();
}

class CompactScreenState extends State<CompactScreen> {
  final GlobalKey _navBarKey = GlobalKey();
  bool _isVisible = true;
  double? _navBarWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavBarWidth());
  }

  void _updateNavBarWidth() {
    if (_navBarKey.currentContext != null) {
      final width = _navBarKey.currentContext!.size?.width;
      if (width != _navBarWidth) {
        setState(() {
          _navBarWidth = width;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavBarWidth());
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      extendBody: true,
      bottomNavigationBar: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            offset: navigationIndex == 2
                ? const Offset(0, 2.2)
                : (_isVisible ? Offset.zero : const Offset(0, 1.2)),
            child: BottomMusicController(
              width: _navBarWidth != null ? _navBarWidth! * 1.1 : null,
            ),
          ),
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            offset: _isVisible ? Offset.zero : const Offset(0, 2.0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              opacity: _isVisible ? 1.0 : 0.0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhysicalModel(
                        color: Colors.black,
                        elevation: 15,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(30),
                        ),
                        child: ClipRRect(
                          key: _navBarKey,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(40),
                          ),
                          child: SalomonBottomBar(
                            backgroundColor: setAppBarColor(context),
                            items: getNavigationBarDestinations(context),
                            currentIndex: navigationIndex,
                            onTap: (i) => setState(() {
                              navigationIndex = i;
                              _isVisible = true;
                            }),
                            itemPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            selectedItemColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isVisible) {
              setState(() {
                _isVisible = false;
              });
            }
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isVisible) {
              setState(() {
                _isVisible = true;
              });
            }
          }
          return false;
        },
        child: IndexedStack(
          index: navigationIndex,
          children: const [Search(), Library(), Settings()],
        ),
      ),
    );
  }
}
