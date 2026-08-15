import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:lottie/lottie.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Rusic/music_player/dynamic_background.dart';
import 'package:Rusic/managers/audio_manager.dart';
import "package:Rusic/managers/ui_manager.dart";
import 'package:Rusic/managers/songs_manager.dart';
import 'package:Rusic/managers/video_manager.dart';
import 'package:Rusic/managers/database_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:Rusic/managers/settings_manager.dart';


bool _isDragging = false;
double _dragValue = 0.0;

class MusicQueueScreen extends StatefulWidget {
  final BuildContext? context;
  const MusicQueueScreen({super.key, this.context});

  @override
  State<MusicQueueScreen> createState() => _MusicQueueScreenState();
}

class _MusicQueueScreenState extends State<MusicQueueScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SongsManager(),
      builder: (context, _) {
        final songsManager = SongsManager();
        final currentSong = songsManager.currentSong;
        final upNext = [];
        if (songsManager.currentQueue.isNotEmpty &&
            songsManager.currentIndex >= 0 &&
            songsManager.currentIndex < songsManager.currentQueue.length - 1) {
          upNext.addAll(
            songsManager.currentQueue.sublist(songsManager.currentIndex + 1),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text("Playing Queue"),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Now Playing",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  currentSong?.title ?? "No Song is Playing...",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: currentSong?.artist != null
                    ? Text(
                        currentSong!.artist!,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      )
                    : null,
                trailing: Icon(
                  Icons.equalizer,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Divider(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                indent: 16,
                endIndent: 16,
              ),
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  "Up Next",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: upNext.length,
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = upNext.removeAt(oldIndex);
                      upNext.insert(newIndex, item);
                      songsManager.reorderQueue(
                        songsManager.currentIndex + 1 + oldIndex,
                        songsManager.currentIndex + 1 + newIndex,
                      );
                    });
                  },
                  itemBuilder: (context, index) {
                    final songItem = upNext[index];
                    return ListTile(
                      key: ValueKey(songItem.id),
                      leading: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      title: Text(
                        songItem.title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      subtitle: songItem.artist != null
                          ? Text(
                              songItem.artist!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            )
                          : null,
                      trailing: Icon(
                        Icons.drag_handle,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MusicProgressBar extends StatefulWidget {
  const MusicProgressBar({super.key});

  @override
  State<MusicProgressBar> createState() => _MusicProgressBarState();
}

class _MusicProgressBarState extends State<MusicProgressBar> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: AudioManager().positionStream,
      builder: (context, snapshot) {
        final totalDuration = AudioManager().totalDuration;
        final currentPosition = snapshot.data ?? Duration.zero;
        double max = totalDuration.inSeconds.toDouble();
        if (max <= 0) max = 1.0;
        double value = _isDragging
            ? _dragValue
            : currentPosition.inSeconds.toDouble();
        if (value > max) value = max;

        return Slider(
          min: 0,
          max: max,
          value: value,
          thumbColor: const Color.fromRGBO(255, 0, 0, 1),
          activeColor: const Color.fromRGBO(255, 0, 0, 1),
          inactiveColor: const Color.fromRGBO(255, 0, 0, 0.3),
          onChanged: (newValue) {
            setState(() {
              _isDragging = true;
              _dragValue = newValue;
            });
          },
          onChangeEnd: (newValue) {
            AudioManager().seek(Duration(seconds: newValue.toInt()));
            setState(() {
              _isDragging = false;
            });
          },
        );
      },
    );
  }
}

class BottomMusicController extends StatefulWidget {
  final double? width;
  const BottomMusicController({super.key, this.width});

  @override
  State<BottomMusicController> createState() => BottomMusicControllerState();
}

class BottomMusicControllerState extends State<BottomMusicController> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SongsManager(),
      builder: (context, _) {
        final currentSong = SongsManager().currentSong;
        return GestureDetector(
          onTap: () => setState(() {
            setState(() {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (context, animation, secondaryanimation) {
                    return const FullSizeMusicController();
                  },
                ),
              );
            });
          }),
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 0) {
              SongsManager().playPrevious();
            } else if (velocity < 0) {
              SongsManager().playNext();
            }
          },
          onDoubleTap: () {
            AudioManager().isPlaying
                ? AudioManager().pause()
                : AudioManager().resume();
          },
          child: Container(
            alignment: Alignment.center,
            width: (MediaQuery.of(context).size.width / 2),
            height: 55,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: setContainerContrastColor(context),
              borderRadius: const BorderRadius.all(Radius.circular(40)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(125, 0, 0, 0),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: Hero(
                              tag: "Music Logo",
                              child: Container(
                                width: 45,
                                height: 45,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: setContainerColor(context),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: SvgPicture.asset(
                                  "assets/MusicIcons/music_logo_black.svg",
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge!.color!,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 8,
                                bottom: 2,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final text = currentSong == null
                                      ? "No Song is Playing..."
                                      : currentSong.title;
                                  final style = TextStyle(
                                    color: setContainerColor(context),
                                    fontSize: 12,
                                  );

                                  final textPainter = TextPainter(
                                    text: TextSpan(text: text, style: style),
                                    maxLines: 1,
                                    textDirection:
                                        Directionality.maybeOf(context) ??
                                        TextDirection.ltr,
                                    textScaler: MediaQuery.of(
                                      context,
                                    ).textScaler,
                                  )..layout(maxWidth: double.infinity);

                                  final bool isOverflowing =
                                      textPainter.width > constraints.maxWidth;

                                  if (isOverflowing) {
                                    return TextScroll(
                                      text,
                                      velocity: const Velocity(
                                        pixelsPerSecond: Offset(30, 0),
                                      ),
                                      pauseBetween: const Duration(seconds: 2),
                                      mode: TextScrollMode.endless,
                                      style: style,
                                    );
                                  } else {
                                    return Text(
                                      text,
                                      maxLines: 1,
                                      style: style,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (constraints.maxWidth >= 210)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: StreamBuilder<PlayerState>(
                          stream: AudioManager().playerStateStream,
                          builder: (context, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            return IconButton(
                              icon: SvgPicture.asset(
                                playing
                                    ? "assets/MusicIcons/pause.svg"
                                    : "assets/MusicIcons/play.svg",
                                color: setContainerColor(context),
                                width: 18,
                                height: 18,
                              ),
                              onPressed: () {
                                playing
                                    ? AudioManager().pause()
                                    : AudioManager().resume();
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),

            // Padding(
            //   padding: const EdgeInsets.only(right: 8),
            //   child: StreamBuilder<PlayerState>(
            //     stream: AudioManager().playerStateStream,
            //     builder: (context, snapshot) {
            //       final playing = snapshot.data?.playing ?? false;
            //       return IconButton(
            //         icon: SvgPicture.asset(
            //           playing
            //               ? "assets/MusicIcons/pause.svg"
            //               : "assets/MusicIcons/play.svg",
            //           color: setContainerColor(context),
            //           width: 25,
            //           height: 25,
            //         ),
            //         onPressed: () {
            //           playing
            //               ? AudioManager().pause()
            //               : AudioManager().resume();
            //         },
            //       );
            // },
            // ),

            // IconButton(
            //   onPressed: () {
            //     SongsManager().toggleRepeat();
            //   },
            //   icon: SvgPicture.asset(
            //     "assets/MusicIcons/loop.svg",
            //     color: SongsManager().repeatMode.name != 'off'
            //         ? Colors.red
            //         : setContainerColor(context),
            //   ),
            // ),
            // IconButton(
            //   onPressed: () {
            //     SongsManager().toggleShuffle();
            //   },
            //   icon: SvgPicture.asset(
            //     "assets/MusicIcons/shuffle.svg",
            //     color: SongsManager().isShuffle
            //         ? Colors.red
            //         : setContainerColor(context),
            //   ),
            // ),
            // ),
          ),
        );
      },
    );
  }
}

class CustomToggleSwitch extends StatefulWidget {
  const CustomToggleSwitch({super.key});

  @override
  State<CustomToggleSwitch> createState() => _CustomToggleSwitchState();
}

class _CustomToggleSwitchState extends State<CustomToggleSwitch> {
  bool isAudioSelected = false;

  @override
  Widget build(BuildContext context) {
    const double width = 300.0;
    const double height = 60.0;

    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(50.0),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: isAudioSelected
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Container(
                width: width * 0.5,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isAudioSelected = true;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.transparent,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize:
                                14, // Set a more readable default size that scales down if needed
                            fontWeight: FontWeight.w500,
                            color: isAudioSelected
                                ? Colors.white
                                : Colors.black,
                            fontFamily: 'Quicksand',
                          ),
                          child: const Text(
                            "Audio",
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isAudioSelected = false;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.transparent,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isAudioSelected
                                ? Colors.black
                                : Colors.white,
                            fontFamily: 'Quicksand',
                          ),
                          child: const Text(
                            "Video",
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

double i = 0;

class FullSizeMusicController extends StatefulWidget {
  const FullSizeMusicController({super.key});

  @override
  State<FullSizeMusicController> createState() =>
      _FullSizeMusicControllerState();
}

class _FullSizeMusicControllerState extends State<FullSizeMusicController> {
  late CurvedAnimation curved;
  bool isQueueOpen = false;
  bool _showLikeAnimation = false;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // curved.dispose(); // No controller passed to curved so removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 100) {
          Navigator.of(context).pop();
        }
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 0) {
          SongsManager().playPrevious();
        } else if (velocity < 0) {
          SongsManager().playNext();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          SongsManager(),
          DatabaseManager.instance,
          SettingsManager.appUI,
        ]),
        builder: (context, _) {
          final currentSong = SongsManager().currentSong;
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isEmbedded = ModalRoute.of(context)?.isFirst ?? true;
              return (constraints.maxWidth < 700 || isEmbedded)
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return DefaultTabController(
                          length: 2,
                          child: Scaffold(
                            key: const ValueKey('displaySize<700'),
                            backgroundColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            extendBodyBehindAppBar: true,
                            extendBody: true,
                            bottomNavigationBar: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: isQueueOpen
                                  ? Theme.of(context).scaffoldBackgroundColor
                                  : Colors.transparent,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const MusicProgressBar(),
                                  Container(
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      spacing: 10,
                                      children: [
                                        IconButton(
                                          icon: SvgPicture.asset(
                                            "assets/MusicIcons/shuffle.svg",
                                            color: currentSong == null
                                                ? Colors.white24
                                                : (SongsManager().isShuffle
                                                      ? Colors.red
                                                      : Theme.of(
                                                          context,
                                                        ).iconTheme.color),
                                            width: 20,
                                            height: 20,
                                          ),
                                          onPressed: currentSong == null
                                              ? null
                                              : () {
                                                  SongsManager()
                                                      .toggleShuffle();
                                                },
                                        ),
                                        IconButton(
                                          icon: SvgPicture.asset(
                                            "assets/MusicIcons/previous_button.svg",
                                            color: currentSong == null
                                                ? Colors.white24
                                                : (SongsManager().isShuffle
                                                      ? Colors.red
                                                      : Theme.of(
                                                          context,
                                                        ).iconTheme.color),
                                            width: 20,
                                            height: 20,
                                          ),
                                          onPressed: currentSong == null
                                              ? null
                                              : () {
                                                  SongsManager().playPrevious();
                                                },
                                        ),
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: currentSong == null
                                                    ? const Color.fromRGBO(
                                                        255,
                                                        0,
                                                        0,
                                                        0.4,
                                                      )
                                                    : const Color.fromRGBO(
                                                        255,
                                                        0,
                                                        0,
                                                        1,
                                                      ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            StreamBuilder<PlayerState>(
                                              stream: AudioManager()
                                                  .instance
                                                  .playerStateStream,
                                              builder: (context, snapshot) {
                                                final playing =
                                                    snapshot.data?.playing ??
                                                    false;
                                                return IconButton(
                                                  icon: SvgPicture.asset(
                                                    playing
                                                        ? "assets/MusicIcons/pause.svg"
                                                        : "assets/MusicIcons/play.svg",
                                                    color: currentSong == null
                                                        ? Colors.white60
                                                        : null,
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                  onPressed: currentSong == null
                                                      ? null
                                                      : () {
                                                          playing
                                                              ? AudioManager()
                                                                    .pause()
                                                              : AudioManager()
                                                                    .resume();
                                                        },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: SvgPicture.asset(
                                            "assets/MusicIcons/next_button.svg",
                                            color: currentSong == null
                                                ? Colors.white24
                                                : (SongsManager().isShuffle
                                                      ? Colors.red
                                                      : Theme.of(
                                                          context,
                                                        ).iconTheme.color),
                                            width: 20,
                                            height: 20,
                                          ),
                                          onPressed: currentSong == null
                                              ? null
                                              : () {
                                                  SongsManager().playNext();
                                                },
                                        ),
                                        IconButton(
                                          icon: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 7.0,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/MusicIcons/loop.svg",
                                                  color: currentSong == null
                                                      ? Colors.white24
                                                      : (SongsManager()
                                                                .isShuffle
                                                            ? Colors.red
                                                            : Theme.of(context)
                                                                  .iconTheme
                                                                  .color),
                                                  width: 20,
                                                  height: 20,
                                                ),
                                                const SizedBox(height: 3),
                                                Container(
                                                  width: 4,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        SongsManager()
                                                                .repeatMode ==
                                                            RepeatMode.one
                                                        ? (currentSong == null
                                                              ? Colors.white24
                                                              : Colors.red)
                                                        : Colors.transparent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          onPressed: currentSong == null
                                              ? null
                                              : () {
                                                  SongsManager().toggleRepeat();
                                                },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 15,
                                      bottom: 30,
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        return FilledButton.icon(
                                          icon: Icon(
                                            isQueueOpen
                                                ? Icons.close
                                                : Icons.queue_music,
                                            size: 15,
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(context)
                                                .navigationRailTheme
                                                .backgroundColor,
                                            disabledForegroundColor:
                                                Colors.white60,
                                          ),
                                          onPressed: currentSong == null
                                              ? null
                                              : () {
                                                  if (isQueueOpen) {
                                                    Navigator.pop(context);
                                                  } else {
                                                    setState(() {
                                                      isQueueOpen = true;
                                                    });
                                                    Scaffold.of(context)
                                                        .showBottomSheet((
                                                          context,
                                                        ) {
                                                          return ClipRRect(
                                                            borderRadius:
                                                                const BorderRadius.vertical(
                                                                  top:
                                                                      Radius.circular(
                                                                        20,
                                                                      ),
                                                                ),
                                                            child: SizedBox(
                                                              height:
                                                                  MediaQuery.of(
                                                                        context,
                                                                      )
                                                                      .size
                                                                      .height *
                                                                  0.65,
                                                              child:
                                                                  MusicQueueScreen(
                                                                    context:
                                                                        context,
                                                                  ),
                                                            ),
                                                          );
                                                        })
                                                        .closed
                                                        .then((_) {
                                                          if (mounted) {
                                                            setState(() {
                                                              isQueueOpen =
                                                                  false;
                                                            });
                                                          }
                                                        });
                                                  }
                                                },
                                          label: Text(
                                            isQueueOpen ? "Close" : "Queue",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .navigationRailTheme
                                                  .backgroundColor,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            appBar: AppBar(
                              surfaceTintColor: Colors.transparent,
                              backgroundColor: Colors.transparent,
                              automaticallyImplyLeading: false,
                              leading: MediaQuery.of(context).size.width < 700
                                  ? IconButton(
                                      icon: SvgPicture.asset(
                                        "assets/MusicIcons/down_arrow.svg",
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    )
                                  : const SizedBox.shrink(),
                              leadingWidth:
                                  MediaQuery.of(context).size.width < 700
                                  ? kToolbarHeight
                                  : 0,
                            ),
                            body: GestureDetector(
                              onDoubleTapDown: (details) {
                                _tapPosition = details.localPosition;
                              },
                              onDoubleTap: () async {
                                if (currentSong != null) {
                                  await DatabaseManager.instance.addFavorite(
                                    currentSong.path,
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _showLikeAnimation = true;
                                      Future.delayed(
                                        const Duration(milliseconds: 1500),
                                        () {
                                          if (mounted) {
                                            setState(() {
                                              _showLikeAnimation = false;
                                              _tapPosition = null;
                                            });
                                          }
                                        },
                                      );
                                    });
                                  }
                                }
                              },
                              child: Stack(
                                children: [
                                  SettingsManager.appUI.value == "Weather Theme"
                                      ? ImageFiltered(
                                          imageFilter: ImageFilter.blur(
                                            sigmaX: 5,
                                            sigmaY: 5,
                                          ),
                                          child: const WeatherBackground(),
                                        )
                                      : const SizedBox.shrink(),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top:
                                          MediaQuery.of(context).padding.top +
                                          kToolbarHeight,
                                      bottom: 180,
                                    ),
                                    child: AnimatedBuilder(
                                      animation: VideoManager(),
                                      builder: (context, _) {
                                        final isVideo =
                                            VideoManager().isVideoAvailable;
                                        return TabBarView(
                                          physics: isVideo
                                              ? const BouncingScrollPhysics()
                                              : const NeverScrollableScrollPhysics(),
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 5,
                                                          ),
                                                      child: IconButton(
                                                        icon: SvgPicture.asset(
                                                          currentSong != null &&
                                                                  DatabaseManager
                                                                      .instance
                                                                      .isFavoriteSync(
                                                                        currentSong
                                                                            .path,
                                                                      )
                                                              ? "assets/MusicIcons/liked.svg"
                                                              : "assets/MusicIcons/like.svg",
                                                          color:
                                                              currentSong ==
                                                                  null
                                                              ? Colors.white24
                                                              : (SongsManager()
                                                                        .isShuffle
                                                                    ? Colors.red
                                                                    : Theme.of(
                                                                        context,
                                                                      ).iconTheme.color),
                                                        ),
                                                        onPressed:
                                                            currentSong == null
                                                            ? null
                                                            : () async {
                                                                final isFav = DatabaseManager
                                                                    .instance
                                                                    .isFavoriteSync(
                                                                      currentSong
                                                                          .path,
                                                                    );
                                                                await DatabaseManager
                                                                    .instance
                                                                    .toggleFavorite(
                                                                      currentSong
                                                                          .path,
                                                                    );
                                                                if (!isFav &&
                                                                    mounted) {
                                                                  setState(() {
                                                                    _showLikeAnimation =
                                                                        true;
                                                                    Future.delayed(
                                                                      const Duration(
                                                                        milliseconds:
                                                                            1500,
                                                                      ),
                                                                      () {
                                                                        if (mounted) {
                                                                          setState(
                                                                            () {
                                                                              _showLikeAnimation = false;
                                                                            },
                                                                          );
                                                                        }
                                                                      },
                                                                    );
                                                                  });
                                                                }
                                                              },
                                                      ),
                                                    ),
                                                    Hero(
                                                      tag: "Music Logo",
                                                      child: Container(
                                                        height:
                                                            constraints
                                                                .maxWidth *
                                                            0.35,
                                                        width:
                                                            constraints
                                                                .maxWidth *
                                                            0.35,
                                                        constraints:
                                                            const BoxConstraints(
                                                              minHeight: 210,
                                                              minWidth: 210,
                                                              maxHeight: 300,
                                                              maxWidth: 300,
                                                            ),
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  setContainerContrastColor(context),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: SvgPicture.asset(
                                                          "assets/MusicIcons/music_logo_black.svg",
                                                          colorFilter: ColorFilter.mode(setContainerColor(context), BlendMode.srcIn),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 5,
                                                          ),
                                                      child: IconButton(
                                                        icon: SvgPicture.asset(
                                                          "assets/MusicIcons/add_playlist.svg",
                                                          color:
                                                              currentSong ==
                                                                  null
                                                              ? Colors.white24
                                                              : (SongsManager()
                                                                        .isShuffle
                                                                    ? Colors.red
                                                                    : Theme.of(
                                                                        context,
                                                                      ).iconTheme.color),
                                                        ),
                                                        onPressed:
                                                            currentSong == null
                                                            ? null
                                                            : () {},
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 20,
                                                      ),
                                                  child: Column(
                                                    spacing: 3,
                                                    children: [
                                                      Text(
                                                        "Song:",
                                                        textHeightBehavior:
                                                            const TextHeightBehavior(
                                                              applyHeightToLastDescent:
                                                                  false,
                                                            ),
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium!
                                                                  .color,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                        child: Text(
                                                          currentSong == null
                                                              ? "No Song is Playing..."
                                                              : currentSong
                                                                    .title,
                                                          textAlign:
                                                              TextAlign.center,
                                                          textHeightBehavior:
                                                              const TextHeightBehavior(
                                                                applyHeightToLastDescent:
                                                                    false,
                                                              ),
                                                          style: TextStyle(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .bodyMedium!
                                                                    .color,

                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ValueListenableBuilder<String>(
                                              valueListenable: SettingsManager
                                                  .videoPreference,
                                              builder: (context, videoPref, _) {
                                                return AnimatedBuilder(
                                                  animation: VideoManager(),
                                                  builder: (context, child) {
                                                    final isAvailable =
                                                        VideoManager()
                                                            .isVideoAvailable;
                                                    final controller =
                                                        VideoManager()
                                                            .controller;

                                                    if (!isAvailable ||
                                                        controller == null ||
                                                        !controller
                                                            .value
                                                            .isInitialized) {
                                                      return Container(
                                                        color: Colors.black,
                                                        alignment:
                                                            Alignment.center,
                                                        child: const Text(
                                                          "No Video Available\nFor The Playing Media",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    BoxFit fit = BoxFit.contain;
                                                    if (videoPref.contains(
                                                      "Cover",
                                                    )) {
                                                      fit = BoxFit.cover;
                                                    }

                                                    return SizedBox.expand(
                                                      child: FittedBox(
                                                        fit: fit,
                                                        child: SizedBox(
                                                          width: controller
                                                              .value
                                                              .size
                                                              .width,
                                                          height: controller
                                                              .value
                                                              .size
                                                              .height,
                                                          child: VideoPlayer(
                                                            controller,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 180,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 130,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: currentSong == null
                                                ? const Color.fromRGBO(
                                                    225,
                                                    225,
                                                    225,
                                                    0.4,
                                                  )
                                                : const Color.fromRGBO(
                                                    225,
                                                    225,
                                                    225,
                                                    1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              25.0,
                                            ),
                                          ),
                                          child: IgnorePointer(
                                            ignoring: currentSong == null,
                                            child: AnimatedBuilder(
                                              animation: VideoManager(),
                                              builder: (context, _) {
                                                final isVideo = VideoManager()
                                                    .isVideoAvailable;
                                                return TabBar(
                                                  labelPadding: EdgeInsets.zero,
                                                  indicatorSize:
                                                      TabBarIndicatorSize.tab,
                                                  indicator: BoxDecoration(
                                                    color: currentSong == null
                                                        ? const Color.fromRGBO(
                                                            34,
                                                            34,
                                                            34,
                                                            0.4,
                                                          )
                                                        : const Color.fromRGBO(
                                                            34,
                                                            34,
                                                            34,
                                                            1,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          25.0,
                                                        ),
                                                  ),
                                                  dividerColor:
                                                      Colors.transparent,
                                                  labelColor:
                                                      currentSong == null
                                                      ? Colors.white60
                                                      : Colors.white,
                                                  unselectedLabelColor:
                                                      currentSong == null
                                                      ? Colors.black38
                                                      : Colors.black,
                                                  splashBorderRadius:
                                                      BorderRadius.circular(
                                                        25.0,
                                                      ),
                                                  onTap: (index) {
                                                    if (!isVideo &&
                                                        index == 1) {
                                                      // Bounce back to Audio tab immediately
                                                      DefaultTabController.of(
                                                        context,
                                                      ).animateTo(0);
                                                    }
                                                  },
                                                  tabs: [
                                                    const Tab(
                                                      child: Text(
                                                        "Audio",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    Tab(
                                                      child: Opacity(
                                                        opacity: isVideo
                                                            ? 1.0
                                                            : 0.4,
                                                        child: const Text(
                                                          "Video",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_showLikeAnimation)
                                    Positioned(
                                      left: _tapPosition != null
                                          ? _tapPosition!.dx - 150
                                          : null,
                                      top: _tapPosition != null
                                          ? _tapPosition!.dy - 150
                                          : null,
                                      right: _tapPosition == null ? 0 : null,
                                      bottom: _tapPosition == null ? 0 : null,
                                      child: IgnorePointer(
                                        child: Center(
                                          child: Lottie.asset(
                                            "assets/lottie_files/like_animation.json",
                                            repeat: false,
                                            width: 300,
                                            height: 300,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Builder(
                      builder: (context) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        });
                        return const SizedBox.shrink();
                      },
                    );
            },
          );
        },
      ),
    );
  }
}

class HomePageMusicController extends StatefulWidget {
  const HomePageMusicController({super.key});

  @override
  State<HomePageMusicController> createState() =>
      _HomePageMusicControllerState();
}

class _HomePageMusicControllerState extends State<HomePageMusicController> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SongsManager(),
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.only(right: 20, left: 20),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.35 + 40,
            decoration: const BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              backgroundBlendMode: BlendMode.darken,
            ),
            child: (MediaQuery.of(context).size.width > 700)
                ? SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Container(
                            width: 250,
                            height: 200,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.music_note,
                              size: 80,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 40),
                            child: Container(
                              height: 200,
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                backgroundBlendMode: BlendMode.darken,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const MusicProgressBar(),
                                  SizedBox(
                                    width: 180,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.skip_previous,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                          onPressed: () {
                                            SongsManager().playPrevious();
                                          },
                                        ),
                                        StreamBuilder<PlayerState>(
                                          stream: AudioManager()
                                              .instance
                                              .playerStateStream,
                                          builder: (context, snapshot) {
                                            final playing =
                                                snapshot.data?.playing ?? false;
                                            return IconButton(
                                              icon: Icon(
                                                playing
                                                    ? Icons.pause_circle_filled
                                                    : Icons.play_circle_fill,
                                                size: 50,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                playing
                                                    ? AudioManager().pause()
                                                    : AudioManager().resume();
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.skip_next,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                          onPressed: () {
                                            SongsManager().playNext();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 30,
                            right: 30,
                            top: 20,
                            bottom: 20,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.rectangle,
                                  backgroundBlendMode: BlendMode.hardLight,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  size: 40,
                                  color: Colors.black,
                                ),
                              ),
                              const Expanded(child: MusicProgressBar()),
                              SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_previous,
                                        color: Colors.white,
                                        size: 35,
                                      ),
                                      onPressed: () {
                                        SongsManager().playPrevious();
                                      },
                                    ),
                                    StreamBuilder<PlayerState>(
                                      stream: AudioManager()
                                          .instance
                                          .playerStateStream,
                                      builder: (context, snapshot) {
                                        final playing =
                                            snapshot.data?.playing ?? false;
                                        return IconButton(
                                          alignment: Alignment.center,
                                          icon: Icon(
                                            playing
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_fill,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                          color: Colors.white,
                                          iconSize: 40,
                                          onPressed: () {
                                            playing
                                                ? AudioManager().pause()
                                                : AudioManager().resume();
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_next,
                                        color: Colors.white,
                                        size: 35,
                                      ),
                                      onPressed: () {
                                        SongsManager().playNext();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class SideMusicController extends StatefulWidget {
  const SideMusicController({super.key});

  @override
  State<SideMusicController> createState() => SideMusicControllerState();
}

class SideMusicControllerState extends State<SideMusicController> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([SongsManager(), SettingsManager.appUI]),
      builder: (context, _) {
        final currentSong = SongsManager().currentSong;
        return Stack(
          children: [
            SettingsManager.appUI.value == "Weather Theme"
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: const WeatherBackground(),
                  )
                : const SizedBox.shrink(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 15,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
                Text(
                  currentSong == null
                      ? "No Song is Playing..."
                      : currentSong.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const MusicProgressBar(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            SongsManager().toggleRepeat();
                          },
                          icon: Icon(
                            SongsManager().repeatMode == RepeatMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                            size: 35,
                            color: SongsManager().repeatMode != RepeatMode.off
                                ? Colors.red
                                : Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            SongsManager().playPrevious();
                          },
                          icon: const Icon(
                            Icons.skip_previous,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                        StreamBuilder<PlayerState>(
                          stream: AudioManager().playerStateStream,
                          builder: (context, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            return IconButton(
                              onPressed: () {
                                playing
                                    ? AudioManager().pause()
                                    : AudioManager().resume();
                              },
                              icon: Icon(
                                playing
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: Colors.white,
                                size: 40,
                              ),
                              color: Colors.black,
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            SongsManager().playNext();
                          },
                          icon: const Icon(
                            Icons.skip_next,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            SongsManager().toggleShuffle();
                          },
                          icon: Icon(
                            Icons.shuffle,
                            size: 35,
                            color: SongsManager().isShuffle
                                ? Colors.red
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
