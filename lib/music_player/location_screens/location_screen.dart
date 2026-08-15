import 'package:flutter/material.dart';
import 'package:Rusic/managers/path_manager.dart';
import 'package:Rusic/ui/media_ui.dart';
import 'package:flutter/rendering.dart';

class LocationsTab extends StatefulWidget {
  const LocationsTab({super.key});

  @override
  State<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<LocationsTab> {
  final Pathmanager _pathManager = Pathmanager();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  List<Map<String, String>> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    final locations = await _pathManager.getLibraryFoldersWithNames();
    setState(() {
      _locations = locations;
      _isLoading = false;
    });
  }

  Future<void> _addFolder() async {
    final added = await _pathManager.addLibraryFolder();
    if (added) {
      _loadLocations();
    }
  }

  void _openLocation(String path, String name) {
    // Capture the parent Tab's NestedScrollController before navigating
    final parentScrollController = PrimaryScrollController.maybeOf(context);

    _navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (newContext) {
          Widget mediaUI = MediaUI(
            title: name,
            showNavigationBar: true,
            mediaFilesFuture: _pathManager
                .scanMediaFiles(path)
                .then((files) => {name: files}),
          );

          // Wrap the new route in the parent's scroll controller so it signals the
          // top CupertinoSliverNavigationBar to shrink when scrolling inside MediaUI
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final navigator = _navigatorKey.currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else {
          // If no nested routes, pop the top level (if possible)
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => _buildLocationsView(context),
          );
        },
      ),
    );
  }

  Widget _buildLocationsView(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'Add Folder',
        child: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
      ),
      body: _locations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Locations Added',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add folders to your library to see them here',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addFolder,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Add Folder"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: CustomScrollView(
                controller: PrimaryScrollController.maybeOf(context),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: _buildGrid(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ), // Space for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildGrid() {
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
            (context, index) =>
                _buildLocationCard(_locations[index], isDesktop),
            childCount: _locations.length,
          ),
        );
      },
    );
  }

  Widget _buildLocationCard(Map<String, String> loc, bool isDesktop) {
    return GestureDetector(
      onTap: () => _openLocation(loc['path']!, loc['name']!),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_rounded,
              size: isDesktop ? 64 : 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                loc['name']!,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                loc['path']!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
