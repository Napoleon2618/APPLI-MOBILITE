/// Which navigation mode led to a followed session (data-model.md).
enum SessionLogSourceMode {
  dailyFormula('daily_formula'),
  bodyZone('body_zone'),
  painSign('pain_sign');

  const SessionLogSourceMode(this.value);

  final String value;

  static SessionLogSourceMode fromValue(String value) =>
      SessionLogSourceMode.values.firstWhere((m) => m.value == value);
}

/// Record that a client followed a session (FR-013) — write-once, see
/// data-model.md.
class SessionLog {
  const SessionLog({
    required this.id,
    required this.clientId,
    required this.sessionId,
    required this.completedAt,
    required this.sourceMode,
  });

  final String id;
  final String clientId;
  final String sessionId;
  final DateTime completedAt;
  final SessionLogSourceMode sourceMode;

  factory SessionLog.fromJson(Map<String, dynamic> json) => SessionLog(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        sessionId: json['session_id'] as String,
        completedAt: DateTime.parse(json['completed_at'] as String),
        sourceMode: SessionLogSourceMode.fromValue(json['source_mode'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'client_id': clientId,
        'session_id': sessionId,
        'source_mode': sourceMode.value,
      };
}
