import 'package:dio/dio.dart';
import '../models/external_data.dart';

class ExternalApiService {
  static final ExternalApiService _instance = ExternalApiService._internal();
  factory ExternalApiService() => _instance;
  ExternalApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  final Map<int, List<PublicHoliday>> _holidayCache = {};
  Map<String, WeatherDay>? _weatherCache;
  double? currentTemperature;
  int? currentWeatherCode;

  /// Nager.Date Public Holiday API (Turkey - TR)
  Future<List<PublicHoliday>> getTurkishHolidays(int year) async {
    if (_holidayCache.containsKey(year)) {
      return _holidayCache[year]!;
    }

    try {
      final res = await _dio.get('https://date.nager.at/api/v3/PublicHolidays/$year/TR');
      if (res.statusCode == 200 && res.data is List) {
        final list = (res.data as List)
            .map((h) => PublicHoliday.fromJson(Map<String, dynamic>.from(h)))
            .toList();
        _holidayCache[year] = list;
        return list;
      }
    } catch (_) {
      // Offline fallback for Turkey's fixed official holidays
    }

    final fallback = [
      PublicHoliday(date: DateTime(year, 1, 1), localName: 'Yılbaşı', name: 'New Year\'s Day'),
      PublicHoliday(date: DateTime(year, 4, 23), localName: 'Ulusal Egemenlik ve Çocuk Bayramı', name: 'National Sovereignty Day'),
      PublicHoliday(date: DateTime(year, 5, 1), localName: 'Emek ve Dayanışma Günü', name: 'Labour Day'),
      PublicHoliday(date: DateTime(year, 5, 19), localName: 'Atatürk\'ü Anma, Gençlik ve Spor Bayramı', name: 'Youth and Sports Day'),
      PublicHoliday(date: DateTime(year, 7, 15), localName: 'Demokrasi ve Millî Birlik Günü', name: 'Democracy Day'),
      PublicHoliday(date: DateTime(year, 8, 30), localName: 'Zafer Bayramı', name: 'Victory Day'),
      PublicHoliday(date: DateTime(year, 10, 29), localName: 'Cumhuriyet Bayramı', name: 'Republic Day'),
    ];
    _holidayCache[year] = fallback;
    return fallback;
  }

  /// Open-Meteo Weather API (Istanbul default coordinates, 14-day forecast)
  Future<Map<String, WeatherDay>> getWeatherForecast({
    double latitude = 41.0082,
    double longitude = 28.9784,
  }) async {
    if (_weatherCache != null && _weatherCache!.isNotEmpty) {
      return _weatherCache!;
    }

    final map = <String, WeatherDay>{};
    try {
      final res = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
          'current': 'temperature_2m,weather_code',
          'timezone': 'auto',
          'forecast_days': 14,
        },
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data);
        if (data['current'] is Map) {
          currentTemperature = (data['current']['temperature_2m'] as num?)?.toDouble();
          currentWeatherCode = (data['current']['weather_code'] as num?)?.toInt();
        }
        final daily = data['daily'];
        if (daily is Map) {
          final times = List<String>.from(daily['time'] ?? []);
          final codes = List<num>.from(daily['weather_code'] ?? []);
          final maxs = List<num>.from(daily['temperature_2m_max'] ?? []);
          final mins = List<num>.from(daily['temperature_2m_min'] ?? []);
          for (int i = 0; i < times.length; i++) {
            final dt = DateTime.tryParse(times[i]);
            if (dt != null) {
              map[times[i]] = WeatherDay(
                date: dt,
                maxTemp: i < maxs.length ? maxs[i].toDouble() : 0,
                minTemp: i < mins.length ? mins[i].toDouble() : 0,
                weatherCode: i < codes.length ? codes[i].toInt() : 0,
              );
            }
          }
        }
        _weatherCache = map;
      }
    } catch (_) {}

    return map;
  }
}
