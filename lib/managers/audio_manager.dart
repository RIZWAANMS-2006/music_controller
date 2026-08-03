import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioManager {
  // Singleton Logic
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioPlayer _player = AudioPlayer();
  final List<AudioPlayer> _fadingPlayers = [];

  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _stateController = StreamController<PlayerState>.broadcast();

  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;

  AudioManager._internal() {
    _attachStreams();
  }

  void _attachStreams() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _posSub = _player.positionStream.listen((pos) => _positionController.add(pos));
    _stateSub = _player.playerStateStream.listen((state) => _stateController.add(state));
  }

  // Core Player
  AudioPlayer get instance => _player;

  // State
  String? currentSongPath;
  bool get isPlaying => _player.playing;
  Stream<Duration> get positionStream => _positionController.stream;
  Duration get totalDuration => _player.duration ?? Duration.zero;

  // Added playerStateStream for SongsManager auto-playing logic
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  // Main Logic
  Future<void> play(String path, {Duration? initialPosition, double crossfadeDuration = 0.0}) async {
    try {
      AudioPlayer? oldPlayer;
      if (crossfadeDuration > 0.0 && _player.playing && currentSongPath != path) {
        oldPlayer = _player;
        _fadingPlayers.add(oldPlayer);
        
        _player = AudioPlayer();
        _attachStreams();
      }

      currentSongPath = path;
      if (path.startsWith('http:') || path.startsWith('https:')) {
        await _player.setUrl(path); // Cloud
      } else {
        await _player.setAudioSource(AudioSource.uri(Uri.file(path))); // Local
      }

      if (initialPosition != null && initialPosition > Duration.zero) {
        await _player.seek(initialPosition);
      }

      if (crossfadeDuration > 0.0 && oldPlayer != null) {
        // Start fading simultaneously only after new player is ready
        _fadeOutAndDispose(oldPlayer, crossfadeDuration);
        _fadeIn(_player, crossfadeDuration);
      } else if (crossfadeDuration <= 0.0 && oldPlayer != null) {
        // If no crossfade but we spawned a new player somehow
        oldPlayer.stop();
        oldPlayer.dispose();
        _fadingPlayers.remove(oldPlayer);
        await _player.setVolume(1.0);
      } else {
        await _player.setVolume(1.0);
      }

      _player.play();
    } catch (e) {}
  }

  void _fadeOutAndDispose(AudioPlayer p, double duration) {
    int steps = 20;
    int interval = (duration * 1000 ~/ steps);
    if (interval <= 0) interval = 1;
    double stepVol = p.volume / steps;
    Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (p.volume - stepVol <= 0) {
        p.stop();
        p.dispose();
        _fadingPlayers.remove(p);
        timer.cancel();
      } else {
        p.setVolume(p.volume - stepVol);
      }
    });
  }

  void _fadeIn(AudioPlayer p, double duration) {
    p.setVolume(0.0);
    int steps = 20;
    int interval = (duration * 1000 ~/ steps);
    if (interval <= 0) interval = 1;
    double stepVol = 1.0 / steps;
    Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (p.volume + stepVol >= 1.0) {
        p.setVolume(1.0);
        timer.cancel();
      } else {
        p.setVolume(p.volume + stepVol);
      }
    });
  }

  // Simple Controls
  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration pos) => _player.seek(pos);

  Future<void> stop() async {
    await _player.stop();
    for (var p in _fadingPlayers) {
      p.stop();
      p.dispose();
    }
    _fadingPlayers.clear();
    currentSongPath = null;
  }
}
