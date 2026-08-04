import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:Rusic/managers/audio_manager.dart';
import 'package:Rusic/managers/songs_manager.dart';
import 'package:Rusic/managers/database_manager.dart';

/// A notification-card styled Music Control Panel widget.
/// Displays currently playing song metadata, interactive playback controls,
/// seeking progress bar, volume control, and expandable details.
class NotificationMusicPanel extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isDismissible;

  const NotificationMusicPanel({
    super.key,
    this.onClose,
    this.isDismissible = true,
  });

  @override
  State<NotificationMusicPanel> createState() => _NotificationMusicPanelState();
}

class _NotificationMusicPanelState extends State<NotificationMusicPanel> {
  bool _isExpanded = false;
  bool _isLiked = false;
  double _volume = 1.0;
  bool _isDraggingSeek = false;
  double _dragSeekValue = 0.0;

  @override
  void initState() {
    super.initState();
    _volume = AudioManager().instance.volume;
    _checkLikedStatus();
  }

  Future<void> _checkLikedStatus() async {
    final currentSong = SongsManager().currentSong;
    if (currentSong != null) {
      final isFav = await DatabaseManager.instance.isFavorite(currentSong.path);
      if (mounted) {
        setState(() {
          _isLiked = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final currentSong = SongsManager().currentSong;
    if (currentSong == null) return;

    if (_isLiked) {
      await DatabaseManager.instance.removeFavorite(currentSong.path);
    } else {
      await DatabaseManager.instance.addFavorite(currentSong.path);
    }

    if (mounted) {
      setState(() {
        _isLiked = !_isLiked;
      });
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SongsManager(),
      builder: (context, _) {
        final songsManager = SongsManager();
        final currentSong = songsManager.currentSong;

        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        _checkLikedStatus();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.75),
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header bar: Notification tag & Expand/Collapse toggle
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "NOW PLAYING",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            onPressed: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                          ),
                          if (widget.isDismissible && widget.onClose != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                              ),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Song info & main playback row
                      Row(
                        children: [
                          // Album Artwork / Icon
                          Container(
                            width: _isExpanded ? 64 : 48,
                            height: _isExpanded ? 64 : 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.redAccent.shade200,
                                  Colors.red.shade700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Title and Artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextScroll(
                                  currentSong.title,
                                  velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                                  pauseBetween: const Duration(seconds: 2),
                                  style: TextStyle(
                                    fontSize: _isExpanded ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSong.artist ?? "Unknown Artist",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quick Control buttons in compact mode
                          if (!_isExpanded) ...[
                            StreamBuilder<PlayerState>(
                              stream: AudioManager().playerStateStream,
                              builder: (context, snapshot) {
                                final playing = AudioManager().isPlaying;
                                return IconButton(
                                  icon: Icon(
                                    playing
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_fill_rounded,
                                    size: 36,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    if (playing) {
                                      AudioManager().pause();
                                    } else {
                                      AudioManager().resume();
                                    }
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 28,
                              ),
                              onPressed: () => songsManager.playNext(),
                            ),
                          ],
                        ],
                      ),

                      // Progress Bar & Duration Timestamps
                      StreamBuilder<Duration>(
                        stream: AudioManager().positionStream,
                        builder: (context, snapshot) {
                          final currentPos = snapshot.data ?? Duration.zero;
                          final totalDur = AudioManager().totalDuration;
                          final maxMs = totalDur.inMilliseconds.toDouble();
                          final currentMs = currentPos.inMilliseconds
                              .toDouble()
                              .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

                          final sliderValue = _isDraggingSeek
                              ? _dragSeekValue
                              : currentMs;

                          return Column(
                            children: [
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: _isExpanded ? 4 : 2,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: _isExpanded ? 6 : 4,
                                  ),
                                  activeTrackColor: Colors.redAccent,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: sliderValue.clamp(
                                    0.0,
                                    maxMs > 0 ? maxMs : 1.0,
                                  ),
                                  max: maxMs > 0 ? maxMs : 1.0,
                                  onChangeStart: (val) {
                                    setState(() {
                                      _isDraggingSeek = true;
                                      _dragSeekValue = val;
                                    });
                                  },
                                  onChanged: (val) {
                                    setState(() {
                                      _dragSeekValue = val;
                                    });
                                  },
                                  onChangeEnd: (val) {
                                    _isDraggingSeek = false;
                                    AudioManager().seek(
                                      Duration(milliseconds: val.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(
                                        Duration(
                                          milliseconds: sliderValue.toInt(),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(totalDur),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Expanded Controls Section
                      if (_isExpanded) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Favorite Button
                            IconButton(
                              icon: Icon(
                                _isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: _isLiked ? Colors.red : Colors.grey,
                              ),
                              onPressed: _toggleFavorite,
                            ),

                            // Shuffle Button
                            IconButton(
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: songsManager.isShuffle
                                    ? Colors.redAccent
                                    : Colors.grey,
                              ),
                              onPressed: () => songsManager.toggleShuffle(),
                            ),

                            // Play Previous Button
                            IconButton(
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                size: 32,
                              ),
                              onPressed: () => songsManager.playPrevious(),
                            ),

                            // Play/Pause Button
                            StreamBuilder<PlayerState>(
                              stream: AudioManager().playerStateStream,
                              builder: (context, snapshot) {
                                final playing = AudioManager().isPlaying;
                                return CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.redAccent,
                                  child: IconButton(
                                    icon: Icon(
                                      playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      if (playing) {
                                        AudioManager().pause();
                                      } else {
                                        AudioManager().resume();
                                      }
                                    },
                                  ),
                                );
                              },
                            ),

                            // Play Next Button
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 32,
                              ),
                              onPressed: () => songsManager.playNext(),
                            ),

                            // Repeat Button
                            IconButton(
                              icon: Icon(
                                songsManager.repeatMode == RepeatMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                                color: songsManager.repeatMode != RepeatMode.off
                                    ? Colors.redAccent
                                    : Colors.grey,
                              ),
                              onPressed: () => songsManager.toggleRepeat(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Volume Control Slider
                        Row(
                          children: [
                            Icon(
                              _volume == 0
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_down_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: const SliderThemeData(
                                  trackHeight: 3,
                                  activeTrackColor: Colors.redAccent,
                                  inactiveTrackColor: Colors.grey,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 5,
                                  ),
                                ),
                                child: Slider(
                                  value: _volume,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) {
                                    setState(() {
                                      _volume = val;
                                    });
                                    AudioManager().instance.setVolume(val);
                                  },
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.volume_up_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Helper function to present the Notification Music Panel as a modal bottom sheet.
void showNotificationMusicPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        child: NotificationMusicPanel(
          onClose: () => Navigator.pop(context),
        ),
      );
    },
  );
}
