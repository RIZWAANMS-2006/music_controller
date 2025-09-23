import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:music_controller/Settings/Settings_UI.dart';
import 'package:weather_animation/weather_animation.dart';
import 'weather_info.dart';

late dynamic controller_darkmode;
late dynamic controller_lightmode;

class Background_Dynamic_Theme extends StatefulWidget {
  const Background_Dynamic_Theme({super.key});

  @override
  State<Background_Dynamic_Theme> createState() {
    return Background_Dynamic_Theme_State();
  }
}

class Background_Dynamic_Theme_State extends State<Background_Dynamic_Theme> {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      controller_darkmode =
          WinVideoPlayerController.file(
              File(
                "D:/Codeing/dart (Flutter)/music_controller/assets/background_wallpapers/live_wallpaper/music_control_infiniteloop_wallpaper1.mp4",
              ),
            )
            ..initialize().then((value) {
              controller_darkmode!.play();
              controller_darkmode!.setLooping(true);
              controller_darkmode!.setPlaybackSpeed(1.0);
              setState(() {});
            });
      controller_lightmode =
          WinVideoPlayerController.file(
              File(
                "D:/Codeing/dart (Flutter)/music_controller/assets/background_wallpapers/live_wallpaper/music_control_infiniteloop_wallpaper2.mp4",
              ),
            )
            ..initialize().then((value) {
              controller_lightmode!.play();
              controller_lightmode!.setLooping(true);
              controller_lightmode!.setPlaybackSpeed(1.0);
              setState(() {});
            });
    } else {
      controller_darkmode =
          VideoPlayerController.asset(
              "assets/background_wallpapers/live_wallpaper/music_control_infiniteloop_wallpaper1.mp4",
            )
            ..initialize().then((_) {
              setState(() {}); // Update UI when video is ready
              controller_darkmode.play(); // Auto play if you want
              controller_darkmode.setLooping(true);
              controller_darkmode.setPlaybackSpeed(2.0);
            });
      controller_lightmode =
          VideoPlayerController.asset(
              "assets/background_wallpapers/live_wallpaper/music_control_infiniteloop_wallpaper2.mp4",
            )
            ..initialize().then((_) {
              setState(() {}); // Update UI when video is ready
              controller_lightmode.play(); // Auto play if you want
              controller_lightmode.setLooping(true);
              controller_lightmode.setPlaybackSpeed(2.0);
            });
    }
  }

  // @override
  // void dispose() {
  //   // controller_darkmode!.dispose();
  //   // controller_lightmode!.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        if (snapshot.data!['bgstatus'] == "Live Wallpaper") {
          return Platform.isWindows
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller_darkmode.value.size.width,
                      height: controller_darkmode.value.size.height,
                      child: snapshot.data!['mode'] == true
                          ? WinVideoPlayer(controller_darkmode)
                          : WinVideoPlayer(controller_lightmode),
                    ),
                  ),
                )
              : snapshot.data!['mode'] == true
              ? VideoPlayer(controller_darkmode)
              : VideoPlayer(controller_lightmode);
        } else if (snapshot.data!['bgstatus'] == "Weather Animation") {
          return StreamBuilder(
            stream: WeatherBackgroundFunction(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SizedBox.expand(child: snapshot.data);
              } else {
                return Align(alignment: AlignmentGeometry.xy(10, 1), child: CircularProgressIndicator(color: Colors.red,));
              }
            },
          );
        } else if (snapshot.data!['bgstatus'] == 'PowerSaving Mode') {
          return Container(
            color: snapshot.data!['mode'] == true ? Colors.black : Colors.white,
          );
        } else {
          return WeatherScene.weatherEvery.sceneWidget;//CircularProgressIndicator(color: Colors.redAccent);
        }
      },
    );
  }
}

int Daily_Usage = 0;

class Daily_Usage_Component extends StatefulWidget {
  const Daily_Usage_Component({super.key});

  @override
  State<StatefulWidget> createState() {
    return Daily_Usage_Component_State();
  }
}

class Daily_Usage_Component_State extends State<Daily_Usage_Component> {
  @override
  void initState() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        Daily_Usage++;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: (snapshot.data!["mode"] == true)
                  ? Colors.black45
                  : Colors.white70,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              backgroundBlendMode: (snapshot.data!["mode"] == true)
                  ? BlendMode.darken
                  : BlendMode.hardLight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Total Usage:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: (snapshot.data!["mode"] == true)
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                Text("", style: TextStyle(fontSize: 10)),
                Text(
                  "${Daily_Usage} min",
                  style: TextStyle(
                    color: (snapshot.data!["mode"] == true)
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            child: CircularProgressIndicator(color: Colors.redAccent),
          );
        }
      },
    );
  }
}

class Date_Time_Component extends StatefulWidget {
  const Date_Time_Component({super.key});
  @override
  State<Date_Time_Component> createState() => Date_Time_Component_State();
}

class Date_Time_Component_State extends State<Date_Time_Component> {
  late DateTime now;
  late Timer t;
  int hour = 0;
  String minute = '';
  String am_pm = "";

  @override
  void initState() {
    //now = DateTime.now();
    t = Timer.periodic(Duration(microseconds: 100), (timer) {
      setState(() {
        now = DateTime.now();
        hour = now.hour > 12 ? now.hour - 12 : now.hour;
        minute = now.minute.toString().length == 1
            ? "0${now.minute}"
            : now.minute.toString();
        am_pm = now.hour > 12 ? "PM" : "AM";
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: snapshot.data!["mode"] == true
                  ? Colors.black45
                  : Colors.white70,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              backgroundBlendMode: (snapshot.data!["mode"] == true)
                  ? BlendMode.darken
                  : BlendMode.hardLight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Time:",
                  style: TextStyle(
                    color: snapshot.data!["mode"] == true
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                Text("", style: TextStyle(fontSize: 10)),
                Text(
                  "$hour:$minute $am_pm",
                  style: TextStyle(
                    color: snapshot.data!["mode"] == true
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            child: CircularProgressIndicator(color: Colors.redAccent),
          );
        }
      },
    );
  }
}

int Total_Songs = 0;

class Total_Songs_Component extends StatelessWidget {
  const Total_Songs_Component({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        return Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: snapshot.data!['mode'] == true
                ? Colors.black45
                : Colors.white70,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            backgroundBlendMode: snapshot.data!['mode'] == true
                ? BlendMode.darken
                : BlendMode.hardLight,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Total Songs:",
                style: TextStyle(
                  color: snapshot.data!['mode'] == true
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              Text("", style: TextStyle(fontSize: 10)),
              Text(
                "${Total_Songs}",
                style: TextStyle(
                  color: snapshot.data!['mode'] == true
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
