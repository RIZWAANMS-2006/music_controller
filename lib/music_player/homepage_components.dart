import 'package:flutter/material.dart';
import '../managers/weather_manager.dart';

late dynamic controller_darkmode;
late dynamic controller_lightmode;

class WeatherBackground extends StatefulWidget {
  const WeatherBackground({super.key});

  @override
  State<WeatherBackground> createState() {
    return WeatherBackgroundState();
  }
}

class WeatherBackgroundState extends State<WeatherBackground> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Widget?>(
      stream: WeatherBackgroundFunction(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SizedBox.expand(child: snapshot.data);
        } else {
          return const Align(
            alignment: AlignmentGeometry.xy(10, 1),
            child: CircularProgressIndicator(color: Colors.red),
          );
        }
      },
    );
  }
}
