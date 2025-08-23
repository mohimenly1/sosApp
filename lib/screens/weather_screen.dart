import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final data = await _weatherService.fetchWeather(
          position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  IconData _getWeatherIcon(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('sunny') || condition.contains('clear')) {
      return Icons.wb_sunny;
    } else if (condition.contains('cloudy') || condition.contains('overcast')) {
      return Icons.cloud;
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return Icons.grain;
    } else if (condition.contains('snow') || condition.contains('sleet')) {
      return Icons.ac_unit;
    } else if (condition.contains('thunder')) {
      return Icons.flash_on;
    } else {
      return Icons.cloud_queue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather Forecast')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildWeatherView(),
    );
  }

  Widget _buildWeatherView() {
    final current = _weatherData!['current'];
    final location = _weatherData!['location'];
    final forecastDays = _weatherData!['forecast']['forecastday'];

    return RefreshIndicator(
      onRefresh: _fetchWeatherData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Current Weather Card
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(location['name'],
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(location['country'],
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network('http:${current['condition']['icon']}',
                          scale: 0.8),
                      const SizedBox(width: 16),
                      Text('${current['temp_c'].round()}°C',
                          style: const TextStyle(
                              fontSize: 56, fontWeight: FontWeight.w300)),
                    ],
                  ),
                  Text(current['condition']['text'],
                      style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Daily Forecast
          const Text('3-Day Forecast',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...forecastDays.map<Widget>((day) {
            final date = DateTime.parse(day['date']);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading:
                    Image.network('http:${day['day']['condition']['icon']}'),
                title: Text(DateFormat('EEEE').format(date)), // Day of the week
                subtitle: Text(day['day']['condition']['text']),
                trailing: Text(
                    '${day['day']['maxtemp_c'].round()}° / ${day['day']['mintemp_c'].round()}°'),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
