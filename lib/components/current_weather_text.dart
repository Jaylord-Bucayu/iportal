// current_weather_text.dart
//
// A simple Flutter component that detects the device's current location
// and displays the current weather as plain text.
//
// Dependencies (add to pubspec.yaml):
//   dependencies:
//     geolocator: ^13.0.1
//     http: ^1.2.2
//
// Permissions:
//   Android (android/app/src/main/AndroidManifest.xml):
//     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//     <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
//
//   iOS (ios/Runner/Info.plist):
//     <key>NSLocationWhenInUseUsageDescription</key>
//     <string>This app needs your location to show local weather.</string>
//
// Usage:
//   const CurrentWeatherText()

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class CurrentWeatherText extends StatefulWidget {
  const CurrentWeatherText({super.key, this.textStyle});

  /// Optional style for the resulting text.
  final TextStyle? textStyle;

  @override
  State<CurrentWeatherText> createState() => _CurrentWeatherTextState();
}

class _CurrentWeatherTextState extends State<CurrentWeatherText> {
  String _display = 'Loading weather...';
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
        _display = 'Loading weather...';
      });
    }
    try {
      final position = await _getCurrentPosition();
      final weatherText = await _fetchWeather(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _display = weatherText;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[Weather] CurrentWeatherText error: $e');
      if (!mounted) return;
      setState(() {
        _display = 'Could not load weather: $e';
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    debugPrint('[Weather] --- LOCATION DIAGNOSTIC START ---');

    // Check if location services are enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[Weather] Location service enabled: $serviceEnabled');
    if (!serviceEnabled) {
      debugPrint('[Weather] --- LOCATION DIAGNOSTIC END (service off) ---');
      throw Exception(
        'Location services are disabled. Turn on Location in the '
            'device/emulator Settings app.',
      );
    }

    // Check / request permission.
    var permission = await Geolocator.checkPermission();
    debugPrint('[Weather] Current permission: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('[Weather] Permission after request: $permission');
      if (permission == LocationPermission.denied) {
        debugPrint('[Weather] --- LOCATION DIAGNOSTIC END (denied) ---');
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('[Weather] --- LOCATION DIAGNOSTIC END (denied forever) ---');
      throw Exception(
        'Location permission permanently denied. Enable it manually in '
            'Settings > Apps > (your app) > Permissions > Location.',
      );
    }

    // Log last known position for extra visibility (doesn't block/throw).
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      debugPrint('[Weather] Last known position: $lastKnown');
    } catch (e) {
      debugPrint('[Weather] getLastKnownPosition error: $e');
    }

    debugPrint('[Weather] Requesting fresh position fix...');
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('[Weather] --- LOCATION DIAGNOSTIC END (timeout) ---');
        throw Exception(
          'Timed out waiting for GPS fix. If you are on an emulator: '
              '1) set a mock location in Extended Controls > Location, '
              '2) make sure Settings > Location is ON inside the emulator, '
              '3) confirm the AVD system image includes Google Play (Play '
              'Store icon in Device Manager) — plain AOSP images have no '
              'Fused Location Provider and will always time out.',
        );
      },
    );

    debugPrint('[Weather] Got position: $position');
    debugPrint('[Weather] --- LOCATION DIAGNOSTIC END (success) ---');
    return position;
  }

  Future<String> _fetchWeather(double lat, double lon) async {
    // Open-Meteo: free, no API key required.
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
          '?latitude=$lat&longitude=$lon&current_weather=true',
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Weather API request timed out.');
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Weather request failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current_weather'] as Map<String, dynamic>?;
    if (current == null) {
      throw Exception('No weather data available.');
    }

    final temp = current['temperature'];
    final windSpeed = current['windspeed'];
    final code = current['weathercode'];

    return '${temp}°C, ${_weatherDescription(code)} (wind ${windSpeed} km/h)';
  }

  String _weatherDescription(dynamic code) {
    // WMO weather interpretation codes (simplified).
    const codes = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Fog',
      48: 'Depositing rime fog',
      51: 'Light drizzle',
      53: 'Moderate drizzle',
      55: 'Dense drizzle',
      61: 'Slight rain',
      63: 'Moderate rain',
      65: 'Heavy rain',
      71: 'Slight snow',
      73: 'Moderate snow',
      75: 'Heavy snow',
      80: 'Slight rain showers',
      81: 'Moderate rain showers',
      82: 'Violent rain showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm with hail',
      99: 'Thunderstorm with heavy hail',
    };
    return codes[code] ?? 'Unknown conditions';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_hasError) {
      // Tap to retry — useful after fixing an emulator location/permission
      // setting, so you don't have to hot-restart the whole app.
      return GestureDetector(
        onTap: _loadWeather,
        child: Text(
          '$_display\n(tap to retry)',
          style: widget.textStyle,
        ),
      );
    }
    return Text(_display, style: widget.textStyle);
  }
}