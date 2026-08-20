/// A client account (consultation role), attached to exactly one coach
/// (FR-021) — see data-model.md.
class Client {
  const Client({
    required this.id,
    required this.coachId,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String coachId;
  final String displayName;
  final DateTime createdAt;

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        coachId: json['coach_id'] as String,
        displayName: json['display_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
