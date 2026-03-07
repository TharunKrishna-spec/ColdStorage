import '../models/storage_reading.dart';

double calculateFreshness({
  required double gasLevel,
  required double temperature,
  required double humidity,
}) {
  final score = 100 - (gasLevel * 0.4) - (temperature * 0.3) - (humidity * 0.3);
  return score.clamp(0, 100);
}

String classifyRisk(double freshness) {
  if (freshness > 70) {
    return 'Safe';
  }
  if (freshness >= 40) {
    return 'Warning';
  }
  return 'Critical';
}

bool detectGasTrend(List<StorageReading> history) {
  if (history.length < 3) {
    return false;
  }
  final a = history[history.length - 3].gasLevel;
  final b = history[history.length - 2].gasLevel;
  final c = history[history.length - 1].gasLevel;
  return c > b && b > a;
}

String recommendationFor(StorageReading reading) {
  if (reading.temperature > 4) {
    return 'Temperature above optimal level. Reduce below 4°C.';
  }
  if (reading.humidity > 80) {
    return 'Humidity is high. Improve airflow/dehumidification.';
  }
  if (reading.gasLevel > 350) {
    return 'Gas concentration is elevated. Inspect stock for early spoilage.';
  }
  return 'Storage conditions are stable.';
}
