import "dart:async";
import 'package:flutter/material.dart';
import "package:weather_animation/weather_animation.dart";
import 'package:weatherapi/weatherapi.dart';

WeatherRequest wr = WeatherRequest(
  '9bf1f9af242648df902121758252006',
  language: Language.english,
);

Stream<Widget?> weatherDetailsFunction() async* {
  while (true) {
    RealtimeWeather rw = await wr.getRealtimeWeatherByCityName("chennai");
    String? temp = rw.current.condition.text;
    if (temp!.toLowerCase().contains('sun') ||
        temp.toLowerCase().contains('clear')) {
      yield Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.sunny, color: Colors.yellow.withOpacity(0.7), size: 30),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              temp,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (temp.toLowerCase() == 'thunder' ||
        temp.toLowerCase().contains('light')) {
      yield Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.thunderstorm,
            color: Colors.blueGrey.withOpacity(0.7),
            size: 30,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              temp,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (temp.toLowerCase().contains('rain') ||
        temp.toLowerCase().contains('drizzle') ||
        temp.toLowerCase().contains('shower')) {
      yield Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.water_drop,
            color: Colors.lightBlue.withOpacity(0.7),
            size: 30,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              temp,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (temp.toLowerCase() == 'partly cloudy' ||
        temp.toLowerCase().contains('cloudy') ||
        temp.toLowerCase().contains('overcast')) {
      yield Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.cloud, color: Colors.white24, size: 30),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              temp,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (temp.toLowerCase() == 'snow' ||
        temp.toLowerCase().contains('ice') ||
        temp.toLowerCase().contains('freez')) {
      yield Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.snowing, color: Colors.white12, size: 30),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              temp,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (temp.toLowerCase() == 'mist' ||
        temp.toLowerCase().contains('fog')) {
      yield Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.air, color: Colors.white, size: 30),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              temp,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (temp.toLowerCase() == 'dust' ||
        temp.toLowerCase().contains('blizzard')) {
      yield Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.air, color: Colors.white, size: 30),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              temp,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      yield Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.sunny, color: Colors.yellow.withOpacity(0.7), size: 30),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              temp,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
    await Future.delayed(Duration(minutes: 1));
  }
}

Stream<Widget?> WeatherBackgroundFunction() async* {
  while (true) {
    RealtimeWeather rw = await wr.getRealtimeWeatherByCityName("chennai");
    String? temp = rw.current.condition.text;
    if (temp!.toLowerCase().contains('sun') ||
        temp.toLowerCase().contains('clear')) {
      if (DateTime.now().hour <= 17 && DateTime.now().hour >= 6) {
        yield WeatherScene.scorchingSun.sceneWidget;
      } else if (DateTime.now().hour >= 18 && DateTime.now().hour < 19) {
        yield WeatherScene.sunset.sceneWidget;
      } else {
        yield Transform.flip(
          flipX: true,
          child: WrapperScene(
            sizeCanvas: Size(350, 540),
            isLeftCornerGradient: true,
            colors: [Color(0xff000000), Color(0xff283593)],
            children: [
              SunWidget(
                sunConfig: SunConfig(
                  width: 480,
                  blurSigma: 10,
                  blurStyle: BlurStyle.solid,
                  isLeftLocation: true,
                  coreColor: Colors.yellow,
                  midColor: Color(0x25ffee58),
                  outColor: Colors.transparent,
                  animMidMill: 2000,
                  animOutMill: 2000,
                ),
              ),
              WindWidget(
                windConfig: WindConfig(
                  width: 5,
                  y: 208,
                  windGap: 10,
                  blurSigma: 6,
                  color: Color(0xff607d8b),
                  slideXStart: 0,
                  slideXEnd: 350,
                  pauseStartMill: 50,
                  pauseEndMill: 6000,
                  slideDurMill: 1000,
                  blurStyle: BlurStyle.solid,
                ),
              ),
              WrapperScene(
                colors: [],
                isLeftCornerGradient: true,
                children: [
                  Transform.flip(
                    flipX: true,
                    child: CloudWidget(
                      cloudConfig: CloudConfig(
                        size: 250,
                        color: Color(0x779e9e9e),
                        icon: Icons.cloud,
                        widgetCloud: null,
                        x: 20,
                        y: 35,
                        scaleBegin: 1,
                        scaleEnd: 1.08,
                        scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
                        slideX: 20,
                        slideY: 0,
                        slideDurMill: 3000,
                        slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
                      ),
                    ),
                  ),
                ],
              ),
              WrapperScene(
                colors: [],
                isLeftCornerGradient: true,
                children: [
                  Transform.flip(
                    flipX: true,
                    child: CloudWidget(
                      cloudConfig: CloudConfig(
                        size: 160,
                        color: Color(0x779e9e9e),
                        icon: Icons.cloud,
                        widgetCloud: null,
                        x: 140,
                        y: 130,
                        scaleBegin: 1,
                        scaleEnd: 1.1,
                        scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
                        slideX: 20,
                        slideY: 4,
                        slideDurMill: 2000,
                        slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
                      ),
                    ),
                  ),
                ],
              ),
              WindWidget(
                windConfig: WindConfig(
                  width: 7,
                  y: 300,
                  windGap: 15,
                  blurSigma: 7,
                  color: Color(0xff607d8b),
                  slideXStart: 0,
                  slideXEnd: 350,
                  pauseStartMill: 50,
                  pauseEndMill: 6000,
                  slideDurMill: 1000,
                  blurStyle: BlurStyle.solid,
                ),
              ),
            ],
          ),
        );
      }
    } else if (temp.toLowerCase() == 'thunder' ||
        temp.toLowerCase().contains('light')) {
      yield WeatherScene.stormy.sceneWidget;
    } else if (temp.toLowerCase().contains('rain') ||
        temp.toLowerCase().contains('drizzle') ||
        temp.toLowerCase().contains('shower')) {
      yield WeatherScene.rainyOvercast.sceneWidget;
    } else if (temp.toLowerCase() == 'partly cloudy' ||
        temp.toLowerCase().contains('cloudy') ||
        temp.toLowerCase().contains('overcast')) {
      yield WrapperScene(
        sizeCanvas: Size(350, 540),
        isLeftCornerGradient: true,
        colors: [Color(0xff607d8b), Color(0xff9e9e9e), Color(0xffbdbdbd)],
        children: [
          CloudWidget(
            cloudConfig: CloudConfig(
              size: 250,
              color: Color(0xa8fafafa),
              icon: Icons.cloud,
              widgetCloud: null,
              x: 20,
              y: 3,
              scaleBegin: 1,
              scaleEnd: 1.08,
              scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
              slideX: 20,
              slideY: 0,
              slideDurMill: 3000,
              slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            ),
          ),
          CloudWidget(
            cloudConfig: CloudConfig(
              size: 160,
              color: Color(0xa8fafafa),
              icon: Icons.cloud,
              widgetCloud: null,
              x: 478,
              y: 154,
              scaleBegin: 1,
              scaleEnd: 1.1,
              scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
              slideX: 20,
              slideY: 4,
              slideDurMill: 2000,
              slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            ),
          ),
          CloudWidget(
            cloudConfig: CloudConfig(
              size: 160,
              color: Color(0xa8fafafa),
              icon: Icons.cloud,
              widgetCloud: null,
              x: 1207,
              y: 174,
              scaleBegin: 1,
              scaleEnd: 1.1,
              scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
              slideX: 20,
              slideY: 4,
              slideDurMill: 2000,
              slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            ),
          ),
          CloudWidget(
            cloudConfig: CloudConfig(
              size: 160,
              color: Color(0xa8fafafa),
              icon: Icons.cloud,
              widgetCloud: null,
              x: 813,
              y: 99,
              scaleBegin: 1,
              scaleEnd: 1.1,
              scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
              slideX: 20,
              slideY: 4,
              slideDurMill: 2000,
              slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            ),
          ),
          CloudWidget(
            cloudConfig: CloudConfig(
              size: 160,
              color: Color(0xa8fafafa),
              icon: Icons.cloud,
              widgetCloud: null,
              x: 141,
              y: 97,
              scaleBegin: 1,
              scaleEnd: 1.1,
              scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
              slideX: 20,
              slideY: 4,
              slideDurMill: 2000,
              slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            ),
          ),
          CloudWidget(
            cloudConfig: CloudConfig(
              size: 250,
              color: Color(0xa8fafafa),
              icon: Icons.cloud,
              widgetCloud: null,
              x: 1052,
              y: 78,
              scaleBegin: 1,
              scaleEnd: 1.08,
              scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
              slideX: 20,
              slideY: 0,
              slideDurMill: 3000,
              slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            ),
          ),
          CloudWidget(
            cloudConfig: CloudConfig(
              size: 250,
              color: Color(0xa8fafafa),
              icon: Icons.cloud,
              widgetCloud: null,
              x: 345,
              y: 58,
              scaleBegin: 1,
              scaleEnd: 1.08,
              scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
              slideX: 20,
              slideY: 0,
              slideDurMill: 3000,
              slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            ),
          ),
          CloudWidget(
            cloudConfig: CloudConfig(
              size: 250,
              color: Color(0xa8fafafa),
              icon: Icons.cloud,
              widgetCloud: null,
              x: 672,
              y: 3,
              scaleBegin: 1,
              scaleEnd: 1.08,
              scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
              slideX: 20,
              slideY: 0,
              slideDurMill: 3000,
              slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            ),
          ),
        ],
      );
      ;
    } else if (temp.toLowerCase() == 'snow' ||
        temp.toLowerCase().contains('ice') ||
        temp.toLowerCase().contains('freez')) {
      yield WeatherScene.snowfall.sceneWidget;
    } else if (temp.toLowerCase() == 'mist' ||
        temp.toLowerCase().contains('fog')) {
      yield WeatherScene.showerSleet.sceneWidget;
    } else if (temp.toLowerCase() == 'dust' ||
        temp.toLowerCase().contains('blizzard')) {
      yield WeatherScene.showerSleet.sceneWidget;
    } else {
      yield WeatherScene.weatherEvery.sceneWidget;
    }
    await Future.delayed(Duration(minutes: 1));
  }
}

// Future<Widget?> weather() async {
//   RealtimeWeather rw = await wr.getRealtimeWeatherByCityName("chennai");
//   String? currentWeather = rw.current.condition.text;
//   if (currentWeather!.toLowerCase().contains('sun') ||
//       currentWeather.toLowerCase().contains('clear')) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Icon(Icons.sunny, color: Colors.yellow.withOpacity(0.7), size: 30),
//         Padding(
//           padding: const EdgeInsets.only(left: 7),
//           child: Text(
//             currentWeather,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//   if (currentWeather.toLowerCase() == 'thunder' ||
//       currentWeather.toLowerCase().contains('light')) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Icon(
//           Icons.thunderstorm,
//           color: Colors.blueGrey.withOpacity(0.7),
//           size: 30,
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 7),
//           child: Text(
//             currentWeather,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//   if (currentWeather.toLowerCase().contains('rain') ||
//       currentWeather.toLowerCase().contains('drizzle') ||
//       currentWeather.toLowerCase().contains('shower')) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Icon(
//           Icons.water_drop,
//           color: Colors.lightBlue.withOpacity(0.7),
//           size: 30,
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 7),
//           child: Text(
//             currentWeather,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//   if (currentWeather.toLowerCase() == 'partly cloudy' ||
//       currentWeather.toLowerCase().contains('cloudy') ||
//       currentWeather.toLowerCase().contains('overcast')) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Icon(Icons.cloud, color: Colors.white24, size: 30),
//         Padding(
//           padding: const EdgeInsets.only(left: 7),
//           child: Text(
//             currentWeather,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//   if (currentWeather.toLowerCase() == 'snow' ||
//       currentWeather.toLowerCase().contains('ice') ||
//       currentWeather.toLowerCase().contains('freez')) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Icon(Icons.snowing, color: Colors.white12, size: 30),
//         Padding(
//           padding: const EdgeInsets.only(left: 7),
//           child: Text(
//             currentWeather,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//   if (currentWeather.toLowerCase() == 'mist' ||
//       currentWeather.toLowerCase().contains('fog')) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Icon(Icons.air, color: Colors.white, size: 30),
//         Padding(
//           padding: const EdgeInsets.only(left: 7),
//           child: Text(
//             currentWeather,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//   if (currentWeather.toLowerCase() == 'dust' ||
//       currentWeather.toLowerCase().contains('blizzard')) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Icon(Icons.air, color: Colors.white, size: 30),
//         Padding(
//           padding: const EdgeInsets.only(left: 7),
//           child: Text(
//             currentWeather,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   } else {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Icon(Icons.sunny, color: Colors.yellow.withOpacity(0.7), size: 30),
//         Padding(
//           padding: const EdgeInsets.only(left: 7),
//           child: Text(
//             currentWeather,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
