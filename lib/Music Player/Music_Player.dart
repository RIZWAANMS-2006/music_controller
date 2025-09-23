import 'dart:ui';

import 'package:flutter/material.dart';

import 'Music_Controller.dart';
import 'HomePage_Components.dart';
import 'package:music_controller/Settings/Settings_UI.dart';

// Creating "Music_Controller"
class Home_Page extends StatefulWidget {
  const Home_Page({super.key});

  @override
  State<Home_Page> createState() => Home_Page_State();
}

// Creating "Music Controller State Class"
class Home_Page_State extends State<Home_Page> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: {"mode":true,"bgstatus":"PowerSaving Mode"},
      future: FileSettings,
      builder: (context, snapshot) {
        if (snapshot.hasData == true) {
          return Stack(
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Background_Dynamic_Theme(),
              ),
              SafeArea(
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Container(
                      //   child: Column(
                      //     children: [
                      //       Padding(
                      //         padding: const EdgeInsets.only(
                      //           top: 30,
                      //           right: 20,
                      //           left: 20,
                      //         ),
                      //         child: Total_Songs_Component(),
                      //       ),
                      //       Container(
                      //         child: Row(
                      //           mainAxisAlignment:
                      //               MainAxisAlignment.spaceBetween,
                      //           children: [
                      //             Expanded(
                      //               flex: 6,
                      //               child: Padding(
                      //                 padding: const EdgeInsets.only(
                      //                   left: 20,
                      //                   top: 30,
                      //                 ),
                      //                 child: Daily_Usage_Component(),
                      //               ),
                      //             ),
                      //             Expanded(
                      //               flex: 1,
                      //               child: Container(height: 100),
                      //             ),
                      //             Expanded(
                      //               flex: 6,
                      //               child: Padding(
                      //                 padding: const EdgeInsets.only(
                      //                   right: 20,
                      //                   top: 30,
                      //                 ),
                      //                 child: Date_Time_Component(),
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Center(child: Home_Page_Music_Controller()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          );
        }
      },
    );
  }
}
