class StorageReading {
  StorageReading({
    required this.temperature,
    required this.humidity,
    required this.gasLevel,
    required this.freshnessScore,
    required this.riskStatus,
    required this.timestamp,
  });

  final double temperature;
  final double humidity;
  final double gasLevel;
  final double freshnessScore;
  final String riskStatus;
  final DateTime timestamp;

  factory StorageReading.fromMap(Map<dynamic, dynamic> map) {
    return StorageReading(
      temperature: _asDouble(map['temperature']),
      humidity: _asDouble(map['humidity']),
      gasLevel: _asDouble(map['gas_level']),
      freshnessScore: _asDouble(map['freshness_score']),
      riskStatus: (map['risk_status'] ?? 'Unknown').toString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (_asDouble(map['timestamp']) * 1000).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'temperature': temperature,
      'humidity': humidity,
      'gas_level': gasLevel,
      'freshness_score': freshnessScore,
      'risk_status': riskStatus,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
