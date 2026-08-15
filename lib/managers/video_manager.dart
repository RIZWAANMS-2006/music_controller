import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:Rusic/managers/audio_manager.dart';
import 'package:Rusic/managers/songs_manager.dart';

class VideoManager extends ChangeNotifier {
  static final VideoManager _instance = VideoManager._internal();
  factory VideoManager() => _instance;

  VideoManager._internal() {
    // Sync play/pause state from AudioManager
    AudioManager().playerStateStream.listen((state) {
      if (_controller != null && _controller!.value.isInitialized) {
        if (state.playing) {
          _controller!.play();
        } else {
          _controller!.pause();
        }
      }
    });

    // Check for significant drift, and resync
    AudioManager().positionStream.listen((pos) {
      if (_controller != null && _controller!.value.isInitialized) {
        final diff = (_controller!.value.position - pos).inMilliseconds.abs();
        if (diff > 800) {
          // If drifted more than 800ms, resync with the audio
          _controller!.seekTo(pos);
        }
      }
    });
  }

  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;

  bool _isPlayingVideo = false;
  bool get isPlayingVideo => _isPlayingVideo;

  bool get isVideoAvailable {
    final currentSong = SongsManager().currentSong;
    if (currentSong == null) return false;
    final lowerPath = currentSong.path.toLowerCase();
    return lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mkv') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.webm') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.wmv');
  }

  Future<void> initializeVideo() async {
    if (!isVideoAvailable) return;

    final currentSong = SongsManager().currentSong!;
    final path = currentSong.path;

    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      _controller = VideoPlayerController.file(File(path));
    }

    try {
      await _controller!.initialize();

      // Mute the video player entirely; let just_audio handle sound and background play
      try {
        await _controller!.setVolume(0.0);
      } catch (e) {
        print('Error setting volume: $e');
      }

      // Sync initial state with AudioManager
      try {
        final currentPos = AudioManager().instance.position;
        await _controller!.seekTo(currentPos);
      } catch (e) {
        print('Error seeking to position: $e');
      }

      if (AudioManager().instance.playing ||
          AudioManager().instance.duration == null ||
          AudioManager().instance.duration == Duration.zero) {
        try {
          await _controller!.play();
          _isPlayingVideo = true;
        } catch (e) {
          print('Error playing video: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error initializing video: $e');
      _controller = null;
      _isPlayingVideo = false;
      notifyListeners();
    }
  }

  void disposeVideo() {
    _controller?.dispose();
    _controller = null;
    _isPlayingVideo = false;
    notifyListeners();
  }
}
