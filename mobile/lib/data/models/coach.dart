/// A coach account (admin/content role) — see data-model.md.
class Coach {
  const Coach({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final DateTime createdAt;

  factory Coach.fromJson(Map<String, dynamic> json) => Coach(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
