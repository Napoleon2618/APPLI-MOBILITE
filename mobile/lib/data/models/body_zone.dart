/// A body zone (e.g. back, shoulders) defined by a coach — see data-model.md.
class BodyZone {
  const BodyZone({
    required this.id,
    required this.coachId,
    required this.label,
    required this.createdAt,
  });

  final String id;
  final String coachId;
  final String label;
  final DateTime createdAt;

  factory BodyZone.fromJson(Map<String, dynamic> json) => BodyZone(
        id: json['id'] as String,
        coachId: json['coach_id'] as String,
        label: json['label'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
