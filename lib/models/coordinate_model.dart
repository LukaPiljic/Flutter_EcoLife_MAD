class CoordinateModel {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double altitude;

  const CoordinateModel({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
  });
}
