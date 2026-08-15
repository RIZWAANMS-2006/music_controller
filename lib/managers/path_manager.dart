// ignore_for_file: avoid_print

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages file system paths and permissions for media file access across platforms.
///
/// This class uses a user-consent model where the app only accesses folders
/// that the user has explicitly selected via the folder picker.
class Pathmanager {
  // ==================== STATIC CONSTANTS ====================

  /// Key for storing user-selected library folders in SharedPreferences.
  static const String _libraryFoldersKey = 'user_library_folders';

  /// Key for tracking if default folders have been initialized.
  static const String _defaultFoldersInitializedKey =
      'default_folders_initialized';

  /// Supported audio file extensions.
  static const List<String> _audioExtensions = [
    '.mp3',
    '.wav',
    '.aac',
    '.flac',
    '.ogg',
    '.m4a',
    '.wma',
  ];

  /// Supported video file extensions.
  static const List<String> _videoExtensions = [
    '.mp4',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.mkv',
    '.webm',
    '.3gp',
  ];

  // ==================== PRIVATE HELPER METHODS ====================

  /// Checks if a directory exists and is accessible.
  Future<bool> _isDirectoryAccessible(Directory directory) async {
    try {
      final exists = await directory.exists();

      return exists;
    } catch (e) {
      return false;
    }
  }

  static const Set<String> _mediaExtensions = {
    ..._audioExtensions,
    ..._videoExtensions,
  };

  /// Checks if a file path has a supported media extension.
  bool _isMediaFile(String filePath) {
    if (filePath.isEmpty) return false;
    final lastDotIndex = filePath.lastIndexOf('.');
    if (lastDotIndex == -1) return false;

    final ext = filePath.substring(lastDotIndex).toLowerCase();
    return _mediaExtensions.contains(ext);
  }

  /// Extracts a readable directory name from a full path.
  ///
  /// Examples:
  /// - /storage/emulated/0/Music → Music
  /// - C:\Users\Name\Downloads → Downloads
  /// - /home/user/Videos → Videos
  String _extractDirectoryName(String fullPath) {
    // Remove trailing slashes
    final cleanPath = fullPath.replaceAll(RegExp(r'[/\\]+$'), '');

    // Get last component
    final parts = cleanPath.split(RegExp(r'[/\\]'));
    final lastName = parts.isNotEmpty ? parts.last : 'Unknown';

    return lastName;
  }

  /// Requests storage permissions on Android.
  /// Returns true if permissions are granted.
  Future<bool> _requestAndroidPermissions() async {
    if (!Platform.isAndroid) return true;

    final storageStatus = await Permission.storage.request();
    final manageStorageStatus = await Permission.manageExternalStorage
        .request();

    return storageStatus.isGranted || manageStorageStatus.isGranted;
  }

  // ==================== USER LIBRARY FOLDER MANAGEMENT ====================

  /// Gets the standard user directories (Downloads, Music, Videos) based on platform.
  ///
  /// Returns a list of directory paths that exist.
  /// - Windows: C:\Users\[username]\Downloads, Music, Videos
  /// - Linux: /home/[username]/Downloads, Music, Videos
  /// - macOS: /Users/[username]/Downloads, Music, Movies
  /// - Android: Skipped (uses different storage model)
  Future<List<String>> getDefaultSystemDirectories() async {
    final List<String> defaultDirs = [];

    try {
      if (Platform.isAndroid) {
        // Skip for Android - uses different storage model

        return defaultDirs;
      }

      // Get user home directory
      final String? home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

      if (home == null) {
        return defaultDirs;
      }

      // Standard directory names based on platform
      final List<String> dirNames = Platform.isMacOS
          ? [
              'Downloads',
              'Music',
              'Movies',
            ] // macOS uses "Movies" instead of "Videos"
          : ['Downloads', 'Music', 'Videos'];

      // Check each directory
      for (final dirName in dirNames) {
        final dirPath = Platform.isWindows
            ? '$home\\$dirName'
            : '$home/$dirName';

        final dir = Directory(dirPath);
        if (await dir.exists()) {
          defaultDirs.add(dirPath);
        } else {}
      }
    } catch (e) {}

    return defaultDirs;
  }

  /// Initializes default library folders on first launch.
  ///
  /// Adds Downloads, Music, and Videos (or Movies on macOS) directories
  /// to the library if they exist and haven't been initialized before.
  ///
  /// Returns the number of directories that were added.
  Future<int> initializeDefaultLibraryFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if already initialized
      final alreadyInitialized =
          prefs.getBool(_defaultFoldersInitializedKey) ?? false;

      if (alreadyInitialized) {
        return 0;
      }

      // Get default system directories
      final defaultDirs = await getDefaultSystemDirectories();

      print(
        '[PathManager] Found ${defaultDirs.length} default directories: $defaultDirs',
      );

      if (defaultDirs.isEmpty) {
        // Mark as initialized even if no directories found
        await prefs.setBool(_defaultFoldersInitializedKey, true);
        return 0;
      }

      // Add each directory to library
      int addedCount = 0;
      for (final dirPath in defaultDirs) {
        final success = await addLibraryFolderPath(dirPath);
        if (success) {
          addedCount++;
        } else {}
      }

      // Mark as initialized
      await prefs.setBool(_defaultFoldersInitializedKey, true);

      return addedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Force initializes default folders even if already initialized.
  ///
  /// Useful when user has no folders and wants to reset to defaults.
  Future<int> forceInitializeDefaultFolders() async {
    try {
      // Get default system directories
      final defaultDirs = await getDefaultSystemDirectories();

      print(
        '[PathManager] Found ${defaultDirs.length} default directories: $defaultDirs',
      );

      if (defaultDirs.isEmpty) {
        return 0;
      }

      // Add each directory to library
      int addedCount = 0;
      for (final dirPath in defaultDirs) {
        final success = await addLibraryFolderPath(dirPath);
        if (success) {
          addedCount++;
        } else {}
      }

      // Mark as initialized
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_defaultFoldersInitializedKey, true);

      return addedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Checks if default folders have been initialized.
  Future<bool> areDefaultFoldersInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_defaultFoldersInitializedKey) ?? false;

    return initialized;
  }

  /// Resets the default folder initialization flag.
  ///
  /// After calling this, the next call to initializeDefaultLibraryFolders()
  /// will add default folders again. Useful for troubleshooting.
  Future<void> resetDefaultFoldersInitialization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_defaultFoldersInitializedKey);
  }

  /// Gets all user-selected library folders from persistent storage.
  ///
  /// Returns an empty list if no folders have been selected yet.
  Future<List<String>> getSavedLibraryFolders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_libraryFoldersKey) ?? [];
  }

  /// Opens a folder picker dialog and adds the selected folder to the library.
  ///
  /// Returns `true` if a new folder was successfully added.
  /// Returns `false` if:
  /// - User canceled the picker
  /// - Selected folder is already in the library (duplicate)
  /// - An error occurred
  Future<bool> addLibraryFolder() async {
    try {
      // Open folder picker dialog
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        final prefs = await SharedPreferences.getInstance();

        // Get current folder list
        List<String> currentFolders =
            prefs.getStringList(_libraryFoldersKey) ?? [];

        // Avoid duplicates
        if (!currentFolders.contains(selectedDirectory)) {
          currentFolders.add(selectedDirectory);
          await prefs.setStringList(_libraryFoldersKey, currentFolders);

          return true;
        } else {}
      } else {}
    } catch (e) {}
    return false;
  }

  /// Adds a specific folder path to the library without opening a picker.
  ///
  /// Useful for programmatically adding folders.
  /// Returns `true` if successfully added, `false` if duplicate or error.
  Future<bool> addLibraryFolderPath(String folderPath) async {
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> currentFolders =
          prefs.getStringList(_libraryFoldersKey) ?? [];

      if (!currentFolders.contains(folderPath)) {
        currentFolders.add(folderPath);
        await prefs.setStringList(_libraryFoldersKey, currentFolders);

        return true;
      }
    } catch (e) {}
    return false;
  }

  /// Removes a folder from the user's library.
  ///
  /// The folder itself is not deleted, only removed from the app's scan list.
  Future<void> removeLibraryFolder(String folderPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> currentFolders =
          prefs.getStringList(_libraryFoldersKey) ?? [];

      currentFolders.remove(folderPath);
      await prefs.setStringList(_libraryFoldersKey, currentFolders);
    } catch (e) {}
  }

  /// Clears all user-selected library folders.
  Future<void> clearAllLibraryFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_libraryFoldersKey);
    } catch (e) {}
  }

  /// Checks if the user has any library folders selected.
  Future<bool> hasLibraryFolders() async {
    final folders = await getSavedLibraryFolders();
    return folders.isNotEmpty;
  }

  /// Gets library folders with their extracted names for display purposes.
  ///
  /// Returns a list of maps containing:
  /// - 'path': full folder path
  /// - 'name': extracted folder name for display
  Future<List<Map<String, String>>> getLibraryFoldersWithNames() async {
    final folders = await getSavedLibraryFolders();
    return folders.map((path) {
      return {'path': path, 'name': _extractDirectoryName(path)};
    }).toList();
  }

  // ==================== LIBRARY SCANNING METHODS ====================

  /// Scans the specified directory and returns all media files (audio + video).
  ///
  /// Performs recursive scanning and filters by supported extensions.
  /// Returns empty list if directory is inaccessible or contains no media.
  Future<List<File>> scanMediaFiles(String directoryPath) async {
    try {
      final targetDir = Directory(directoryPath);

      if (!await targetDir.exists()) {
        return [];
      }

      final allEntries = await targetDir.list(recursive: true).toList();

      final mediaFiles = allEntries
          .whereType<File>()
          .where((file) => _isMediaFile(file.path))
          .toList();

      return mediaFiles;
    } catch (e) {
      rethrow;
    }
  }

  /// Scans ONLY the user-selected library folders for media files.
  ///
  /// This is the recommended method for scanning media files as it respects
  /// user preferences and only accesses folders the user has explicitly allowed.
  ///
  /// Returns a Map where:
  /// - Keys: directory names (e.g., "Music", "Downloads")
  /// - Values: list of media files found in that directory
  ///
  /// Returns an empty map if no library folders have been selected.
  Future<Map<String, List<File>>> fetchMediaFilesFromLibrary() async {
    // Request permissions on Android before scanning
    await _requestAndroidPermissions();

    final libraryFolders = await getSavedLibraryFolders();
    final mediaFilesByLocation = <String, List<File>>{};

    if (libraryFolders.isEmpty) {
      return mediaFilesByLocation;
    }

    print(
      '[PathManager] Scanning ${libraryFolders.length} user library folders...',
    );

    for (final folderPath in libraryFolders) {
      final dir = Directory(folderPath);

      if (await _isDirectoryAccessible(dir)) {
        final filesInDirectory = await scanMediaFiles(folderPath);
        final dirName = _extractDirectoryName(folderPath);
        // Always include saved folders, even if they have no media files yet
        mediaFilesByLocation[dirName] = filesInDirectory;
      } else {}
    }

    final totalFiles = mediaFilesByLocation.values.fold<int>(
      0,
      (sum, files) => sum + files.length,
    );
    print(
      '[PathManager] Library total: $totalFiles files across ${mediaFilesByLocation.length} locations',
    );

    return mediaFilesByLocation;
  }

  /// Scans library folders and returns a flat list of all media files.
  ///
  /// Unlike [fetchMediaFilesFromLibrary], this returns all files in a single list
  /// without grouping by directory. Useful when you just need all songs.
  Future<List<File>> fetchAllMediaFilesFromLibrary() async {
    // Request permissions on Android before scanning
    await _requestAndroidPermissions();

    final libraryFolders = await getSavedLibraryFolders();
    final allMediaFiles = <File>[];

    if (libraryFolders.isEmpty) {
      return allMediaFiles;
    }

    for (final folderPath in libraryFolders) {
      final dir = Directory(folderPath);

      if (await dir.exists()) {
        try {
          final files = await dir.list(recursive: true).toList();

          for (final file in files) {
            if (file is File && _isMediaFile(file.path)) {
              allMediaFiles.add(file);
            }
          }
        } catch (e) {}
      }
    }

    return allMediaFiles;
  }

  /// Scans library folders and returns only audio files.
  Future<List<File>> fetchAudioFilesFromLibrary() async {
    // Request permissions on Android before scanning
    await _requestAndroidPermissions();

    final libraryFolders = await getSavedLibraryFolders();
    final audioFiles = <File>[];

    if (libraryFolders.isEmpty) {
      return audioFiles;
    }

    for (final folderPath in libraryFolders) {
      final dir = Directory(folderPath);

      if (await dir.exists()) {
        try {
          final files = await dir.list(recursive: true).toList();

          for (final file in files) {
            if (file is File) {
              if (file.path.isEmpty) continue;
              final lastDotIndex = file.path.lastIndexOf('.');
              if (lastDotIndex == -1) continue;

              final extension = file.path.substring(lastDotIndex).toLowerCase();
              if (_audioExtensions.contains(extension)) {
                audioFiles.add(file);
              }
            }
          }
        } catch (e) {}
      }
    }

    return audioFiles;
  }

  /// Scans library folders and returns only video files.
  Future<List<File>> fetchVideoFilesFromLibrary() async {
    // Request permissions on Android before scanning
    await _requestAndroidPermissions();

    final libraryFolders = await getSavedLibraryFolders();
    final videoFiles = <File>[];

    if (libraryFolders.isEmpty) {
      return videoFiles;
    }

    for (final folderPath in libraryFolders) {
      final dir = Directory(folderPath);

      if (await dir.exists()) {
        try {
          final files = await dir.list(recursive: true).toList();

          for (final file in files) {
            if (file is File) {
              if (file.path.isEmpty) continue;
              final lastDotIndex = file.path.lastIndexOf('.');
              if (lastDotIndex == -1) continue;

              final extension = file.path.substring(lastDotIndex).toLowerCase();
              if (_videoExtensions.contains(extension)) {
                videoFiles.add(file);
              }
            }
          }
        } catch (e) {}
      }
    }

    return videoFiles;
  }
}
