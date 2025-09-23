import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';
import 'package:music_controller/Settings/Settings_UI.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:music_controller/Music Player/HomePage_Components.dart';

// play and pause button variable declaration
int indicatorState = 0;

//Audio Playing feature variables and functions
final AudioPlayer player = AudioPlayer();
String audio_path = "";
Future<double?> audioPlayAndPauseFunction() async {
  if (audio_path.isNotEmpty) {
    if (player.state == PlayerState.playing) {
      player.pause();
      return 0;
    } else {
      await player.play(DeviceFileSource(audio_path));
      var a = await (player.getDuration());
      return a?.inSeconds.toDouble();
    }
  }
  return null;
}

//Bottom Music Controller
class Bottom_Music_Controller extends StatefulWidget {
  const Bottom_Music_Controller({super.key});

  @override
  State<Bottom_Music_Controller> createState() =>
      Bottom_Music_Controller_State();
}

class Bottom_Music_Controller_State extends State<Bottom_Music_Controller> {
  double bmch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        bmch = 65;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        if (snapshot.hasData == true) {
          return GestureDetector(
            onTap: () => setState(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Full_Size_Music_Controller(),
                ),
              );
            }),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.slowMiddle,
              alignment: Alignment.topCenter,
              width: double.infinity,
              height: bmch,
              decoration: BoxDecoration(
                color: (snapshot.data!['mode'] == true)
                    ? Color.fromARGB(215, 255, 255, 255)
                    : Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 10),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: (snapshot.data!['mode'] == true)
                                  ? Colors.black
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 25,
                              color: snapshot.data!['mode'] == true
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),

                        Text(
                          audio_path == ''
                              ? "No Song is Playing..."
                              : audio_path.split(Platform.pathSeparator).last,
                          style: TextStyle(
                            color: (snapshot.data!['mode'] == true)
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: [
                              Icon(
                                Icons.play_arrow,
                                size: 40,
                                color: (snapshot.data!['mode'] == true)
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              Icon(
                                Icons.pause,
                                size: 40,
                                color: (snapshot.data!['mode'] == true)
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ][indicatorState],
                            color: (snapshot.data!['mode'] == true)
                                ? Colors.black
                                : Colors.white,
                            onPressed: () {
                              if (indicatorState == 0) {
                                setState(() {
                                  audioPlayAndPauseFunction();
                                  indicatorState = 1;
                                });
                              } else {
                                setState(() {
                                  audioPlayAndPauseFunction();
                                  indicatorState = 0;
                                });
                              }
                            },
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.repeat,
                              size: 40,
                              color: (snapshot.data!['mode'] == true)
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.shuffle,
                              size: 40,
                              color: (snapshot.data!['mode'] == true)
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return CircularProgressIndicator(color: Colors.redAccent);
        }
      },
    );
  }
}

double i = 0;

// Full Sized Music Controller
class Full_Size_Music_Controller extends StatefulWidget {
  const Full_Size_Music_Controller({super.key});

  @override
  State<Full_Size_Music_Controller> createState() =>
      Full_Size_Music_Controller_State();
}

class Full_Size_Music_Controller_State
    extends State<Full_Size_Music_Controller> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Webview(url: "https://www.youtube.com"),
    );
  }
}

class Home_Page_Music_Controller extends StatefulWidget {
  const Home_Page_Music_Controller({super.key});

  @override
  State<Home_Page_Music_Controller> createState() =>
      Home_Page_Music_Controller_State();
}

class Home_Page_Music_Controller_State
    extends State<Home_Page_Music_Controller> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.only(right: 20, left: 20),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.35 + 40,
            decoration: BoxDecoration(
              color: (snapshot.data!['mode'] == true)
                  ? Colors.black45
                  : Colors.white38,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              backgroundBlendMode: (snapshot.data!['mode'] == true)
                  ? BlendMode.darken
                  : BlendMode.hardLight,
            ),
            child: (MediaQuery.of(context).size.width > 700)
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Container(
                            width: 250,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (snapshot.data!['mode'] == true)
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 80,
                              color: (snapshot.data!['mode'] == true)
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 40),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: (snapshot.data!['mode'] == true)
                                    ? Colors.black45
                                    : Colors.white38,
                                backgroundBlendMode:
                                    (snapshot.data!['mode'] == true)
                                    ? BlendMode.darken
                                    : BlendMode.hardLight,

                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Slider(
                                    value: i,
                                    min: 0,
                                    max: 100,
                                    thumbColor: Colors.white,
                                    onChanged: (value) {
                                      setState(() {
                                        i = value;
                                      });
                                    },
                                    activeColor: Colors.redAccent,
                                    inactiveColor: Colors.white,
                                  ),
                                  Container(
                                    width: 180,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.skip_previous,
                                            color:
                                                (snapshot.data!['mode'] == true)
                                                ? Colors.white
                                                : Colors.black,
                                            size: 40,
                                          ),
                                          onPressed: () {},
                                        ),
                                        IconButton(
                                          icon: [
                                            Icon(
                                              Icons.play_circle_fill,
                                              size: 50,
                                              color:
                                                  (snapshot.data!['mode'] ==
                                                      true)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            Icon(
                                              Icons.pause_circle_filled,
                                              size: 50,
                                              color:
                                                  (snapshot.data!['mode'] ==
                                                      true)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ][indicatorState],
                                          onPressed: () {
                                            if (indicatorState == 0) {
                                              setState(() {
                                                player.resume();
                                                indicatorState = 1;
                                              });
                                            } else {
                                              setState(() {
                                                player.pause();
                                                indicatorState = 0;
                                              });
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.skip_next,
                                            color:
                                                (snapshot.data!['mode'] == true)
                                                ? Colors.white
                                                : Colors.black,
                                            size: 40,
                                          ),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 30,
                            right: 30,
                            top: 20,
                            bottom: 20,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: (snapshot.data!['mode'] == true)
                                      ? Colors.white
                                      : Colors.black,
                                  shape: BoxShape.rectangle,
                                  backgroundBlendMode: BlendMode.hardLight,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  size: 40,
                                  color: (snapshot.data!['mode'] == true)
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  thumbColor: Colors.white,
                                  activeColor: Colors.redAccent,
                                  min: 0,
                                  max: 100,
                                  value: i,
                                  onChanged: (value) {
                                    setState(() {
                                      i = value;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                height: 50,
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.skip_previous,
                                        color: (snapshot.data!['mode'] == true)
                                            ? Colors.white
                                            : Colors.black,
                                        size: 35,
                                      ),
                                      onPressed: () => {},
                                    ),
                                    IconButton(
                                      alignment: Alignment.center,
                                      icon: [
                                        Icon(
                                          Icons.play_circle_fill,
                                          color:
                                              (snapshot.data!['mode'] == true)
                                              ? Colors.white
                                              : Colors.black,
                                          size: 40,
                                        ),
                                        Icon(
                                          Icons.pause_circle_filled,
                                          color:
                                              (snapshot.data!['mode'] == true)
                                              ? Colors.white
                                              : Colors.black,
                                          size: 40,
                                        ),
                                      ][indicatorState],
                                      color: (snapshot.data!['mode'] == true)
                                          ? Colors.white
                                          : Colors.black,
                                      iconSize: 40,
                                      onPressed: () {
                                        if (indicatorState == 1) {
                                          setState(() {
                                            audioPlayAndPauseFunction();
                                            indicatorState = 0;
                                          });
                                        } else {
                                          setState(() {
                                            audioPlayAndPauseFunction();
                                            indicatorState = 1;
                                          });
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.skip_next,
                                        color: (snapshot.data!['mode'] == true)
                                            ? Colors.white
                                            : Colors.black,
                                        size: 35,
                                      ),
                                      onPressed: () => {},
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class SideBar_Music_Controller extends StatefulWidget {
  const SideBar_Music_Controller({super.key});

  @override
  State<SideBar_Music_Controller> createState() =>
      SideBar_Music_Controller_State();
}

class SideBar_Music_Controller_State extends State<SideBar_Music_Controller> {
  double sbmcw = -350;

  @override
  void initState() {
    super.initState();
    // Animate sidebar in after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        sbmcw = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode": true, "bgstatus": "PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        return SizedBox(
          width: 350,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            // alignment: AlignmentDirectional.center,
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                right: sbmcw,
                child: SizedBox(
                  width: 350, // match parent Container width
                  height: MediaQuery.of(
                    context,
                  ).size.height, // match parent Container height
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Background_Dynamic_Theme(),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                right: sbmcw,
                child: SizedBox(
                  width: 350,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 15,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: snapshot.data!['mode'] == true
                              ? Colors.white
                              : Colors.black,
                        ),
                        child: Icon(
                          Icons.music_note,
                          size: 60,
                          color: snapshot.data!['mode'] == true
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                      Text(
                        audio_path == ''
                              ? "No Song is Playing..."
                              : audio_path.split(Platform.pathSeparator).last,
                        style: TextStyle(
                          color: snapshot.data!['mode'] == true
                              ? Colors.white
                              : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Slider(
                            thumbColor: Colors.white,
                            activeColor: Colors.redAccent,
                            min: 0,
                            max: 100,
                            value: i,
                            onChanged: (value) {
                              setState(() {
                                i = value;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (indicatorState == 1) {
                                    setState(() {
                                      audioPlayAndPauseFunction();
                                      indicatorState = 0;
                                    });
                                  } else {
                                    setState(() {
                                      audioPlayAndPauseFunction();
                                      indicatorState = 1;
                                    });
                                  }
                                },
                                icon: Icon(
                                  Icons.repeat,
                                  size: 35,
                                  color: snapshot.data!['mode'] == true
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.skip_previous,
                                  size: 35,
                                  color: snapshot.data!['mode'] == true
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (indicatorState == 1) {
                                    setState(() {
                                      audioPlayAndPauseFunction();
                                      indicatorState = 0;
                                    });
                                  } else {
                                    setState(() {
                                      audioPlayAndPauseFunction();
                                      indicatorState = 1;
                                    });
                                  }
                                },
                                icon: [
                                  Icon(
                                    Icons.play_circle_fill,
                                    color: (snapshot.data!['mode'] == true)
                                        ? Colors.white
                                        : Colors.black,
                                    size: 40,
                                  ),
                                  Icon(
                                    Icons.pause_circle_filled,
                                    color: (snapshot.data!['mode'] == true)
                                        ? Colors.white
                                        : Colors.black,
                                    size: 40,
                                  ),
                                ][indicatorState],
                                color: (snapshot.data!['mode'] == true)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.skip_next,
                                  size: 35,
                                  color: snapshot.data!['mode'] == true
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.shuffle,
                                  size: 35,
                                  color: snapshot.data!['mode'] == true
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
