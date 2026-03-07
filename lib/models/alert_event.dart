class AlertEvent {
  AlertEvent({
    required this.id,
    required this.storageUnit,
    required this.message,
    required this.severity,
    required this.timestamp,
  });

  final String id;
  final String storageUnit;
  final String message;
  final String severity;
  final DateTime timestamp;

  factory AlertEvent.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    final seconds = rawTimestamp is num
        ? rawTimestamp.toDouble()
        : double.tryParse(rawTimestamp?.toString() ?? '') ?? 0;
    return AlertEvent(
      id: id,
      storageUnit: (map['storage_unit'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      severity: (map['severity'] ?? 'info').toString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch((seconds * 1000).toInt()),
    );
  }
}
