import 'package:flutter/material.dart';
import 'package:Rusic/managers/database_manager.dart';
import 'package:Rusic/ui/media_ui.dart';

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});

  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: DatabaseManager.instance,
        builder: (context, _) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseManager.instance.getPlaylists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final playlists = snapshot.data ?? [];
              if (playlists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.queue_music, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("No Playlists Yet", style: TextStyle(color: Colors.grey, fontSize: 18)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Create Playlist"),
                        onPressed: () => showAddToPlaylistDialog(context, url: "", title: "", source: 'Local'),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                      )
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return Card(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.queue_music, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(
                        playlist['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              title: const Text("Delete Playlist"),
                              content: Text("Are you sure you want to delete '${playlist['name']}'?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await DatabaseManager.instance.deletePlaylist(playlist['id'] as int);
                            setState(() {}); // refresh
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              body: OnlineMediaUI(
                                title: playlist['name'],
                                songsFuture: DatabaseManager.instance.getPlaylistSongs(playlist['id'] as int),
                                emptyMessage: "No songs in this playlist.",
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => showAddToPlaylistDialog(context, url: "", title: "", source: 'Local'),
      ),
    );
  }
}
