import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:Rusic/music_player/music_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'music_player/music_player.dart';
import 'settings/settings.dart';
import 'search/search_page.dart';
import 'package:Rusic/managers/settings_manager.dart';
import 'package:Rusic/managers/ui_manager.dart';
import 'package:toastification/toastification.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:Rusic/managers/audio_manager.dart';
import 'package:Rusic/managers/songs_manager.dart';

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
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    // If an EditableText/TextField is currently focused, do not intercept keys
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.context != null) {
      final context = primaryFocus.context!;
      final isEditable =
          context.widget is EditableText ||
          context.findAncestorWidgetOfExactType<EditableText>() != null ||
          context.findAncestorWidgetOfExactType<TextField>() != null;
      if (isEditable) {
        return false;
      }
    }

    // Do not intercept if modifier keys like Ctrl, Alt, Meta are pressed
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (AudioManager().isPlaying) {
        AudioManager().pause();
      } else {
        AudioManager().resume();
      }
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      SongsManager().playNext();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      SongsManager().playPrevious();
      return true;
    }

    return false;
  }

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
            shortcuts: <ShortcutActivator, Intent>{
              ...WidgetsApp.defaultShortcuts,
              const SingleActivator(LogicalKeyboardKey.arrowLeft):
                  const DoNothingAndStopPropagationIntent(),
              const SingleActivator(LogicalKeyboardKey.arrowRight):
                  const DoNothingAndStopPropagationIntent(),
              const SingleActivator(LogicalKeyboardKey.space):
                  const DoNothingAndStopPropagationIntent(),
            },
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
            destinations: getNavigationRailDestinations(context),
            groupAlignment: 0,
            leading: IconButton(
              onPressed: toggleWideScreenPanels,
              icon: SvgPicture.asset(
                "assets/MusicIcons/swap.svg",
                colorFilter: ColorFilter.mode(
                  Theme.of(context).iconTheme.color!,
                  BlendMode.srcIn,
                ),
              ),
            ),
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
                              const VerticalDivider(
                                color: Color.fromRGBO(255, 245, 245, 0.3),
                                thickness: 0.5,
                                width: 0.5,
                              ),
                              SizedBox(
                                width: compactPaneWidth,
                                height: double.infinity,
                                child: contentPane,
                              ),
                            ]
                          : [
                              Expanded(child: contentPane),
                              const VerticalDivider(
                                color: Color.fromRGBO(255, 245, 245, 0.3),
                                thickness: 0.5,
                                width: 0.5,
                              ),
                              SizedBox(
                                width: compactPaneWidth,
                                height: double.infinity,
                                child: musicPane,
                              ),
                            ],
                    ),
                    // Positioned(
                    //   top: MediaQuery.of(context).padding.top + 4,
                    //   right: compactPaneWidth - 52,
                    //   child: IconButton(
                    //     onPressed: toggleWideScreenPanels,
                    //     icon: SvgPicture.asset(
                    //       "assets/MusicIcons/swap.svg",
                    //       colorFilter: ColorFilter.mode(
                    //         Theme.of(context).iconTheme.color!,
                    //         BlendMode.srcIn,
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
                : (_isVisible ? Offset.zero : const Offset(0, 1)),
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
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhysicalModel(
                        color: Colors.transparent,
                        // shadowColor: Colors.red,
                        shadowColor : setContainerColor(context),
                        elevation: 10,
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
