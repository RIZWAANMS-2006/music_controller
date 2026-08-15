import "package:flutter/material.dart";
import "package:Rusic/managers/path_manager.dart";
import "dart:io";
import 'package:Rusic/ui/media_ui.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin {
  late Future<Map<String, List<File>>> mediaFileFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    mediaFileFuture = Pathmanager().fetchMediaFilesFromLibrary();
  }

  void _refreshMedia() {
    setState(() {
      mediaFileFuture = Pathmanager().fetchMediaFilesFromLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MediaUI(
      title: "Search",
      mediaFilesFuture: mediaFileFuture,
      showSearchBar: true,
      showMusicController: true,
      emptyMessage: "No media files found",
      onEmptyAction: () async {
        final added = await Pathmanager().addLibraryFolder();
        if (added) {
          _refreshMedia();
        }
      },
    );
  }
}
