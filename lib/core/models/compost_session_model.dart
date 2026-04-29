import 'package:cloud_firestore/cloud_firestore.dart';

class CompostSession {
  final String id;
  final double compostablePct;
  final double nonCompostablePct;
  final double backgroundPct;
  final DateTime timestamp;
  final String? imageUrl;
  final int inferenceTimeMs;

  const CompostSession({
    required this.id,
    required this.compostablePct,
    required this.nonCompostablePct,
    required this.backgroundPct,
    required this.timestamp,
    this.imageUrl,
    required this.inferenceTimeMs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'compostablePct': compostablePct,
        'nonCompostablePct': nonCompostablePct,
        'backgroundPct': backgroundPct,
        'timestamp': Timestamp.fromDate(timestamp),
        'imageUrl': imageUrl,
        'inferenceTimeMs': inferenceTimeMs,
      };

  factory CompostSession.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    final raw = json['timestamp'];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is String) {
      ts = DateTime.parse(raw);
    } else {
      ts = DateTime.now();
    }
    return CompostSession(
      id: json['id'] as String? ?? '',
      compostablePct: (json['compostablePct'] as num?)?.toDouble() ?? 0,
      nonCompostablePct: (json['nonCompostablePct'] as num?)?.toDouble() ?? 0,
      backgroundPct: (json['backgroundPct'] as num?)?.toDouble() ?? 0,
      timestamp: ts,
      imageUrl: json['imageUrl'] as String?,
      inferenceTimeMs: (json['inferenceTimeMs'] as num?)?.toInt() ?? 0,
    );
  }
}
