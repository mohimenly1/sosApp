import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // ملاحظة أمان مهمة: في التطبيقات الحقيقية، يجب عدم وضع مفتاح API مباشرة في الكود.
  // يتم وضعه هنا للتسهيل في مشروع التخرج.
  static const String _apiKey = '30c165a5d2df4249826172001250408';
  static const String _baseUrl = 'http://api.weatherapi.com/v1';

  Future<Map<String, dynamic>> fetchWeather(
      double latitude, double longitude) async {
    final url =
        '$_baseUrl/forecast.json?key=$_apiKey&q=$latitude,$longitude&days=3&aqi=no&alerts=no';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Failed to connect to the weather service');
    }
  }
}
