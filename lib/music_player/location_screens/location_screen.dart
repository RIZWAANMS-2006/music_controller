import 'package:Rusic/managers/ui_manager.dart';
import 'package:flutter/material.dart';
import 'package:Rusic/managers/path_manager.dart';
import 'package:Rusic/ui/media_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:bounce/bounce.dart';

class LocationsTab extends StatefulWidget {
  const LocationsTab({super.key});

  @override
  State<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<LocationsTab> {
  final Pathmanager _pathManager = Pathmanager();

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

    Navigator.push(
      context,
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
    return _buildLocationsView(context);
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
      body: ScrollConfiguration(
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
            ),
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
            (context, index) {
              if (index == _locations.length) {
                return _buildAddLocationCard(isDesktop);
              }
              return _buildLocationCard(_locations[index], isDesktop);
            },
            childCount: _locations.length + 1,
          ),
        );
      },
    );
  }

  Widget _buildAddLocationCard(bool isDesktop) {
    const bounceDuration = Duration(milliseconds: 100);
    return Bounce(
      tilt: false,
      duration: bounceDuration,
      scaleFactor: 0.9,
      onTap: () async {
        await Future.delayed(bounceDuration);
        if (mounted) {
          _addFolder();
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
              Icons.create_new_folder_rounded,
              size: isDesktop ? 64 : 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Add Folder",
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
                "Add local folder",
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

  Widget _buildLocationCard(Map<String, String> loc, bool isDesktop) {
    const bounceDuration = Duration(milliseconds: 100);
    return Bounce(
      tilt: false,
      duration: bounceDuration,
      scaleFactor: 0.9,
      onTap: () async {
        await Future.delayed(bounceDuration);
        if (mounted) {
          _openLocation(loc['path']!, loc['name']!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: setContainerColor(context),
          // color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: setContainerContrastColor(context).withAlpha(3), width: 1),
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
