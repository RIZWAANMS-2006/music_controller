import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Rusic/managers/ui_manager.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:Rusic/managers/songs_manager.dart';
import 'package:Rusic/managers/database_manager.dart';
import 'package:Rusic/managers/settings_manager.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';

/// A universal UI component for displaying media files across different tabs.
///
/// Supports both grid view (desktop) and list view (mobile) layouts.
/// Can be used with either a Future or direct data.
class MediaUI extends StatefulWidget {
  /// The title displayed in the navigation bar
  final String title;

  /// Future that resolves to media files grouped by location
  final Future<Map<String, List<File>>>? mediaFilesFuture;

  /// Direct media files data (use this OR mediaFilesFuture, not both)
  final Map<String, List<File>>? mediaFiles;

  /// Callback when no media files are found - typically to add folders
  final VoidCallback? onEmptyAction;

  /// Text for the empty state action button
  final String emptyActionText;

  /// Message shown when no media files are found
  final String emptyMessage;

  /// Whether to show the search bar (for search tab)
  final bool showSearchBar;

  /// Whether to show the floating music controller
  final bool showMusicController;

  /// Whether to show the navigation bar
  final bool showNavigationBar;

  const MediaUI({
    super.key,
    this.title = "Media",
    this.mediaFilesFuture,
    this.mediaFiles,
    this.onEmptyAction,
    this.emptyActionText = "Add Folder",
    this.emptyMessage = "No media files found",
    this.showSearchBar = false,
    this.showMusicController = true,
    this.showNavigationBar = true,
  });

  @override
  State<MediaUI> createState() => _MediaUIState();
}

class _MediaUIState extends State<MediaUI> {
  int hoverIndex = -1;
  final ScrollController _scrollController = ScrollController();
  final Map<String, int> _letterToIndex = {};
  List<File> _sortedFiles = [];
  final Set<String> _likedFiles = {};
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await DatabaseManager.instance.getAllFavorites();
    if (mounted) {
      setState(() {
        _likedFiles.addAll(favorites);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If direct data is provided, use it; otherwise use the future
    if (widget.mediaFiles != null) {
      return _buildContent(widget.mediaFiles!);
    }

    if (widget.mediaFilesFuture != null) {
      return FutureBuilder<Map<String, List<File>>>(
        future: widget.mediaFilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildContent(data);
          }
        },
      );
    }

    // No data provided
    return _buildEmptyState();
  }

  Widget _buildLoadingState() {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
          slivers: [
            if (widget.showNavigationBar) _buildNavigationBar(),
            SliverFillRemaining(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[850]!,
                highlightColor: Colors.grey[700]!,
                child: isDesktop
                    ? const _DesktopShimmer()
                    : const _MobileShimmer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
          slivers: [
            if (widget.showNavigationBar) _buildNavigationBar(),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading files',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
          slivers: [
            if (widget.showNavigationBar) _buildNavigationBar(),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      widget.emptyMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add folders to your library to see media',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    if (widget.onEmptyAction != null) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: widget.onEmptyAction,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(widget.emptyActionText),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<File>>? _lastMediaByLocation;

  Widget _buildContent(Map<String, List<File>> mediaByLocation) {
    if (_lastMediaByLocation != mediaByLocation) {
      final uniqueFiles = <String, File>{};
      for (final file in mediaByLocation.values.expand((files) => files)) {
        uniqueFiles[file.path] = file;
      }
      final allFiles = uniqueFiles.values.toList();
      _lastMediaByLocation = mediaByLocation;
      _sortedFiles = _sortAndMapFiles(allFiles);
    }
    
    List<File> filesToDisplay = _sortedFiles;
    if (_searchQuery.isNotEmpty) {
      filesToDisplay = filesToDisplay.where((f) {
        final name = f.path.split(Platform.pathSeparator).last.toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isDesktop ? _buildDesktopLayout(filesToDisplay) : _buildMobileLayout(filesToDisplay),
    );
  }

  Widget _buildNavigationBar() {
    if (widget.title == 'Search' || widget.showSearchBar) {
      return Builder(
        builder: (context) {
          return CupertinoSliverNavigationBar(
            stretch: true,
            backgroundColor: setAppBarColor(context),
            largeTitle: Text(widget.title),
            alwaysShowMiddle: false,
            transitionBetweenRoutes: false,
            border: Border(
              bottom: BorderSide(color: setAppBarBorderColor(context)),
            ),
          );
        },
      );
    }

    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      leadingWidth: 40,
      expandedHeight: 20,
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              style: const ButtonStyle(
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildDesktopLayout(List<File> displayFiles) {
    final groupedFiles = _groupFilesByLetter(displayFiles);
    final sortedLetters = groupedFiles.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: CustomScrollView(
              controller:
                  PrimaryScrollController.maybeOf(context) ?? _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                if (widget.showNavigationBar) _buildNavigationBar(),
                if (widget.showSearchBar)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: CupertinoSearchTextField(
                        placeholder: 'Search...',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                // Build sections for each letter
                ...sortedLetters.expand((letter) {
                  final filesInSection = groupedFiles[letter]!;
                  return [
                    // Section header – tap to open letter picker
                    SliverToBoxAdapter(
                      child: GestureDetector(
                        onTap: _showLetterPicker,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Grid for this letter's files
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      sliver: SliverGrid.extent(
                        maxCrossAxisExtent: 400,
                        childAspectRatio: 4,
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                        children: filesInSection.map((file) {
                          final index = _sortedFiles.indexOf(file);
                          return _buildGridItem(file, index);
                        }).toList(),
                      ),
                    ),
                  ];
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 170)),
              ],
            ),
          ),
          // Bottom gradient fade
          Positioned(
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 100,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 1),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<File> displayFiles) {
    return Stack(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: CustomScrollView(
            controller:
                PrimaryScrollController.maybeOf(context) ?? _scrollController,
            slivers: [
              if (widget.showNavigationBar) _buildNavigationBar(),
              if (widget.showSearchBar)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: CupertinoSearchTextField(
                      placeholder: 'Search...',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: displayFiles.length,
                itemBuilder: (context, index) {
                  final file = displayFiles[index];
                  final fileName = file.path.substring(
                    file.path.lastIndexOf(Platform.pathSeparator) + 1,
                  );
                  final currentLetter = fileName.isNotEmpty
                      ? fileName[0].toUpperCase()
                      : '#';

                  // Check if this is the first item of a new letter section
                  bool showHeader = false;
                  if (index == 0) {
                    showHeader = true;
                  } else {
                    final prevFile = displayFiles[index - 1];
                    final prevFileName = prevFile.path.substring(
                      prevFile.path.lastIndexOf(Platform.pathSeparator) + 1,
                    );
                    final prevLetter = prevFileName.isNotEmpty
                        ? prevFileName[0].toUpperCase()
                        : '#';
                    showHeader = currentLetter != prevLetter;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        GestureDetector(
                          onTap: _showLetterPicker,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              currentLetter,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      _buildListItem(file, index),
                    ],
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),
        ),
        // Bottom gradient fade
        Positioned(
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 100,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(File file, int index) {
    final fileName = file.path.substring(
      file.path.lastIndexOf(Platform.pathSeparator) + 1,
    );

    return GestureDetector(
      onTap: () => _onFileTap(file),
      child: AnimatedScale(
        scale: (hoverIndex == index) ? 1.015 : 1,
        duration: const Duration(milliseconds: 75),
        curve: Curves.linear,
        child: MouseRegion(
          onEnter: (_) => setState(() => hoverIndex = index),
          onExit: (_) => setState(() => hoverIndex = -1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: setContainerColor(context),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  fileName,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(File file, int index) {
    final fileName = file.path.substring(
      file.path.lastIndexOf(Platform.pathSeparator) + 1,
    );

    return SwipeActionCell(
      key: ValueKey(file.path),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      trailingActions: <SwipeAction>[
        SwipeAction(
          icon: const Icon(Icons.close, color: Colors.white),
          color: Colors.grey[850]!,
          onTap: (CompletionHandler handler) async {
            await handler(false);
          },
        ),
        SwipeAction(
          icon: const Icon(Icons.playlist_add, color: Colors.white),
          color: Colors.grey[700]!,
          onTap: (CompletionHandler handler) async {
            await handler(false);
            if (context.mounted) {
              final title = file.path.split(Platform.pathSeparator).last;
              await showAddToPlaylistDialog(
                context,
                url: file.path,
                title: title,
                artist: null,
                source: 'Local',
              );
            }
          },
        ),
        SwipeAction(
          icon: Icon(
            _likedFiles.contains(file.path)
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            color: Colors.white,
          ),
          color: Colors.redAccent,
          performsFirstActionWithFullSwipe: true,
          onTap: (CompletionHandler handler) async {
            await handler(false);

            await DatabaseManager.instance.toggleFavorite(file.path);

            if (mounted) {
              setState(() {
                if (_likedFiles.contains(file.path)) {
                  _likedFiles.remove(file.path);
                } else {
                  _likedFiles.add(file.path);
                }
              });
            }
            // Handle like action here
          },
        ),
      ],
      leadingActions: <SwipeAction>[
        SwipeAction(
          icon: const Icon(Icons.queue_music, color: Colors.white),
          color: Colors.green,
          performsFirstActionWithFullSwipe: true,
          onTap: (CompletionHandler handler) async {
            await handler(false);
            SongsManager().addToQueue(
              QueueItem(id: file.path, title: fileName, path: file.path),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $fileName to queue')),
              );
            }
          },
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 50,
        ),
        child: ListTile(
          onTap: () => _onFileTap(file),
          leading: Container(
            width: 35,
            height: 35,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: SvgPicture.asset("assets/MusicIcons/music_logo_black.svg"),
          ),
          title: Text(
            fileName,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _onFileTap(File file) {
    if (_sortedFiles.isNotEmpty) {
      final items = _sortedFiles.map((f) {
        final fName = f.path.substring(
          f.path.lastIndexOf(Platform.pathSeparator) + 1,
        );
        return QueueItem(id: f.path, title: fName, path: f.path);
      }).toList();
      final index = _sortedFiles.indexOf(file);
      SongsManager().setQueue(queue: items, startIndex: index);
    }
  }

  /// Sort files alphabetically and create letter-to-index mapping
  List<File> _sortAndMapFiles(List<File> files) {
    if (files.isEmpty) return [];

    // Cache uppercase names to avoid O(N log N) string splitting inside sort
    final Map<File, String> nameCache = {};
    for (final file in files) {
      final lastSeparator = file.path.lastIndexOf(Platform.pathSeparator);
      final fileName = lastSeparator != -1
          ? file.path.substring(lastSeparator + 1)
          : file.path;
      nameCache[file] = fileName.toUpperCase();
    }

    final sorted = List<File>.from(files);
    sorted.sort((a, b) => nameCache[a]!.compareTo(nameCache[b]!));

    // Create letter-to-index mapping
    _letterToIndex.clear();
    for (int i = 0; i < sorted.length; i++) {
      final fileName = sorted[i].path.substring(
        sorted[i].path.lastIndexOf(Platform.pathSeparator) + 1,
      );
      final firstChar = fileName.isNotEmpty ? fileName[0].toUpperCase() : '#';
      if (!_letterToIndex.containsKey(firstChar)) {
        _letterToIndex[firstChar] = i;
      }
    }

    return sorted;
  }

  /// Group files by their starting letter
  Map<String, List<File>> _groupFilesByLetter(List<File> files) {
    final Map<String, List<File>> grouped = {};
    for (final file in files) {
      final fileName = file.path.substring(
        file.path.lastIndexOf(Platform.pathSeparator) + 1,
      );
      final firstChar = fileName.isNotEmpty ? fileName[0].toUpperCase() : '#';
      grouped.putIfAbsent(firstChar, () => []).add(file);
    }
    return grouped;
  }

  /// Scroll to the section starting with the given letter
  void _scrollToLetter(String letter) {
    final index = _letterToIndex[letter];
    final currentController =
        PrimaryScrollController.maybeOf(context) ?? _scrollController;
    if (index != null && currentController.hasClients) {
      // Calculate approximate position
      // For grid: each row has multiple items
      // For list: each item has a fixed height
      final isDesktop = MediaQuery.of(context).size.width > 700;

      if (isDesktop) {
        // Grid layout calculation
        final itemsPerRow = (MediaQuery.of(context).size.width / 400).floor();
        final rowIndex = (index / itemsPerRow).floor();
        final offset = rowIndex * (400 / 3 + 5) + 100; // childAspectRatio = 3

        currentController.animateTo(
          offset.clamp(0.0, currentController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // List layout calculation
        final offset = index * 50.0 + 100; // approximate item height

        currentController.animateTo(
          offset.clamp(0.0, currentController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// Show the letter picker overlay
  void _showLetterPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (ctx) => LetterPickerDialog(
        letterToIndex: _letterToIndex,
        onLetterSelected: (letter) {
          Navigator.of(ctx).pop();
          _scrollToLetter(letter);
        },
      ),
    );
  }
}

/// A model class representing an online song from Supabase
class OnlineSong {
  final String title;
  final String url;
  final String? artist;
  final String? album;
  final String? source;

  OnlineSong({
    required this.title,
    required this.url,
    this.artist,
    this.album,
    this.source,
  });

  factory OnlineSong.fromMap(Map<String, dynamic> map, {String? source}) {
    // Create a case-insensitive lookup
    final lowerMap = <String, dynamic>{};
    for (final entry in map.entries) {
      lowerMap[entry.key.toLowerCase()] = entry.value;
    }

    return OnlineSong(
      title:
          lowerMap['title']?.toString() ??
          lowerMap['name']?.toString() ??
          lowerMap['song_name']?.toString() ??
          lowerMap['filename']?.toString() ??
          'Unknown Song',
      url:
          lowerMap['url']?.toString() ??
          lowerMap['audio_url']?.toString() ??
          lowerMap['file_url']?.toString() ??
          lowerMap['path']?.toString() ??
          '',
      artist: lowerMap['artist']?.toString(),
      album: lowerMap['album']?.toString(),
      source: source ?? lowerMap['source']?.toString(),
    );
  }
}

/// A UI component for displaying online media files from Supabase.
///
/// Supports both grid view (desktop) and list view (mobile) layouts.
/// Similar to MediaUI but designed for online songs.
class OnlineMediaUI extends StatefulWidget {
  /// The title displayed in the navigation bar
  final String title;

  /// Future that resolves to list of online songs
  final Future<List<OnlineSong>>? songsFuture;

  /// Direct songs data (use this OR songsFuture, not both)
  final List<OnlineSong>? songs;

  /// Message shown when no songs are found
  final String emptyMessage;

  /// Whether to show the floating music controller
  final bool showMusicController;

  /// Optional logout callback
  final VoidCallback? onLogout;

  const OnlineMediaUI({
    super.key,
    this.title = "Online",
    this.songsFuture,
    this.songs,
    this.emptyMessage = "No songs found",
    this.showMusicController = true,
    this.onLogout,
  });

  @override
  State<OnlineMediaUI> createState() => _OnlineMediaUIState();
}

class _OnlineMediaUIState extends State<OnlineMediaUI> {
  int hoverIndex = -1;
  final ScrollController _scrollController = ScrollController();
  final Map<String, int> _letterToIndex = {};
  List<OnlineSong> _sortedSongs = [];
  String? _selectedSource;
  String _searchQuery = "";

  Widget _borelAlignedChipLabel(String text) {
    final isBorelFont = SettingsManager.getFontFamily == 'Borel';
    final label = Text(
      text,
      textHeightBehavior: isBorelFont
          ? const TextHeightBehavior(applyHeightToLastDescent: false)
          : null,
      style: isBorelFont
          ? const TextStyle(
              height: 1.0,
              leadingDistribution: TextLeadingDistribution.even,
            )
          : null,
    );

    if (!isBorelFont) {
      return label;
    }

    return Transform.translate(offset: const Offset(0, 7), child: label);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If direct data is provided, use it; otherwise use the future
    if (widget.songs != null) {
      return _buildContent(widget.songs!);
    }

    if (widget.songsFuture != null) {
      return FutureBuilder<List<OnlineSong>>(
        future: widget.songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildContent(data);
          }
        },
      );
    }

    // No data provided
    return _buildEmptyState();
  }

  Widget _buildLoadingState() {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(isLoading: true),
      body: Shimmer.fromColors(
        baseColor: Colors.grey[850]!,
        highlightColor: Colors.grey[700]!,
        child: isDesktop ? const _DesktopShimmer() : const _MobileShimmer(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error loading songs',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'No songs available in this table',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar({List<OnlineSong>? songs, bool isLoading = false}) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    Set<String> sources = {};
    if (songs != null) {
      for (var s in songs) {
        if (s.source != null && s.source!.isNotEmpty) {
          sources.add(s.source!);
        }
      }
    }

    Widget chipsWidget;
    if (isLoading) {
      chipsWidget = Shimmer.fromColors(
        baseColor: Colors.grey[850]!,
        highlightColor: Colors.grey[700]!,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      );
    } else {
      chipsWidget = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: _borelAlignedChipLabel('All'),
              selected: _selectedSource == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedSource = null);
                }
              },
            ),
            ...sources.map(
              (source) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ChoiceChip(
                  label: _borelAlignedChipLabel(source),
                  selected: _selectedSource == source,
                  onSelected: (selected) {
                    setState(() => _selectedSource = selected ? source : null);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    final searchField = CupertinoSearchTextField(
      placeholder: 'Search...',
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );

    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      title: searchField,
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              style: const ButtonStyle(
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
              ),
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).iconTheme.color ?? Colors.white,
              ),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: chipsWidget,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      actions: [
        if (isDesktop && widget.onLogout != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Transform.scale(
              scale: 0.9,
              child: FilledButton(
                onPressed: widget.onLogout,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  spacing: 5,
                  children: [
                    Icon(Icons.power_settings_new_rounded),
                    Text("Logout"),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<OnlineSong>? _lastOnlineSongs;
  String? _lastSelectedSource;

  Widget _buildContent(List<OnlineSong> songs) {
    if (_lastOnlineSongs != songs || _lastSelectedSource != _selectedSource) {
      final filteredSongs = _selectedSource == null
          ? songs
          : songs.where((s) => s.source == _selectedSource).toList();
      _sortedSongs = _sortAndMapSongs(filteredSongs);
      _lastOnlineSongs = songs;
      _lastSelectedSource = _selectedSource;
    }

    List<OnlineSong> songsToDisplay = _sortedSongs;
    if (_searchQuery.isNotEmpty) {
      songsToDisplay = songsToDisplay.where((s) {
        final titleMatch = s.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final artistMatch = s.artist?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        return titleMatch || artistMatch;
      }).toList();
    }
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: widget.showMusicController && !isDesktop
      //     ? Padding(
      //         padding: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
      //         child: BottomMusicController(),
      //       )
      //     : null,
      body: isDesktop ? _buildDesktopLayout(songsToDisplay) : _buildMobileLayout(songsToDisplay),
    );
  }

  Widget _buildDesktopLayout(List<OnlineSong> displaySongs) {
    final groupedSongs = _groupSongsByLetter(displaySongs);
    final sortedLetters = groupedSongs.keys.toList()..sort();

    return Scaffold(
      appBar: _buildAppBar(songs: displaySongs),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: CustomScrollView(
              controller:
                  PrimaryScrollController.maybeOf(context) ?? _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Build sections for each letter
                ...(() {
                  return sortedLetters.expand((letter) {
                    final songsInSection = groupedSongs[letter]!;
                    return [
                      // Section header – tap to open letter picker
                      SliverToBoxAdapter(
                        child: GestureDetector(
                          onTap: _showLetterPicker,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Grid for this letter's songs
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        sliver: SliverGrid.extent(
                          maxCrossAxisExtent: 400,
                          childAspectRatio: 4,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                          children: songsInSection.map((song) {
                            final index = _sortedSongs.indexOf(song);
                            return _buildGridItem(song, index);
                          }).toList(),
                        ),
                      ),
                    ];
                  }).toList();
                })(),
                const SliverToBoxAdapter(child: SizedBox(height: 170)),
              ],
            ),
          ),
          // Bottom gradient fade
          Positioned(
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 100,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<OnlineSong> displaySongs) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(songs: displaySongs),
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView.builder(
              controller:
                  PrimaryScrollController.maybeOf(context) ?? _scrollController,
              itemCount: displaySongs.length,
              itemBuilder: (context, index) {
                final song = displaySongs[index];
                final currentLetter = song.title.isNotEmpty
                    ? song.title[0].toUpperCase()
                    : '#';

                // Check if this is the first item of a new letter section
                bool showHeader = false;
                if (index == 0) {
                  showHeader = true;
                } else {
                  final prevSong = displaySongs[index - 1];
                  final prevLetter = prevSong.title.isNotEmpty
                      ? prevSong.title[0].toUpperCase()
                      : '#';
                  showHeader = currentLetter != prevLetter;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      GestureDetector(
                        onTap: _showLetterPicker,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            currentLetter,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    _buildListItem(song, index),
                  ],
                );
              },
            ),
          ),
          // Bottom gradient fade
          Positioned(
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 100,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(OnlineSong song, int index) {
    return GestureDetector(
      onTap: () => _onSongTap(song),
      child: AnimatedScale(
        scale: (hoverIndex == index) ? 1.015 : 1,
        duration: const Duration(milliseconds: 75),
        curve: Curves.linear,
        child: MouseRegion(
          onEnter: (_) => setState(() => hoverIndex = index),
          onExit: (_) => setState(() => hoverIndex = -1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: setContainerColor(context),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (song.source != null && song.source!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        song.source!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(OnlineSong song, int index) {
    return SwipeActionCell(
      key: ValueKey(song.url),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      trailingActions: <SwipeAction>[
        SwipeAction(
          icon: const Icon(Icons.close, color: Colors.white),
          color: Colors.grey[850]!,
          onTap: (CompletionHandler handler) async {
            await handler(false);
          },
        ),
        SwipeAction(
          icon: const Icon(Icons.playlist_add, color: Colors.white),
          color: Colors.grey[700]!,
          onTap: (CompletionHandler handler) async {
            await handler(false);
            if (context.mounted) {
              await showAddToPlaylistDialog(
                context,
                url: song.url,
                title: song.title,
                artist: song.artist,
                source: song.source,
              );
            }
          },
        ),
        SwipeAction(
          icon: AnimatedBuilder(
            animation: DatabaseManager.instance,
            builder: (context, _) {
              return Icon(
                DatabaseManager.instance.isFavoriteSync(song.url)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border,
                color: Colors.white,
              );
            },
          ),
          color: Colors.redAccent,
          performsFirstActionWithFullSwipe: true,
          onTap: (CompletionHandler handler) async {
            await handler(false);
            await DatabaseManager.instance.toggleFavoriteOnline(
              song.url,
              song.title,
              song.artist,
              song.source,
            );
          },
        ),
      ],
      leadingActions: <SwipeAction>[
        SwipeAction(
          icon: const Icon(Icons.queue_music, color: Colors.white),
          color: Colors.green,
          onTap: (CompletionHandler handler) async {
            await handler(false);
            SongsManager().addToQueue(
              QueueItem(
                id: song.url,
                title: song.title,
                path: song.url,
                artist: song.artist,
              ),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ${song.title} to queue')),
              );
            }
          },
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 50,
        ),
        child: ListTile(
          onTap: () => _onSongTap(song),
          leading: Container(
            width: 35,
            height: 35,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: SvgPicture.asset("assets/MusicIcons/music_logo_black.svg"),
          ),
          title: Text(
            song.title,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle:
              (song.artist?.isNotEmpty == true ||
                  song.source?.isNotEmpty == true)
              ? Text(
                  [
                    song.artist,
                    song.source,
                  ].where((e) => e != null && e.isNotEmpty).join(' • '),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                )
              : null,
        ),
      ),
    );
  }

  void _onSongTap(OnlineSong song) {
    if (song.url.isNotEmpty && _sortedSongs.isNotEmpty) {
      final items = _sortedSongs
          .map(
            (s) => QueueItem(
              id: s.url,
              title: s.title,
              path: s.url,
              artist: s.artist,
            ),
          )
          .toList();
      final index = _sortedSongs.indexOf(song);
      SongsManager().setQueue(queue: items, startIndex: index);
    }
  }

  /// Sort songs alphabetically and create letter-to-index mapping
  List<OnlineSong> _sortAndMapSongs(List<OnlineSong> songs) {
    if (songs.isEmpty) return [];

    final Map<OnlineSong, String> nameCache = {};
    for (final song in songs) {
      nameCache[song] = song.title.toUpperCase();
    }

    final sorted = List<OnlineSong>.from(songs);
    sorted.sort((a, b) => nameCache[a]!.compareTo(nameCache[b]!));

    // Create letter-to-index mapping
    _letterToIndex.clear();
    for (int i = 0; i < sorted.length; i++) {
      final firstChar = sorted[i].title.isNotEmpty
          ? sorted[i].title[0].toUpperCase()
          : '#';
      if (!_letterToIndex.containsKey(firstChar)) {
        _letterToIndex[firstChar] = i;
      }
    }

    return sorted;
  }

  /// Group songs by their starting letter
  Map<String, List<OnlineSong>> _groupSongsByLetter(List<OnlineSong> songs) {
    final Map<String, List<OnlineSong>> grouped = {};
    for (final song in songs) {
      final firstChar = song.title.isNotEmpty
          ? song.title[0].toUpperCase()
          : '#';
      grouped.putIfAbsent(firstChar, () => []).add(song);
    }
    return grouped;
  }

  /// Scroll to the section starting with the given letter
  void _scrollToLetter(String letter) {
    final index = _letterToIndex[letter];
    final currentController =
        PrimaryScrollController.maybeOf(context) ?? _scrollController;
    if (index != null && currentController.hasClients) {
      final isDesktop = MediaQuery.of(context).size.width > 700;

      if (isDesktop) {
        // Grid layout calculation
        final itemsPerRow = (MediaQuery.of(context).size.width / 400).floor();
        final rowIndex = (index / itemsPerRow).floor();
        final offset = rowIndex * (400 / 3 + 5) + 100;

        currentController.animateTo(
          offset.clamp(0.0, currentController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // List layout calculation
        final offset = index * 50.0 + 100;

        currentController.animateTo(
          offset.clamp(0.0, currentController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// Show the letter picker overlay
  void _showLetterPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (ctx) => LetterPickerDialog(
        letterToIndex: _letterToIndex,
        onLetterSelected: (letter) {
          Navigator.of(ctx).pop();
          _scrollToLetter(letter);
        },
      ),
    );
  }
}

/// A full-screen letter picker dialog.
///
/// Shows a grid of alphabetical characters (matching the screenshot).
/// Available letters (those that have songs) are bright white; unavailable
/// ones are dimmed.  Tapping a letter dismisses the dialog and jumps to
/// that section in the list.
class LetterPickerDialog extends StatelessWidget {
  final Map<String, int> letterToIndex;
  final void Function(String) onLetterSelected;

  const LetterPickerDialog({
    super.key,
    required this.letterToIndex,
    required this.onLetterSelected,
  });

  // All selectable entries in display order (matches screenshot layout)
  static const List<String> _letters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(36, 36, 36, 0.97),
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Letter grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.15,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: _letters.length,
                  itemBuilder: (context, index) {
                    final letter = _letters[index];
                    final isAvailable = letterToIndex.containsKey(letter);
                    return GestureDetector(
                      onTap: isAvailable
                          ? () => onLetterSelected(letter)
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isAvailable
                                ? Colors.white
                                : Colors.white.withOpacity(0.22),
                            fontSize: 22,
                            fontWeight: isAvailable
                                ? FontWeight.w400
                                : FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Globe / language icon row (decorative, as in the screenshot)
                Icon(
                  Icons.language_rounded,
                  color: Colors.white.withOpacity(0.55),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopShimmer extends StatelessWidget {
  const _DesktopShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 400,
      childAspectRatio: 3,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      children: List.generate(15, (index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                      margin: const EdgeInsets.only(right: 20),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MobileShimmer extends StatelessWidget {
  const _MobileShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 15,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                      margin: const EdgeInsets.only(right: 40),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 150, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.more_vert, color: Colors.white),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showAddToPlaylistDialog(
  BuildContext context, {
  required String url,
  required String title,
  String? artist,
  required String? source,
}) async {
  bool isCreating = false;
  String newPlaylistName = "";

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isCreating ? "Create Playlist" : "Add to Playlist",
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: isCreating
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          autofocus: true,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            labelText: "Playlist Name",
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          onChanged: (val) => newPlaylistName = val,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => isCreating = false),
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                if (newPlaylistName.trim().isNotEmpty) {
                                  await DatabaseManager.instance.createPlaylist(newPlaylistName.trim());
                                  setState(() => isCreating = false);
                                }
                              },
                              child: const Text("Create"),
                            ),
                          ],
                        ),
                      ],
                    )
                  : FutureBuilder<List<Map<String, dynamic>>>(
                      future: DatabaseManager.instance.getPlaylists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final playlists = snapshot.data ?? [];
                        return ListView.builder(
                          itemCount: playlists.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ListTile(
                                leading: const Icon(Icons.add, color: Colors.grey),
                                title: const Text(
                                  "Create New Playlist",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                onTap: () => setState(() => isCreating = true),
                              );
                            }
                            final playlist = playlists[index - 1];
                            return ListTile(
                              leading: Icon(Icons.queue_music, color: Theme.of(context).colorScheme.primary),
                              title: Text(
                                playlist['name'],
                                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              onTap: () async {
                                await DatabaseManager.instance.addSongToPlaylist(
                                  playlist['id'] as int,
                                  url,
                                  title,
                                  artist,
                                  source,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added to ${playlist['name']}')),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          );
        },
      );
    },
  );
}
