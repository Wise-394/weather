import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:weather/models/weather_model.dart';
import 'package:weather/services/weather_service.dart';
import 'package:intl/intl.dart';

enum SampleItem { theme, settings, exit }

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final apiKey = dotenv.env['API_KEY'];
  late final _weatherService = WeatherService(apiKey!);
  Weather? _weather;
  late Timer _timer;
  late String currentTime;
  late String currentDay;
  late List<String> _nextFiveDays;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    currentTime = DateFormat.jms().format(DateTime.now());
    currentDay = DateFormat('EEEE').format(DateTime.now());
    _nextFiveDays = _calculateNextFiveDays();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateFormat.jms().format(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  _fetchWeather() async {
    String cityName = await _weatherService.getCurrentCity();
    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      print(e);
    }
  }

  List<String> _calculateNextFiveDays() {
    final List<String> days = [];
    final now = DateTime.now();
    for (int i = 0; i < 5; i++) {
      final nextDay = now.add(Duration(days: i + 1));
      days.add(_formatDay(nextDay));
    }
    return days;
  }

  String _formatDay(DateTime day) {
    return DateFormat('EEEE').format(day);
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/sunny.json';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'fog':
        return 'assets/cloudy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/rainy.json';
      case 'thunderstorm':
        return 'assets/thunderstorm.json';
      case 'clear':
        return 'assets/sunny.json';
      default:
        return 'assets/sunny.json';
    }
  }

  String getWeatherCondition(String? mainCondition) {
    if (mainCondition == null) return 'loading weather condition';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'fog':
        return 'Cloudy weather';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'Rainy weather';
      case 'thunderstorm':
        return 'Thunderstorm';
      case 'clear':
        return 'Clear weather';
      default:
        return 'loading weather condition';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            buildLocationAndDateTimeWidget(),
            const SizedBox(height: 20),
            buildWeatherAnimationWithDetails(),
            const SizedBox(height: 20),
            buildWeatherForecast(),
          ],
        ),
      ),
    );
  }

  Widget buildLocationAndDateTimeWidget() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_city_rounded,
                size: 35,
              ),
              Text(
                _weather?.cityName ?? "Loading City",
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$currentDay: ',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currentTime.split(',').last,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildWeatherAnimationWithDetails() {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        height: 200,
        child: Container(
          width: size.width,
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.6),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlue.withOpacity(0.5),
                offset: const Offset(0, 25),
                blurRadius: 10,
                spreadRadius: -12,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -40,
                left: 20,
                child: Lottie.asset(
                  getWeatherAnimation(_weather?.mainCondition ?? ""),
                  width: 150,
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                child: Text(
                  getWeatherCondition(_weather?.mainCondition ?? ""),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${_weather?.temperature.round()}°',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
  }

  Widget buildWeatherForecast() {
    return Container(
      height: 100,
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.lightBlue.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.lightBlue.withOpacity(0.15),
            offset: const Offset(0, 15),
            blurRadius: 10,
            spreadRadius: -12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (String day in _nextFiveDays)
              Column(
                children: [
                  Text(day),
                  Icon(Icons.cloud),
                  Text("32C"),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
