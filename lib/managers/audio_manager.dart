import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// AudioManager with native OS notification media controls support.
/// Uses a single primary AudioPlayer tagged with MediaItem so the
/// Android notification drawer, lockscreen, and Windows SMTC show
/// the correct track info and expose Play/Pause/Skip buttons.
class AudioManager {
  // Singleton Logic
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  /// Primary player - the one that drives the OS notification
  final AudioPlayer _player = AudioPlayer();

  /// Secondary player used only during crossfade transitions
  AudioPlayer? _crossfadePlayer;

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();

  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;

  AudioManager._internal() {
    _attachStreams();
  }

  void _attachStreams() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _posSub = _player.positionStream
        .listen((pos) => _positionController.add(pos));
    _stateSub = _player.playerStateStream
        .listen((state) => _stateController.add(state));
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// The primary player (used for direct volume/position queries)
  AudioPlayer get instance => _player;

  String? currentSongPath;
  bool get isPlaying => _player.playing;
  Stream<Duration> get positionStream => _positionController.stream;
  Duration get totalDuration => _player.duration ?? Duration.zero;
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  // ── Playback ───────────────────────────────────────────────────────────────

  Future<void> play(
    String path, {
    Duration? initialPosition,
    double crossfadeDuration = 0.0,
    String? title,
    String? artist,
    Uri? artUri,
  }) async {
    try {
      final cleanTitle =
          title ?? path.split('/').last.split(Platform.pathSeparator).last;

      final mediaItem = MediaItem(
        id: path,
        album: 'Rusic',
        title: cleanTitle,
        artist: artist ?? 'Unknown Artist',
        artUri: artUri,
      );

      final AudioSource source = path.startsWith('http:') ||
              path.startsWith('https:')
          ? AudioSource.uri(Uri.parse(path), tag: mediaItem)
          : AudioSource.uri(Uri.file(path), tag: mediaItem);

      final bool wasCrossfading =
          crossfadeDuration > 0.0 && _player.playing && currentSongPath != path;

      if (wasCrossfading) {
        // ── Crossfade: fade out old via a temporary copy, fade in new on main ─
        await _startCrossfade(crossfadeDuration);
      }

      currentSongPath = path;
      await _player.setAudioSource(source);

      if (initialPosition != null && initialPosition > Duration.zero) {
        await _player.seek(initialPosition);
      }

      if (wasCrossfading) {
        await _player.setVolume(0.0);
        _player.play();
        _fadeIn(_player, crossfadeDuration);
      } else {
        await _player.setVolume(1.0);
        _player.play();
      }
    } catch (e) {
      debugPrint('[AudioManager] play error: $e');
    }
  }

  Future<void> _startCrossfade(double duration) async {
    // Dispose any lingering crossfade player first
    await _crossfadePlayer?.stop();
    _crossfadePlayer?.dispose();
    _crossfadePlayer = null;

    // Snapshot current path + position before we overwrite them
    final oldPath = currentSongPath;
    final oldPosition = _player.position;
    final oldVolume = _player.volume;

    if (oldPath == null) return;

    // Spawn a temporary player to continue the old track while we fade
    final tempPlayer = AudioPlayer();
    _crossfadePlayer = tempPlayer;

    try {
      final AudioSource oldSource = oldPath.startsWith('http:') ||
              oldPath.startsWith('https:')
          ? AudioSource.uri(Uri.parse(oldPath))
          : AudioSource.uri(Uri.file(oldPath));

      await tempPlayer.setAudioSource(oldSource);
      await tempPlayer.seek(oldPosition);
      await tempPlayer.setVolume(oldVolume);
      tempPlayer.play();

      // Fade out the temp player in the background
      _fadeOutAndDispose(tempPlayer, duration);
    } catch (_) {
      tempPlayer.dispose();
      _crossfadePlayer = null;
    }
  }

  void _fadeOutAndDispose(AudioPlayer p, double duration) {
    const steps = 20;
    final interval = Duration(
      milliseconds: ((duration * 1000) ~/ steps).clamp(1, 10000),
    );
    final stepVol = p.volume / steps;

    Timer.periodic(interval, (timer) {
      if (p.volume - stepVol <= 0) {
        p.stop();
        p.dispose();
        if (identical(p, _crossfadePlayer)) _crossfadePlayer = null;
        timer.cancel();
      } else {
        p.setVolume((p.volume - stepVol).clamp(0.0, 1.0));
      }
    });
  }

  void _fadeIn(AudioPlayer p, double duration) {
    p.setVolume(0.0);
    const steps = 20;
    final interval = Duration(
      milliseconds: ((duration * 1000) ~/ steps).clamp(1, 10000),
    );
    const stepVol = 1.0 / steps;

    Timer.periodic(interval, (timer) {
      if (p.volume + stepVol >= 1.0) {
        p.setVolume(1.0);
        timer.cancel();
      } else {
        p.setVolume((p.volume + stepVol).clamp(0.0, 1.0));
      }
    });
  }

  // ── Controls ───────────────────────────────────────────────────────────────

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration pos) => _player.seek(pos);

  Future<void> stop() async {
    await _player.stop();
    await _crossfadePlayer?.stop();
    _crossfadePlayer?.dispose();
    _crossfadePlayer = null;
    currentSongPath = null;
  }
}
