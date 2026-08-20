import 'session.dart';

/// Association between a date and a session for a coach (FR-006) — see
/// data-model.md.
class DailyFormula {
  const DailyFormula({
    required this.id,
    required this.coachId,
    required this.sessionId,
    required this.date,
    this.session,
  });

  final String id;
  final String coachId;
  final String sessionId;
  final DateTime date;

  /// The associated session, when loaded (with its ordered exercises).
  final SessionModel? session;

  factory DailyFormula.fromJson(
    Map<String, dynamic> json, {
    SessionModel? session,
  }) =>
      DailyFormula(
        id: json['id'] as String,
        coachId: json['coach_id'] as String,
        sessionId: json['session_id'] as String,
        date: DateTime.parse(json['date'] as String),
        session: session,
      );
}
