import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

//File Handling for Settings
Future<Map<dynamic, dynamic>> settingsFunction() async {
  final dir = await getDownloadsDirectory();
  if (dir == null) {
    throw Exception("Downloads directory not found");
  }
  File settingsFile = File("${dir.path}/MyMusic/settings.json");
  Map<dynamic, dynamic> settingsData = {};
  if (await settingsFile.exists()) {
    String settingsJsonInfo = await settingsFile.readAsString();
    settingsData = jsonDecode(settingsJsonInfo);
    return settingsData;
  } else {
    settingsFile.create();
    Map<dynamic, dynamic> defaultSettings = {
      "mode": true,
      "bgstatus": 'Live Wallpaper',
    };
    settingsFile.writeAsString(jsonEncode(defaultSettings));
    String settingsJsonInfo = await settingsFile.readAsString();
    settingsData = jsonDecode(settingsJsonInfo);
    return settingsData;
  }
}

// Stream<Map<dynamic, dynamic>> FileSettings() async* {
//   yield await settingsFunction();
// }

var FileSettings = settingsFunction();

WidgetStateProperty<Icon> Switch_Icons =
    WidgetStateProperty.fromMap(<WidgetStatesConstraint, Icon>{
      WidgetState.selected: Icon(Icons.dark_mode),
      WidgetState.any: Icon(Icons.light_mode),
    });

String mainvalue = 'Live Wallpaper';

class Settings_UI extends StatefulWidget {
  const Settings_UI({super.key});

  @override
  State<Settings_UI> createState() => Settings_UI_State();
}

class Settings_UI_State extends State<Settings_UI> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        return SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: (snapshot.data!['mode'] == true)
                ? Colors.black
                : Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 10, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      "SETTINGS",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 40,
                        fontStyle: FontStyle.normal,
                        fontFamily: "Doto",
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: (snapshot.data!['mode'] == true)
                              ? Colors.white
                              : Colors.black,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "SYSTEM PREFERENCES",
                          style: TextStyle(
                            color: (snapshot.data!['mode'] == true)
                                ? Colors.white
                                : Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        FutureBuilder(
                          initialData: {
                            "mode": true,
                            "bgstatus": "PowerSaving Mode",
                          },
                          future: FileSettings,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              bool mode = snapshot.data!["mode"];
                              return Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  activeTrackColor: Colors.redAccent,
                                  thumbIcon: Switch_Icons,
                                  inactiveThumbColor: Colors.black,
                                  value: mode,
                                  onChanged: (bool value) async {
                                    final dir = await getDownloadsDirectory();
                                    if (dir == null) {
                                      throw Exception(
                                        "Downloads directory not found",
                                      );
                                    }
                                    File settingsFile = File(
                                      "${dir.path}/MyMusic/settings.json",
                                    );
                                    Map<dynamic, dynamic> settingsData =
                                        jsonDecode(
                                          await settingsFile.readAsString(),
                                        );
                                    setState(() {
                                      settingsData["mode"] = value;
                                      settingsFile.writeAsString(
                                        jsonEncode(settingsData),
                                      );
                                      FileSettings = settingsFunction();
                                    });
                                  },
                                ),
                              );
                            } else {
                              return CircularProgressIndicator(
                                padding: EdgeInsets.only(right: 10),
                                color: Colors.redAccent,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: (snapshot.data!['mode'] == true)
                              ? Colors.white
                              : Colors.black,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SYSTEM JOY",
                          style: TextStyle(
                            color: (snapshot.data!['mode'] == true)
                                ? Colors.white
                                : Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        DropdownButton(
                          value: snapshot.data!['bgstatus'],
                          icon: Icon(null, color: Colors.redAccent),
                          underline: Container(),
                          dropdownColor: (snapshot.data!['mode'] == true)
                              ? Colors.black
                              : Colors.white,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: (snapshot.data!['mode'] == true)
                                ? Colors.white
                                : Colors.black,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          alignment: Alignment.centerRight,
                          items: [
                            DropdownMenuItem(
                              value: 'Live Wallpaper',
                              alignment: Alignment.center,
                              child: Text('Live Wallpaper'),
                            ),
                            DropdownMenuItem(
                              value: 'Weather Animation',
                              alignment: Alignment.center,
                              child: Text('Weather Animation'),
                            ),
                            DropdownMenuItem(
                              value: 'PowerSaving Mode',
                              alignment: Alignment.center,
                              child: Text('PowerSaving Mode'),
                            ),
                          ],
                          onChanged: (value) async {
                            final dir =
                                await getDownloadsDirectory(); // I guess this will work only in windows
                            if (dir == null) {
                              throw Exception("Downloads directory not found");
                            }
                            File settingsFile = File(
                              "${dir.path}/MyMusic/settings.json",
                            );
                            Map<dynamic, dynamic> settingsData = jsonDecode(
                              await File(
                                "${dir.path}/MyMusic/settings.json",
                              ).readAsString(),
                            );
                            setState(() {
                              settingsData['bgstatus'] = value;
                              settingsFile.writeAsString(
                                jsonEncode(settingsData),
                              );
                              FileSettings = settingsFunction();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
