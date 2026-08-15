import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manager for securely storing sensitive credentials like API keys, URLs, and table names
/// Uses FlutterSecureStorage which encrypts data on device storage across all platforms
class CredentialsManager {
  static final CredentialsManager _instance = CredentialsManager._internal();
  factory CredentialsManager() => _instance;
  CredentialsManager._internal();

  // FlutterSecureStorage with platform-specific secure options
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(useBackwardCompatibility: true),
    lOptions: LinuxOptions(),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final StreamController<void> _configStreamController =
      StreamController<void>.broadcast();

  Stream<void> get configStream => _configStreamController.stream;

  // Legacy Key constants for secure storage (to be migrated)
  static const String _keySupabaseUrl = 'secure_supabase_url';
  static const String _keySupabaseAnonKey = 'secure_supabase_anon_key';
  static const String _keySupabaseTableName = 'secure_supabase_table_name';
  static const String _keyServerAddress = 'secure_server_address';
  static const String _keyServerName = 'secure_server_name';

  // New List Key constants
  static const String _keySupabaseConfigsList = 'secure_supabase_configs_list';
  static const String _keyServerConfigsList = 'secure_server_configs_list';

  bool _hasMigrated = false;
  List<Map<String, String>>? _cachedSupabaseConfigs;
  List<Map<String, String>>? _cachedServerConfigs;

  /// Ensure legacy data is migrated safely to the new list structure on first access
  Future<void> _migrateLegacyDataIfNeeded() async {
    if (_hasMigrated) return;
    _hasMigrated = true;

    final legacySupabaseUrl = await _storage.read(key: _keySupabaseUrl);
    if (legacySupabaseUrl != null) {
      final key = await _storage.read(key: _keySupabaseAnonKey);
      final table = await _storage.read(key: _keySupabaseTableName);

      if (key != null && table != null) {
        await addSupabaseConfiguration({
          'url': legacySupabaseUrl,
          'apiKey': key,
          'tableName': table,
        });
      }

      await _storage.delete(key: _keySupabaseUrl);
      await _storage.delete(key: _keySupabaseAnonKey);
      await _storage.delete(key: _keySupabaseTableName);
    }

    final legacyServerAddr = await _storage.read(key: _keyServerAddress);
    if (legacyServerAddr != null) {
      final name = await _storage.read(key: _keyServerName);
      await addServerConfiguration({
        'serverAddress': legacyServerAddr,
        'serverName': name ?? legacyServerAddr,
      });

      await _storage.delete(key: _keyServerAddress);
      await _storage.delete(key: _keyServerName);
    }
  }

  // --- Supabase Configurations ---

  Future<List<Map<String, String>>> getSupabaseConfigurations() async {
    if (_cachedSupabaseConfigs != null) return _cachedSupabaseConfigs!;
    await _migrateLegacyDataIfNeeded();
    final data = await _storage.read(key: _keySupabaseConfigsList);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      _cachedSupabaseConfigs = decoded
          .map((e) => Map<String, String>.from(e))
          .toList();
      return _cachedSupabaseConfigs!;
    } catch (e) {
      return [];
    }
  }

  Future<void> addSupabaseConfiguration(Map<String, String> config) async {
    final configs = await getSupabaseConfigurations();
    // Prevent duplicates by checking tableName
    configs.removeWhere((c) => c['tableName'] == config['tableName']);
    configs.add(config);
    await _storage.write(
      key: _keySupabaseConfigsList,
      value: jsonEncode(configs),
    );
    _cachedSupabaseConfigs = configs;
    _configStreamController.add(null);
  }

  Future<void> removeSupabaseConfiguration(String tableName) async {
    final configs = await getSupabaseConfigurations();
    configs.removeWhere((c) => c['tableName'] == tableName);
    await _storage.write(
      key: _keySupabaseConfigsList,
      value: jsonEncode(configs),
    );
    _cachedSupabaseConfigs = configs;
    _configStreamController.add(null);
  }

  // --- Server Configurations ---

  Future<List<Map<String, String>>> getServerConfigurations() async {
    if (_cachedServerConfigs != null) return _cachedServerConfigs!;
    await _migrateLegacyDataIfNeeded();
    final data = await _storage.read(key: _keyServerConfigsList);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      _cachedServerConfigs = decoded
          .map((e) => Map<String, String>.from(e))
          .toList();
      return _cachedServerConfigs!;
    } catch (e) {
      return [];
    }
  }

  Future<void> addServerConfiguration(Map<String, String> config) async {
    final configs = await getServerConfigurations();
    configs.removeWhere((c) => c['serverName'] == config['serverName']);
    configs.add(config);
    await _storage.write(
      key: _keyServerConfigsList,
      value: jsonEncode(configs),
    );
    _cachedServerConfigs = configs;
    _configStreamController.add(null);
  }

  Future<void> removeServerConfiguration(String serverName) async {
    final configs = await getServerConfigurations();
    configs.removeWhere((c) => c['serverName'] == serverName);
    await _storage.write(
      key: _keyServerConfigsList,
      value: jsonEncode(configs),
    );
    _cachedServerConfigs = configs;
    _configStreamController.add(null);
  }

  /// Legacy clear all fallback
  Future<void> clearAll() async {
    await _storage.deleteAll();
    _cachedSupabaseConfigs = null;
    _cachedServerConfigs = null;
    _configStreamController.add(null);
  }

  // To preserve backwards compatibility for places expecting legacy methods:
  Future<String?> getServerAddress() async {
    final configs = await getServerConfigurations();
    if (configs.isNotEmpty) return configs.first['serverAddress'];
    return null;
  }

  Future<String?> getServerName() async {
    final configs = await getServerConfigurations();
    if (configs.isNotEmpty) return configs.first['serverName'];
    return null;
  }

  Future<void> saveServerAddress(
    String address,
  ) async {} // No-op, replaced by addServerConfiguration
  Future<void> saveServerName(
    String name,
  ) async {} // No-op, replaced by addServerConfiguration
  Future<void> clearServerAddress() async {}
  Future<void> clearServerName() async {}

  Future<Map<String, String?>> getSupabaseCredentials() async {
    final configs = await getSupabaseConfigurations();
    if (configs.isNotEmpty) {
      return {
        'url': configs.first['url'],
        'apiKey': configs.first['apiKey'],
        'tableName': configs.first['tableName'],
      };
    }
    return {'url': null, 'apiKey': null, 'tableName': null};
  }

  Future<void>
  clearSupabaseCredentials() async {} // Handled via specific removes now

  Future<void> saveSupabaseCredentials({
    required String url,
    required String apiKey,
    required String tableName,
  }) async {
    await addSupabaseConfiguration({
      'url': url,
      'apiKey': apiKey,
      'tableName': tableName,
    });
  }
}
