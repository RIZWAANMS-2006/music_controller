import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:window_size/window_size.dart";
import 'Music Player/Music_Player.dart';
import 'Settings/Settings_UI.dart';
import 'Search/Search_Page.dart';

void main() async {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Center(child: CircularProgressIndicator(color: Colors.redAccent));
  };
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(Size(450, 1005)); //logical width height
    setWindowMaxSize(Size(10000, 10000)); //logical width height
  }
  runApp(const MyMusic());
}

//index for bottom navigation bar
int index = 1;

// Bottom Navigation Bar Items
final List<BottomNavigationBarItem> ItermsForSmallScreen = [
  BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
  BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Home'),
  BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
];

final List<NavigationRailDestination> ItemsForLargerScreen = [
  NavigationRailDestination(
    icon: Icon(Icons.search),
    label: Text('Search'),
  ),
  NavigationRailDestination(
    icon: Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Icon(Icons.library_music),
    ),
    label: Text('Home'),
  ),
  NavigationRailDestination(
    icon: Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Icon(Icons.settings),
    ),
    label: Text('Settings'),
  ),
];

class MyMusic extends StatefulWidget {
  const MyMusic({super.key});

  @override
  State<MyMusic> createState() => MyMusicState();
}

class MyMusicState extends State<MyMusic> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "MyMusic",
      home: FutureBuilder(
        initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
        future: FileSettings,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              backgroundColor: Colors.black38,
              bottomNavigationBar: MediaQuery.of(context).size.width < 700
                  ? BottomNavigationBar(
                      items: ItermsForSmallScreen,
                      currentIndex: index,
                      onTap: (value) => setState(() {
                        index = value;
                      }),
                      showUnselectedLabels: false,
                      backgroundColor: (snapshot.data!["mode"] == true)
                          ? Colors.black
                          : Colors.white,
                      unselectedItemColor: (snapshot.data!["mode"] == true)
                          ? Colors.white
                          : Colors.black,
                      selectedItemColor: Colors.red,
                    )
                  : null,
              body: MediaQuery.of(context).size.width < 700
                  ? (index == 0
                        ? Search_Page()
                        : index == 1
                        ? Home_Page()
                        : index == 2
                        ? Settings_UI()
                        : Container())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 0,
                      children: [
                        NavigationRail(
                          minWidth: 1,
                          groupAlignment: 0,
                          useIndicator: false,
                          backgroundColor: Colors.black,
                          indicatorColor: Colors.red,
                          labelType: NavigationRailLabelType.selected,
                          destinations: ItemsForLargerScreen,
                          selectedIndex: index,
                          selectedLabelTextStyle: TextStyle(color: Colors.red),
                          onDestinationSelected: (value) {
                            setState(() {
                              index = value;
                            });
                          },
                        ),
                        VerticalDivider(
                          width: 0,
                          thickness: 0,
                          color: Colors.black,
                        ),
                        index == 0
                            ? Expanded(child: Search_Page())
                            : index == 1
                            ? Expanded(child: Home_Page())
                            : index == 2
                            ? Expanded(child: Settings_UI())
                            : Container(),
                      ],
                    ),
            );
          } else {
            return CircularProgressIndicator(color: Colors.redAccent);
          }
        },
      ),
    );
  }
}
