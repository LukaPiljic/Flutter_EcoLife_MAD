class WeatherModel {
  final String cityName;
  final double temp;
  final int humidity;
  final String description;
  final String iconCode;

  const WeatherModel({
    required this.cityName,
    required this.temp,
    required this.humidity,
    required this.description,
    required this.iconCode,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List<dynamic>;
    final first = weatherList.isNotEmpty
        ? weatherList.first as Map<String, dynamic>
        : <String, dynamic>{};
    return WeatherModel(
      cityName: (json['name'] as String?) ?? '',
      temp: (main['temp'] as num).toDouble(),
      humidity: (main['humidity'] as num).toInt(),
      description: (first['description'] as String?) ?? '',
      iconCode: (first['icon'] as String?) ?? '01d',
    );
  }
}

class AirQuality {
  /// OpenWeatherMap air-quality index, 1 (Good) … 5 (Very Poor).
  final int aqi;

  const AirQuality(this.aqi);

  String get label => switch (aqi) {
        1 => 'Good',
        2 => 'Fair',
        3 => 'Moderate',
        4 => 'Poor',
        _ => 'Very Poor',
      };

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List<dynamic>;
    final aqi = (list.first as Map<String, dynamic>)['main']['aqi'] as int;
    return AirQuality(aqi);
  }
}
