/// A plain-language, non-medical pain sign defined by a coach (FR-009,
/// FR-016) — see data-model.md.
class PainSign {
  const PainSign({
    required this.id,
    required this.coachId,
    required this.label,
    required this.createdAt,
  });

  final String id;
  final String coachId;
  final String label;
  final DateTime createdAt;

  factory PainSign.fromJson(Map<String, dynamic> json) => PainSign(
        id: json['id'] as String,
        coachId: json['coach_id'] as String,
        label: json['label'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
