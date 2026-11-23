class ObservationModel {
  final DateTime timestamp;
  final String type;
  final String value;
  final String note;
  final String lat;
  final String lon;

  const ObservationModel({
    required this.timestamp,
    required this.type,
    required this.value,
    required this.note,
    required this.lat,
    required this.lon,
  });
}
