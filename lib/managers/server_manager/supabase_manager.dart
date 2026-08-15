import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Rusic/ui/media_ui.dart';

class SupabaseConnection {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String tableName;
  late final SupabaseClient client;

  SupabaseConnection({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.tableName,
  }) {
    client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  }

  Future<bool> isConnected() async {
    try {
      await client.from(tableName).select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches all songs from the Supabase table and converts them to OnlineSong objects
  Future<List<OnlineSong>> fetchOnlineSongsRaw() async {
    try {
      final response = await client
          .from(tableName)
          .select()
          .timeout(const Duration(seconds: 15));

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response as List,
      );

      return data
          .map((map) => OnlineSong.fromMap(map, source: tableName))
          .toList();
    } catch (e) {
      print('Supabase fetch error: $e');
      return [];
    }
  }
}
