import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:Rusic/ui/media_ui.dart';

class HTTPServerManager {
  final String serverAddress;
  final String? serverName;

  HTTPServerManager({required this.serverAddress, this.serverName});

  Future<List<OnlineSong>> fetchSongs() async {
    List<OnlineSong> songs = [];
    Set<String> visited = {};

    // Begin recursive fetch starting with the root serverAddress
    await _fetchDirectory(serverAddress, songs, visited);
    return songs;
  }

  Future<void> _fetchDirectory(
    String url,
    List<OnlineSong> songs,
    Set<String> visited,
  ) async {
    if (visited.contains(url)) return;
    visited.add(url);

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        url = response.request?.url.toString() ?? url;
        var document = parse(response.body);
        var anchors = document.getElementsByTagName('a');

        List<Future> subdirs = [];

        for (var anchor in anchors) {
          var href = anchor.attributes['href'];
          if (href != null && href.isNotEmpty) {
            if (href == '../' || href == '/' || href.startsWith('?')) continue;

            var absoluteUrl = _buildAbsoluteUrl(url, href);

            if (_isMediaFile(href)) {
              var title = Uri.decodeFull(href)
                  .replaceAll(RegExp(r'^/'), '')
                  .replaceAll(RegExp(r'\.[^.]+$'), ''); // remove extension

              if (title.contains('/')) {
                title = title.split('/').last;
              }

              songs.add(
                OnlineSong(
                  title: title,
                  url: absoluteUrl,
                  artist: 'Server',
                  source: serverName ?? serverAddress,
                ),
              );
            } else if (href.endsWith('/') && !href.startsWith('http')) {
              // Recursively fetch subdirectories
              subdirs.add(_fetchDirectory(absoluteUrl, songs, visited));
            }
          }
        }
        await Future.wait(subdirs);
      } else {
        print('HTTP Server error at $url: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching from HTTP server directory $url: $e');
    }
  }

  bool _isMediaFile(String href) {
    final lowerHref = href.toLowerCase();
    return lowerHref.endsWith('.mp3') ||
        lowerHref.endsWith('.wav') ||
        lowerHref.endsWith('.m4a') ||
        lowerHref.endsWith('.flac') ||
        lowerHref.endsWith('.aac') ||
        lowerHref.endsWith('.ogg') ||
        lowerHref.endsWith('.mp4') ||
        lowerHref.endsWith('.mkv') ||
        lowerHref.endsWith('.avi') ||
        lowerHref.endsWith('.webm') ||
        lowerHref.endsWith('.mov') ||
        lowerHref.endsWith('.wmv');
  }

  String _buildAbsoluteUrl(String base, String relative) {
    if (relative.startsWith('http://') || relative.startsWith('https://')) {
      return relative;
    }

    try {
      final baseUri = Uri.parse(base);
      return baseUri.resolve(relative).toString();
    } catch (_) {
      // Fallback
      var sanitizedBase = base;
      if (!sanitizedBase.endsWith('/')) {
        sanitizedBase = '$sanitizedBase/';
      }

      var sanitizedRelative = relative;
      if (sanitizedRelative.startsWith('/')) {
        sanitizedRelative = sanitizedRelative.substring(1);
      }

      return '$sanitizedBase$sanitizedRelative';
    }
  }
}
