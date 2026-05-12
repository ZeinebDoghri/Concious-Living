import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<Map<String, dynamic>> getTomorrowWeather({
    required double lat,
    required double lng,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/forecast?lat=$lat&lng=$lng&appid=$apiKey&units=metric&cnt=8',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return {};
      final data = jsonDecode(response.body);

      // Extract tomorrow's midday forecast (index 4 = ~12h from now)
      final tomorrow = (data['list'] as List)[4];
      return {
        'temp':        tomorrow['main']['temp'],
        'feels_like':  tomorrow['main']['feels_like'],
        'weather':     tomorrow['weather'][0]['main'],  // 'Rain', 'Clear', etc.
        'description': tomorrow['weather'][0]['description'],
      };
    } catch (e) {
      return {};
    }
  }
}
