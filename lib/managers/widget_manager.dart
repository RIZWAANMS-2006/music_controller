import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'package:Rusic/managers/audio_manager.dart';
import 'package:Rusic/managers/songs_manager.dart';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri == null) return;
  
  if (uri.host == 'playpause') {
    if (AudioManager().isPlaying) {
      await AudioManager().pause();
    } else {
      await AudioManager().resume();
    }
  } else if (uri.host == 'next') {
    await SongsManager().playNext();
  } else if (uri.host == 'prev') {
    await SongsManager().playPrevious();
  } else if (uri.host == 'loop') {
    SongsManager().toggleRepeat();
  } else if (uri.host == 'shuffle') {
    SongsManager().toggleShuffle();
  }
}

class WidgetManager {
  static const String androidWidgetName = 'MusicWidgetProvider';
  
  static Future<void> initWidget() async {
    await HomeWidget.setAppGroupId('group.rusic.app'); // Required for iOS, ignored on Android
    
    // Register background callback for widget button clicks
    await HomeWidget.registerInteractivityCallback(backgroundCallback);

    // Listen to changes and update the widget
    _listenToPlaybackState();
    _listenToMetadata();
    _listenToPosition();
    _listenToModes();
  }

  static void _listenToPlaybackState() {
    AudioManager().playerStateStream.listen((state) async {
      await HomeWidget.saveWidgetData<bool>('isPlaying', state.playing);
      _updateWidget();
    });
  }

  static void _listenToMetadata() {
    SongsManager().addListener(() async {
      final currentSong = SongsManager().currentSong;
      if (currentSong != null) {
        await HomeWidget.saveWidgetData<String>('title', currentSong.title);
      } else {
        await HomeWidget.saveWidgetData<String>('title', 'Not Playing');
      }
      _updateWidget();
    });
  }
  
  static void _listenToModes() {
    SongsManager().addListener(() async {
      final loopMode = SongsManager().repeatMode;
      final shuffleMode = SongsManager().isShuffle;
      
      String loopStr = 'off';
      if (loopMode == RepeatMode.all) loopStr = 'all';
      if (loopMode == RepeatMode.one) loopStr = 'one';
      
      await HomeWidget.saveWidgetData<String>('loopMode', loopStr);
      await HomeWidget.saveWidgetData<bool>('shuffleMode', shuffleMode);
      _updateWidget();
    });
  }

  // To save battery, we might not want to update position every millisecond.
  // Updating it every second is okay while app is foregrounded.
  static DateTime? _lastUpdate;
  
  static void _listenToPosition() {
    AudioManager().positionStream.listen((pos) async {
      final now = DateTime.now();
      // Throttle updates to at most once per 2 seconds to save battery
      if (_lastUpdate == null || now.difference(_lastUpdate!).inSeconds >= 2) {
        _lastUpdate = now;
        
        final duration = AudioManager().totalDuration;
        int progressPercent = 0;
        if (duration.inMilliseconds > 0) {
          progressPercent = ((pos.inMilliseconds / duration.inMilliseconds) * 1000).toInt(); // out of 1000
        }
        
        await HomeWidget.saveWidgetData<int>('progress', progressPercent);
        _updateWidget();
      }
    });
  }

  static Future<void> _updateWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: androidWidgetName,
      );
    } catch (e) {
      // Handle widget update error
    }
  }
}