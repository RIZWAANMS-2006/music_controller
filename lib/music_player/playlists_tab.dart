import 'package:Rusic/managers/ui_manager.dart';
import 'package:flutter/material.dart';
import 'package:Rusic/managers/database_manager.dart';
import 'package:Rusic/ui/media_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:bounce/bounce.dart';

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});

  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  // Previous ListTile implementation of Favorites and Playlists (commented out for reference):
  /*
  Widget _buildFavoritesListTile() {
    return Card(
      color: setContainerColor(context),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: setContainerContrastColor(context).withAlpha(3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.redAccent,
          ),
        ),
        title: const Text(
          "Favorites",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: const Text(
          "Favorite songs",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        onTap: () => _openFavorites(),
      ),
    );
  }
  */

  void _openFavorites() {
    final parentScrollController = PrimaryScrollController.maybeOf(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          Widget mediaUI = OnlineMediaUI(
            title: "Favorites",
            songsFuture: DatabaseManager.instance.getAllFavoriteSongs(),
            emptyMessage: "No Favorite Yet...",
          );

          if (parentScrollController != null) {
            return PrimaryScrollController(
              controller: parentScrollController,
              child: mediaUI,
            );
          }
          return mediaUI;
        },
      ),
    );
  }

  void _openPlaylist(Map<String, dynamic> playlist) {
    final parentScrollController = PrimaryScrollController.maybeOf(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          Widget mediaUI = OnlineMediaUI(
            title: playlist['name'],
            songsFuture: DatabaseManager.instance
                .getPlaylistSongs(playlist['id'] as int),
            emptyMessage: "No songs in this playlist.",
          );

          if (parentScrollController != null) {
            return PrimaryScrollController(
              controller: parentScrollController,
              child: mediaUI,
            );
          }
          return mediaUI;
        },
      ),
    );
  }

  Future<void> _deletePlaylist(Map<String, dynamic> playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text("Delete Playlist"),
        content: Text(
          "Are you sure you want to delete '${playlist['name']}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseManager.instance.deletePlaylist(
        playlist['id'] as int,
      );
      setState(() {}); // refresh
    }
  }

  Widget _buildFavoritesCard(bool isDesktop) {
    const bounceDuration = Duration(milliseconds: 100);
    return Bounce(
      tilt: false,
      duration: bounceDuration,
      scaleFactor: 0.9,
      onTap: () async {
        await Future.delayed(bounceDuration);
        if (mounted) {
          _openFavorites();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: setContainerColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: setContainerContrastColor(context).withAlpha(3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: isDesktop ? 64 : 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Favorites",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Favorite songs",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist, bool isDesktop) {
    const bounceDuration = Duration(milliseconds: 100);
    return Bounce(
      tilt: false,
      duration: bounceDuration,
      scaleFactor: 0.9,
      onTap: () async {
        await Future.delayed(bounceDuration);
        if (mounted) {
          _openPlaylist(playlist);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: setContainerColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: setContainerContrastColor(context).withAlpha(3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: isDesktop ? 64 : 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      playlist['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Playlist",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _deletePlaylist(playlist),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPlaylistCard(bool isDesktop) {
    const bounceDuration = Duration(milliseconds: 100);
    return Bounce(
      tilt: false,
      duration: bounceDuration,
      scaleFactor: 0.9,
      onTap: () async {
        await Future.delayed(bounceDuration);
        if (mounted) {
          showAddToPlaylistDialog(
            context,
            url: "",
            title: "",
            source: 'Local',
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: setContainerColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: setContainerContrastColor(context).withAlpha(3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_rounded,
              size: isDesktop ? 64 : 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Create Playlist",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Create new playlist",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> playlists) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final isDesktop = constraints.crossAxisExtent > 700;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            childAspectRatio: isDesktop ? 1.5 : 0.8,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                return _buildFavoritesCard(isDesktop);
              }
              if (index <= playlists.length) {
                final playlist = playlists[index - 1];
                return _buildPlaylistCard(playlist, isDesktop);
              }
              return _buildAddPlaylistCard(isDesktop);
            },
            childCount: playlists.length + 2,
          ),
        );
      },
    );
  }

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

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: CustomScrollView(
                  controller: PrimaryScrollController.maybeOf(context),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: _buildGrid(playlists),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
