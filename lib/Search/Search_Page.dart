import "package:audioplayers/audioplayers.dart";
import "package:flutter/material.dart";
import "package:music_controller/Settings/Settings_UI.dart";
import "package:path_provider/path_provider.dart";
import "dart:io";
import 'package:music_controller/Music Player/Music_Controller.dart';

Future<String> getOrCreateMyMusicDirectory() async {
  Directory? myMusicDir;
  if (Platform.isAndroid) {
    myMusicDir = Directory('/storage/emulated/0/Download/MyMusic');
  } else if (Platform.isWindows) {
    myMusicDir = await getDownloadsDirectory();
  } else if (Platform.isLinux) {
    final String? home = Platform.environment['HOME'];
    final String separator = Platform.pathSeparator;
    final String musicPath = '$home${separator}Downloads${separator}MyMusic';
    myMusicDir = Directory(musicPath);
  }
  if (await myMusicDir!.exists()) {
    return myMusicDir.path;
  } else {
    await myMusicDir.create(recursive: true);
    return myMusicDir.path;
  }
}

Future<List<File>> getMediaFiles(String path) async {
  final dir = Directory(path);
  final files = dir.listSync(recursive: true);
  // List of common audio and video file extensions
  final extensions = [
    '.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a', // audio
    '.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv', '.webm', '.3gp', // video
  ];
  return files
      .whereType<File>()
      .where(
        (file) =>
            extensions.any((ext) => file.path.toLowerCase().endsWith(ext)),
      )
      .toList();
}

Future<List<File>> comboFunction() async {
  List<File> mediaFiles = await getMediaFiles(
    await getOrCreateMyMusicDirectory(),
  );
  return mediaFiles;
}

class Search_Page extends StatefulWidget {
  const Search_Page({super.key});

  @override
  State<Search_Page> createState() => _Search_PageState();
}

class _Search_PageState extends State<Search_Page> {
  late Future<List<File>> mediaFileFuture;

  @override
  void initState() {
    super.initState();
    mediaFileFuture = comboFunction();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, msnapshot) {
        return Scaffold(
          backgroundColor: (msnapshot.data!['mode'] == true)
              ? Colors.black
              : Colors.grey,
          bottomNavigationBar: MediaQuery.of(context).size.width < 700
              ? Bottom_Music_Controller()
              : null,
          body: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    //For better debugging use a container with a color in Column
                    mainAxisAlignment: MainAxisAlignment.start,
                    // crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FutureBuilder(
                        future: mediaFileFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'No media files found',
                                style: TextStyle(
                                  color: (msnapshot.data!['mode'] == true)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            );
                          } else {
                            if (MediaQuery.of(context).size.width > 700) {
                              return GridView.extent(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  bottom: 5,
                                ),
                                maxCrossAxisExtent: 400,
                                childAspectRatio: 3,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                children: List.generate(snapshot.data!.length, (
                                  index,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      right: 5,
                                      top: 5,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        audio_path = snapshot.data![index].path;
                                        audioPlayAndPauseFunction();
                                        if (player.state ==
                                            PlayerState.playing) {
                                          indicatorState = 0;
                                        } else {
                                          indicatorState = 1;
                                        }
                                        setState(() {});
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),

                                          color:
                                              (msnapshot.data!['mode'] == true)
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          snapshot.data![index].path
                                              .split(Platform.pathSeparator)
                                              .last,
                                          style: TextStyle(
                                            color:
                                                msnapshot.data!['mode'] == true
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            } else {
                              return Column(
                                spacing: 2,
                                children: List.generate(snapshot.data!.length, (
                                  index,
                                ) {
                                  return ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: double.infinity,
                                      minHeight: 50,
                                    ),
                                    child: ListTile(
                                      onTap: () {
                                        audio_path = snapshot.data![index].path;
                                        audioPlayAndPauseFunction();
                                        if (indicatorState == 0) {
                                          indicatorState = 1;
                                        } else {
                                          indicatorState = 0;
                                        }
                                        setState(() {});
                                      },
                                      leading: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: 35,
                                          minHeight: 35,
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color:
                                                (msnapshot.data!['mode'] ==
                                                    true)
                                                ? Colors.white
                                                : Colors.black,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(5),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.music_note,
                                            color:
                                                (msnapshot.data!['mode'] ==
                                                    true)
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                      tileColor: msnapshot.data!['mode'] == true
                                          ? Colors.black
                                          : Colors.white,
                                      title: Text(
                                        snapshot.data![index].path
                                            .split(Platform.pathSeparator)
                                            .last,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              (msnapshot.data!['mode'] == true)
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              MediaQuery.of(context).size.width > 700
                  ? SideBar_Music_Controller()
                  : Container(),
            ],
          ),
          floatingActionButton: SearchAnchor(
            builder: (context, controller) {
              return SearchBar(
                controller: controller,
                onTap: () {
                  controller.openView();
                },
                onChanged: (value) {
                  controller.openView();
                },
                leading: const Icon(Icons.search),
              );
            },
            suggestionsBuilder: (context, controller) {
              return [ListTile(title: Text("Search is not available yet"))];
            },
          ),
        );
      },
    );
  }
}
