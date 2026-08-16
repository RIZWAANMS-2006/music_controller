import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Rusic/managers/credentials_manager.dart';
import 'package:Rusic/managers/server_manager/supabase_manager.dart';
import 'package:Rusic/managers/server_manager/server_manager.dart';
import 'package:Rusic/managers/database_manager.dart';
import 'package:Rusic/ui/media_ui.dart';

class OnlineScreen extends StatefulWidget {
  const OnlineScreen({super.key});

  @override
  State<OnlineScreen> createState() => OnlineScreenState();
}

class OnlineScreenState extends State<OnlineScreen> {
  Future<List<OnlineSong>>? _songsFuture;
  bool _isConfigured = false;
  bool _isLoading = true;
  StreamSubscription<void>? _configSubscription;

  @override
  void initState() {
    super.initState();
    _checkConfigAndFetch();
    _configSubscription = CredentialsManager().configStream.listen((_) {
      _checkConfigAndFetch(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConfigAndFetch({bool forceRefresh = false}) async {
    if (forceRefresh && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final credentials = CredentialsManager();
    final supaConfigs = await credentials.getSupabaseConfigurations();
    final serverConfigs = await credentials.getServerConfigurations();

    final hasSupa = supaConfigs.isNotEmpty;
    final hasServer = serverConfigs.isNotEmpty;

    if (!hasSupa && !hasServer) {
      if (mounted) {
        setState(() {
          _isConfigured = false;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isConfigured = true;
      });
    }

    List<OnlineSong> cachedSongs = [];
    try {
      cachedSongs = await DatabaseManager.instance.getCachedOnlineSongs();
    } catch (e) {
      print('Database error reading cache: $e');
    }

    if (cachedSongs.isNotEmpty && !forceRefresh) {
      if (mounted) {
        setState(() {
          _songsFuture = Future.value(cachedSongs);
          _isLoading = false;
        });
      }
      // Update cache in the background
      _fetchAndUpdateCache(supaConfigs, serverConfigs);
    } else {
      if (mounted) {
        setState(() {
          _songsFuture = _fetchAndUpdateCache(supaConfigs, serverConfigs);
          _isLoading = false;
        });
      }
    }
  }

  Future<List<OnlineSong>> _fetchAndUpdateCache(
    List<Map<String, String>> supaConfigs,
    List<Map<String, String>> serverConfigs,
  ) async {
    List<OnlineSong> combinedSongs = [];

    // Create parallel fetch futures
    List<Future<List<OnlineSong>>> fetchTasks = [];

    // 1. Queue all Supabase config fetches
    for (final config in supaConfigs) {
      if (config['url'] != null && config['apiKey'] != null) {
        fetchTasks.add(() async {
          try {
            final tableName = config['tableName'] ?? 'Online';
            final supa = SupabaseConnection(
              supabaseUrl: config['url']!,
              supabaseAnonKey: config['apiKey']!,
              tableName: tableName,
            );
            return await supa.fetchOnlineSongsRaw();
          } catch (e) {
            print('Error fetching Supabase (${config['tableName']}): $e');
            return <OnlineSong>[];
          }
        }());
      }
    }

    // 2. Queue all HTTP Server fetches
    for (final config in serverConfigs) {
      if (config['serverAddress'] != null &&
          config['serverAddress']!.isNotEmpty) {
        fetchTasks.add(() async {
          try {
            final serverName = config['serverName'] ?? config['serverAddress'];
            final httpManager = HTTPServerManager(
              serverAddress: config['serverAddress']!,
              serverName: serverName,
            );
            final songs = await httpManager.fetchSongs();
            // Ensure the source matches the user-configured serverName.
            return songs
                .map(
                  (s) => OnlineSong(
                    title: s.title,
                    url: s.url,
                    artist: s.artist,
                    album: s.album,
                    source: serverName,
                  ),
                )
                .toList();
          } catch (e) {
            print('Error fetching Server (${config['serverAddress']}): $e');
            return <OnlineSong>[];
          }
        }());
      }
    }

    // Wait for all fetch tasks concurrently
    final results = await Future.wait(fetchTasks);
    for (final subset in results) {
      combinedSongs.addAll(subset);
    }

    if (supaConfigs.isNotEmpty || serverConfigs.isNotEmpty) {
      try {
        await DatabaseManager.instance.cacheOnlineSongs(combinedSongs);
      } catch (e) {
        print('Error caching online songs: $e');
      }
    } else {
      // Clear cache if all configs are explicitly gone.
      try {
        await DatabaseManager.instance.cacheOnlineSongs([]);
      } catch (e) {
        print('Error clearing online songs cache: $e');
      }
    }

    return combinedSongs;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeCap: StrokeCap.round),
        ),
      );
    }

    if (!_isConfigured) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.signal_wifi_connected_no_internet_4, size: 64, color: Colors.grey),
                SizedBox(height: 6),
                Text(
                  'Not Configured',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Please configure Supabase or Server inside Settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 100,),
      child: OnlineMediaUI(
        title: 'Online',
        songsFuture: _songsFuture,
        emptyMessage: 'No songs found. Please check your connection or server.',
        showMusicController: true,
        onLogout: null, // Removed logout button from UI
      ),
    );
  }
}
