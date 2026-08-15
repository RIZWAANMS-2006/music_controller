import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../ui/media_ui.dart';

class DatabaseManager extends ChangeNotifier {
  static final DatabaseManager instance = DatabaseManager._init();
  static Database? _database;

  // Added a cache to avoid frequent disk lookups and prevent UI flickering
  final Set<String> _cachedFavorites = {};
  bool _isCacheInitialized = false;

  DatabaseManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('rusic_data.db');
    await _initCache();
    return _database!;
  }

  Future<void> _initCache() async {
    if (_isCacheInitialized) return;
    final db = _database!;
    final maps = await db.query('favorites');
    _cachedFavorites.clear();
    for (var map in maps) {
      _cachedFavorites.add(map['url'] as String);
    }
    _isCacheInitialized = true;
    notifyListeners();
  }

  bool isFavoriteSync(String url) {
    return _cachedFavorites.contains(url);
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      // Initialize FFI for desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE online_songs (
  id $idType,
  url $textType UNIQUE,
  title $textType,
  artist $textNullable,
  album $textNullable,
  source $textNullable
)
''');

    await db.execute('''
CREATE TABLE favorites (
  id $idType,
  url $textType UNIQUE,
  title $textNullable,
  artist $textNullable,
  is_online INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE playlists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
)
''');

    await db.execute('''
CREATE TABLE playlist_songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  playlist_id INTEGER,
  url TEXT NOT NULL,
  title TEXT,
  artist TEXT,
  is_online INTEGER DEFAULT 0,
  FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE online_songs ADD COLUMN source TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE favorites ADD COLUMN title TEXT');
      await db.execute('ALTER TABLE favorites ADD COLUMN artist TEXT');
      await db.execute('ALTER TABLE favorites ADD COLUMN is_online INTEGER DEFAULT 0');

      await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
      ''');

      await db.execute('''
      CREATE TABLE playlist_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER,
        url TEXT NOT NULL,
        title TEXT,
        artist TEXT,
        is_online INTEGER DEFAULT 0,
        FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
      )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE favorites ADD COLUMN source TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE playlist_songs ADD COLUMN source TEXT');
      } catch (e) {}
    }
  }

  Future<void> cacheOnlineSongs(List<OnlineSong> songs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('online_songs');
      for (final song in songs) {
        await txn.insert('online_songs', {
          'url': song.url,
          'title': song.title,
          'artist': song.artist,
          'album': song.album,
          'source': song.source,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<OnlineSong>> getCachedOnlineSongs() async {
    final db = await database;
    final maps = await db.query('online_songs');
    return maps.map((map) {
      return OnlineSong(
        title: map['title'] as String,
        url: map['url'] as String,
        artist: map['artist'] as String?,
        album: map['album'] as String?,
        source: map['source'] as String?,
      );
    }).toList();
  }

  Future<void> toggleFavorite(String url) async {
    final db = await database;
    final isFav = await isFavorite(url);
    if (isFav) {
      _cachedFavorites.remove(url);
      await db.delete('favorites', where: 'url = ?', whereArgs: [url]);
    } else {
      _cachedFavorites.add(url);
      await db.insert('favorites', {
        'url': url,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    notifyListeners();
  }

  Future<void> toggleFavoriteOnline(String url, String? title, String? artist, String? source) async {
    final db = await database;
    final isFav = await isFavorite(url);
    if (isFav) {
      _cachedFavorites.remove(url);
      await db.delete('favorites', where: 'url = ?', whereArgs: [url]);
    } else {
      _cachedFavorites.add(url);
      await db.insert('favorites', {
        'url': url,
        'title': title,
        'artist': artist,
        'is_online': source != null && source != 'Local' ? 1 : 0,
        'source': source,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    notifyListeners();
  }

  Future<bool> isFavorite(String url) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'url = ?',
      whereArgs: [url],
    );
    return maps.isNotEmpty;
  }

  Future<void> addFavorite(String url) async {
    final db = await database;
    _cachedFavorites.add(url);
    await db.insert('favorites', {
      'url': url,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    notifyListeners();
  }

  Future<void> removeFavorite(String url) async {
    final db = await database;
    _cachedFavorites.remove(url);
    await db.delete('favorites', where: 'url = ?', whereArgs: [url]);
    notifyListeners();
  }

  Future<List<String>> getAllFavorites() async {
    final db = await database;
    final maps = await db.query('favorites');
    _cachedFavorites.clear();
    for (var map in maps) {
      _cachedFavorites.add(map['url'] as String);
    }
    _isCacheInitialized = true;
    return _cachedFavorites.toList();
  }

  Future<List<OnlineSong>> getAllFavoriteSongs() async {
    final db = await database;
    final maps = await db.query('favorites');
    List<OnlineSong> songs = [];
    for (var map in maps) {
      final url = map['url'] as String;
      final rawTitle = map['title'] as String? ?? url.split(Platform.pathSeparator).last;
      final title = Uri.decodeComponent(rawTitle);
      final artist = map['artist'] as String?;
      final dbSource = map['source'] as String?;
      final isOnline = (map['is_online'] as int?) == 1;
      final source = dbSource ?? (isOnline ? 'Online' : 'Local');
      songs.add(OnlineSong(title: title, url: url, artist: artist, source: source));
    }
    return songs;
  }

  // Playlists Logic
  Future<int> createPlaylist(String name) async {
    final db = await database;
    return await db.insert('playlists', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    return await db.query('playlists');
  }

  Future<void> deletePlaylist(int id) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addSongToPlaylist(int playlistId, String url, String? title, String? artist, String? source) async {
    final db = await database;
    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'url': url,
      'title': title,
      'artist': artist,
      'is_online': source != null && source != 'Local' ? 1 : 0,
      'source': source,
    });
  }

  Future<void> removeSongFromPlaylist(int songId) async {
    final db = await database;
    await db.delete('playlist_songs', where: 'id = ?', whereArgs: [songId]);
  }

  Future<List<OnlineSong>> getPlaylistSongs(int playlistId) async {
    final db = await database;
    final maps = await db.query('playlist_songs', where: 'playlist_id = ?', whereArgs: [playlistId]);
    return maps.map((map) {
      final url = map['url'] as String;
      final rawTitle = map['title'] as String? ?? url.split(Platform.pathSeparator).last;
      final title = Uri.decodeComponent(rawTitle);
      final artist = map['artist'] as String?;
      final dbSource = map['source'] as String?;
      final isOnline = (map['is_online'] as int?) == 1;
      final source = dbSource ?? (isOnline ? 'Online' : 'Local');
      // We pass the playlist_song id in the album field temporarily to allow deletion from playlist
      return OnlineSong(title: title, url: url, artist: artist, source: source, album: map['id'].toString());
    }).toList();
  }
}
